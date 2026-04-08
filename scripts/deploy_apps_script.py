#!/usr/bin/env python3
"""
deploy_apps_script.py v1.0.0
Deploy Google Apps Script webhooks using clasp CLI.

Replaces deploy_apps_script.bat — Python handles long deployment IDs
correctly (batch echo truncates them).

Prerequisites:
  - Node.js installed
  - npm install -g @google/clasp
  - clasp login (one-time Google auth)
  - Apps Script API enabled: https://script.google.com/home/usersettings

Usage:
  python scripts/deploy_apps_script.py          # Full deploy
  python scripts/deploy_apps_script.py --urls    # Just show current deployment URLs
  python scripts/deploy_apps_script.py --fix     # Re-extract URLs from existing deployments
"""

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
CONFIG_DIR = PROJECT_ROOT / "config"
WEBHOOKS_FILE = CONFIG_DIR / "webhooks.json"

ANALYTICS_DIR = SCRIPT_DIR / "clasp_analytics"
CONTRIBUTIONS_DIR = SCRIPT_DIR / "clasp_contributions"

ANALYTICS_GS = SCRIPT_DIR / "analytics_webapp.gs"
CONTRIBUTIONS_GS = SCRIPT_DIR / "contributions_webapp.gs"


def run(cmd, cwd=None, capture=True):
    """Run a command and return (returncode, stdout, stderr)."""
    print(f"  $ {cmd}")
    result = subprocess.run(
        cmd, shell=True, cwd=cwd,
        capture_output=capture, text=True,
    )
    if capture:
        if result.stdout.strip():
            print(f"    {result.stdout.strip()}")
        if result.stderr.strip():
            print(f"    [stderr] {result.stderr.strip()}")
    return result.returncode, result.stdout, result.stderr


def check_prerequisites():
    """Check that Node.js and clasp are installed."""
    print("[1/5] Checking prerequisites...")

    # Node.js
    if shutil.which("node") is None:
        print("  ERROR: Node.js not found. Install: winget install OpenJS.NodeJS.LTS")
        return False
    print("  Node.js: OK")

    # clasp
    if shutil.which("clasp") is None:
        print("  clasp not found. Installing...")
        rc, _, _ = run("npm install -g @google/clasp")
        if rc != 0:
            print("  ERROR: Could not install clasp. Try: npm install -g @google/clasp")
            return False
    print("  clasp: OK")

    # Login check
    clasprc = Path.home() / ".clasprc.json"
    if not clasprc.exists():
        print("  Not logged in. Running clasp login...")
        rc, _, _ = run("clasp login", capture=False)
        if rc != 0:
            print("  ERROR: Login failed.")
            return False
    print("  clasp login: OK")

    return True


def extract_deployment_id(text):
    """Extract a deployment ID (AKfycb...) from clasp output.

    clasp deploy output:  "Created version 3.\n- AKfycbxLONG_ID @3."
    clasp deployments:    "- AKfycbxLONG_ID @3 - Description"

    Deployment IDs start with 'AKfycb' and are ~80+ chars long.
    We want the VERSIONED deployment (has @N), NOT the @HEAD one.
    """
    # Find all deployment IDs
    # Pattern: AKfycb followed by alphanumeric/underscore/dash chars
    ids = re.findall(r'(AKfycb[A-Za-z0-9_-]{30,})', text)

    if not ids:
        return None

    # Check if any line has @HEAD — we want to skip that one
    lines = text.strip().split('\n')
    head_ids = set()
    versioned_ids = []

    for line in lines:
        match = re.search(r'(AKfycb[A-Za-z0-9_-]{30,})', line)
        if match:
            dep_id = match.group(1)
            if '@HEAD' in line:
                head_ids.add(dep_id)
            else:
                versioned_ids.append(dep_id)

    # Prefer versioned deployments (most recent = last in list)
    if versioned_ids:
        return versioned_ids[-1]

    # If only HEAD exists, use first non-HEAD ID
    for dep_id in ids:
        if dep_id not in head_ids:
            return dep_id

    # Last resort: return the last ID found
    return ids[-1] if ids else None


def create_manifest(project_dir, with_oauth=False):
    """Create appsscript.json manifest."""
    manifest = {
        "timeZone": "Africa/Douala",
        "dependencies": {},
        "webapp": {
            "executeAs": "USER_DEPLOYING",
            "access": "ANYONE_ANONYMOUS",
        },
        "exceptionLogging": "STACKDRIVER",
        "runtimeVersion": "V8",
    }

    if with_oauth:
        manifest["oauthScopes"] = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive",
            "https://www.googleapis.com/auth/script.send_mail",
        ]

    manifest_path = project_dir / "appsscript.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    print(f"  Created {manifest_path}")


def deploy_project(name, project_dir, gs_file, with_oauth=False):
    """Deploy a single Apps Script project. Returns the deployment URL or None."""
    print(f"\nDeploying {name}...")

    project_dir.mkdir(exist_ok=True)

    # Create project if needed
    clasp_json = project_dir / ".clasp.json"
    if not clasp_json.exists():
        print(f"  Creating new Apps Script project: {name}...")
        rc, stdout, stderr = run(f'clasp create --title "{name}" --type standalone', cwd=project_dir)
        if rc != 0:
            print(f"  ERROR: Could not create project.")
            print(f"  Make sure Apps Script API is enabled:")
            print(f"  https://script.google.com/home/usersettings")
            return None
    else:
        print(f"  Project exists ({clasp_json})")

    # Copy .gs file as Code.js
    code_js = project_dir / "Code.js"
    shutil.copy2(gs_file, code_js)
    print(f"  Copied {gs_file.name} -> Code.js")

    # Always write manifest with webapp config (clasp create doesn't include it)
    create_manifest(project_dir, with_oauth=with_oauth)

    # Push code
    print("  Pushing code to Apps Script...")
    rc, stdout, stderr = run("clasp push --force", cwd=project_dir)
    if rc != 0:
        print(f"  ERROR: Push failed.")
        return None

    # Deploy (create new version)
    print("  Creating new deployment...")
    rc, stdout, stderr = run(f'clasp deploy --description "{name} auto-deploy"', cwd=project_dir)
    deploy_output = stdout + "\n" + stderr

    # Try to extract deployment ID from deploy output
    deploy_id = extract_deployment_id(deploy_output)

    if not deploy_id:
        # Fallback: get from clasp deployments
        print("  Deploy output didn't contain ID, checking deployments list...")
        rc2, stdout2, stderr2 = run("clasp deployments", cwd=project_dir)
        deployments_output = stdout2 + "\n" + stderr2
        deploy_id = extract_deployment_id(deployments_output)

    if deploy_id:
        url = f"https://script.google.com/macros/s/{deploy_id}/exec"
        print(f"  SUCCESS!")
        print(f"  Deployment ID: {deploy_id}")
        print(f"  URL: {url}")
        return url
    else:
        print(f"  WARNING: Could not extract deployment ID.")
        print(f"  Run manually: cd {project_dir} && clasp deployments")
        return None


def get_existing_urls():
    """Get deployment URLs from existing clasp projects without redeploying."""
    urls = {}

    for name, project_dir in [("analytics", ANALYTICS_DIR), ("contributions", CONTRIBUTIONS_DIR)]:
        if not (project_dir / ".clasp.json").exists():
            print(f"  {name}: No project found at {project_dir}")
            continue

        rc, stdout, stderr = run("clasp deployments", cwd=project_dir)
        output = stdout + "\n" + stderr
        deploy_id = extract_deployment_id(output)

        if deploy_id:
            url = f"https://script.google.com/macros/s/{deploy_id}/exec"
            urls[f"{name}_url"] = url
            print(f"  {name}: {url}")
        else:
            print(f"  {name}: Could not extract deployment ID")

    return urls


def save_config(analytics_url, contributions_url):
    """Save webhook URLs to config/webhooks.json."""
    CONFIG_DIR.mkdir(exist_ok=True)

    from datetime import datetime
    config = {
        "analytics_url": analytics_url or "",
        "contributions_url": contributions_url or "",
        "deployed_at": datetime.now().isoformat(timespec='seconds'),
    }

    with open(WEBHOOKS_FILE, 'w') as f:
        json.dump(config, f, indent=2)

    print(f"\nSaved to {WEBHOOKS_FILE}:")
    print(json.dumps(config, indent=2))


def main():
    print("=" * 55)
    print(" Awing AI Learning - Apps Script Deployer v1.0.0")
    print("=" * 55)

    # Handle --urls flag (just show existing URLs)
    if "--urls" in sys.argv:
        print("\nReading existing deployment URLs...")
        urls = get_existing_urls()
        return

    # Handle --fix flag (re-extract URLs and save config)
    if "--fix" in sys.argv:
        print("\nRe-extracting deployment URLs from existing projects...")
        urls = get_existing_urls()
        save_config(
            urls.get("analytics_url", ""),
            urls.get("contributions_url", ""),
        )
        return

    # Full deployment
    if not check_prerequisites():
        sys.exit(1)

    print("\n[2/5] Deploying Analytics...")
    analytics_url = deploy_project(
        "Awing Analytics",
        ANALYTICS_DIR,
        ANALYTICS_GS,
        with_oauth=False,
    )

    print("\n[3/5] Deploying Contributions...")
    contributions_url = deploy_project(
        "Awing Contributions",
        CONTRIBUTIONS_DIR,
        CONTRIBUTIONS_GS,
        with_oauth=True,
    )

    print("\n[4/5] Saving configuration...")
    save_config(analytics_url, contributions_url)

    print("\n" + "=" * 55)
    print(" Deployment Complete!")
    print("=" * 55)

    if analytics_url:
        print(f" [OK] Analytics:     {analytics_url}")
    else:
        print(" [!!] Analytics:     FAILED - see errors above")

    if contributions_url:
        print(f" [OK] Contributions: {contributions_url}")
    else:
        print(" [!!] Contributions: FAILED - see errors above")

    print()

    if not analytics_url or not contributions_url:
        print(" To fix missing URLs, run:")
        print("   python scripts/deploy_apps_script.py --fix")
        print()

    print(" NEXT STEPS:")
    print(" 1. Open each project in browser (clasp open)")
    print("    cd scripts/clasp_analytics && clasp open")
    print("    cd scripts/clasp_contributions && clasp open")
    print(" 2. Run the setup function ONCE in each project:")
    print("    Analytics: Run setupSheets()")
    print("    Contributions: Run setupContributions()")
    print(" 3. Re-run build_and_run.bat — it will use the new URLs")
    print("=" * 55)


if __name__ == "__main__":
    main()
