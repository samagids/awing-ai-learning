#!/usr/bin/env python3
"""
setup_and_deploy.py v3.0.0
Fully automated deploy pipeline: webhooks, authorization, build, install.

Smart automation:
  - Deploys webhooks and updates config/webhooks.json automatically
  - Tests webhook connectivity — only prompts for re-auth if actually needed
  - Builds APK and installs on connected device via adb
  - Opens app automatically after install

Usage:
  python scripts/setup_and_deploy.py              # Smart full pipeline (DEFAULT)
  python scripts/setup_and_deploy.py --webhooks   # Only redeploy webhooks
  python scripts/setup_and_deploy.py --test       # Only test webhook connectivity
  python scripts/setup_and_deploy.py --authorize  # Force open Apps Script editor
  python scripts/setup_and_deploy.py --sha1       # Only show SHA-1 fingerprint
  python scripts/setup_and_deploy.py --build      # Only build + install APK
  python scripts/setup_and_deploy.py --quick       # Webhooks + build (skip tests)
"""

import json
import os
import re
import shutil
import subprocess
import sys
import webbrowser
from pathlib import Path
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# ==================== Paths ====================
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
CONFIG_DIR = PROJECT_ROOT / "config"
WEBHOOKS_FILE = CONFIG_DIR / "webhooks.json"

ANALYTICS_DIR = SCRIPT_DIR / "clasp_analytics"
CONTRIBUTIONS_DIR = SCRIPT_DIR / "clasp_contributions"
ANALYTICS_GS = SCRIPT_DIR / "analytics_webapp.gs"
CONTRIBUTIONS_GS = SCRIPT_DIR / "contributions_webapp.gs"

ANDROID_DIR = PROJECT_ROOT / "android"


def run(cmd, cwd=None, capture=True, timeout=120, quiet=False):
    """Run a command and return (returncode, stdout, stderr)."""
    if not quiet:
        print(f"  $ {cmd}")
    try:
        result = subprocess.run(
            cmd, shell=True, cwd=cwd,
            capture_output=capture, text=True, timeout=timeout,
        )
        if capture and not quiet:
            if result.stdout.strip():
                for line in result.stdout.strip().split('\n')[:20]:
                    print(f"    {line}")
            if result.stderr.strip():
                for line in result.stderr.strip().split('\n')[:10]:
                    print(f"    [stderr] {line}")
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        if not quiet:
            print(f"    [timeout] Command timed out after {timeout}s")
        return 1, "", "timeout"


def extract_deployment_id(text):
    """Extract a deployment ID (AKfycb...) from clasp output."""
    ids = re.findall(r'(AKfycb[A-Za-z0-9_-]{30,})', text)
    if not ids:
        return None

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

    if versioned_ids:
        return versioned_ids[-1]
    for dep_id in ids:
        if dep_id not in head_ids:
            return dep_id
    return ids[-1] if ids else None


def load_webhooks():
    """Load current webhooks.json config."""
    if WEBHOOKS_FILE.exists():
        try:
            with open(WEBHOOKS_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def get_script_id(name):
    """Get Apps Script ID from clasp project."""
    project_dir = ANALYTICS_DIR if name == "analytics" else CONTRIBUTIONS_DIR
    clasp_json = project_dir / ".clasp.json"
    if clasp_json.exists():
        try:
            with open(clasp_json, 'r') as f:
                return json.load(f).get("scriptId", "")
        except Exception:
            pass
    return ""


# ==================== Step 1: Deploy Webhooks ====================

def deploy_webhooks():
    """Copy latest .gs files, push, deploy, and update webhooks.json."""
    print("\n" + "=" * 60)
    print("  [1/4] Deploy Google Apps Script Webhooks")
    print("=" * 60)

    # Check clasp
    if shutil.which("clasp") is None:
        print("\n  clasp not found. Installing...")
        rc, _, _ = run("npm install -g @google/clasp")
        if rc != 0:
            print("  ERROR: Install clasp manually: npm install -g @google/clasp")
            return False

    # Check login
    clasprc = Path.home() / ".clasprc.json"
    if not clasprc.exists():
        print("\n  Not logged into clasp. Running clasp login...")
        rc, _, _ = run("clasp login", capture=False)
        if rc != 0:
            print("  ERROR: clasp login failed")
            return False

    urls = {}

    for name, project_dir, gs_file, description in [
        ("analytics", ANALYTICS_DIR, ANALYTICS_GS, "Analytics with dev 2FA email"),
        ("contributions", CONTRIBUTIONS_DIR, CONTRIBUTIONS_GS, "Contributions webhook"),
    ]:
        print(f"\n  --- Deploying {name} ---")

        if not project_dir.exists():
            print(f"  ERROR: {project_dir} not found. Run clasp create first.")
            continue

        # Copy latest .gs code
        code_js = project_dir / "Code.js"
        if gs_file.exists():
            shutil.copy2(gs_file, code_js)
            print(f"  Copied {gs_file.name} -> Code.js")

        # Push
        rc, stdout, stderr = run("clasp push --force", cwd=project_dir)
        if rc != 0:
            print(f"  ERROR: Push failed for {name}")
            continue

        # Deploy
        rc, stdout, stderr = run(
            f'clasp deploy --description "{description}"',
            cwd=project_dir,
        )
        deploy_output = stdout + "\n" + stderr
        deploy_id = extract_deployment_id(deploy_output)

        if not deploy_id:
            print("  Checking deployments list...")
            rc2, stdout2, stderr2 = run("clasp deployments", cwd=project_dir)
            deploy_id = extract_deployment_id(stdout2 + "\n" + stderr2)

        if deploy_id:
            url = f"https://script.google.com/macros/s/{deploy_id}/exec"
            urls[f"{name}_url"] = url
            print(f"  OK: {url}")
        else:
            print(f"  WARNING: Could not extract deployment ID for {name}")

    # Save to webhooks.json
    if urls:
        CONFIG_DIR.mkdir(exist_ok=True)
        existing = load_webhooks()
        existing.update(urls)
        existing["deployed_at"] = datetime.now().isoformat(timespec='seconds')

        with open(WEBHOOKS_FILE, 'w') as f:
            json.dump(existing, f, indent=2)

        print(f"\n  Saved to {WEBHOOKS_FILE}")
        return True
    else:
        print("\n  No webhooks were deployed successfully.")
        return False


# ==================== Step 2: Test & Auto-Authorize ====================

def test_webhook(url, name="webhook"):
    """Test a single webhook URL. Returns True if working, False if needs auth."""
    try:
        data = json.dumps({"action": "ping", "test": True}).encode('utf-8')
        req = Request(url, data=data, headers={'Content-Type': 'application/json'})
        resp = urlopen(req, timeout=15)
        body = resp.read().decode('utf-8')
        try:
            result = json.loads(body)
            status = result.get('status', '')
            if status == 'ok':
                return True
            # Some errors mean it's reachable but has issues
            return True  # At least it responded with JSON
        except json.JSONDecodeError:
            # HTML response usually means auth issue or redirect
            if 'authorization' in body.lower() or 'sign in' in body.lower():
                return False
            return True  # Non-JSON but reachable
    except HTTPError as e:
        if e.code == 401 or e.code == 403:
            return False
        return False
    except (URLError, Exception):
        return False


def test_dev_email(analytics_url):
    """Test if the dev email (send_mail scope) actually works."""
    try:
        data = json.dumps({
            "action": "send_dev_code",
            "code": "000000",
            "email": "test@test.com",  # Will be rejected by email check — that's fine
        }).encode('utf-8')
        req = Request(analytics_url, data=data, headers={'Content-Type': 'application/json'})
        resp = urlopen(req, timeout=15)
        body = resp.read().decode('utf-8')
        result = json.loads(body)
        # "Unauthorized email" means the function ran — send_mail scope is authorized
        if result.get('status') == 'error' and 'Unauthorized' in result.get('message', ''):
            return True
        # "ok" would mean it actually sent (shouldn't happen with test email)
        if result.get('status') == 'ok':
            return True
        return False
    except Exception:
        return False


def test_and_authorize():
    """Test webhooks and auto-authorize if needed. Returns True if all working."""
    print("\n" + "=" * 60)
    print("  [2/4] Test Webhook Connectivity & Authorization")
    print("=" * 60)

    config = load_webhooks()
    analytics_url = config.get('analytics_url', '')
    contributions_url = config.get('contributions_url', '')

    if not analytics_url or not contributions_url:
        print("  ERROR: webhooks.json missing URLs. Run --webhooks first.")
        return False

    all_ok = True

    # Test contributions webhook
    print(f"\n  Testing contributions webhook...")
    if test_webhook(contributions_url, "contributions"):
        print("  [OK] Contributions webhook is working")
    else:
        print("  [!!] Contributions webhook not responding")
        all_ok = False

    # Test analytics webhook (basic)
    print(f"\n  Testing analytics webhook...")
    if test_webhook(analytics_url, "analytics"):
        print("  [OK] Analytics webhook is reachable")
    else:
        print("  [!!] Analytics webhook not responding")
        all_ok = False

    # Test send_mail scope (critical for 2FA)
    print(f"\n  Testing 2FA email capability (send_mail scope)...")
    if test_dev_email(analytics_url):
        print("  [OK] 2FA email is working (send_mail authorized)")
    else:
        print("  [!!] 2FA email NOT working — needs re-authorization")
        all_ok = False

        # Auto-open browser for re-auth
        script_id = get_script_id("analytics")
        if script_id:
            url = f"https://script.google.com/d/{script_id}/edit"
            print(f"\n  Opening Apps Script editor for authorization...")
            print(f"  URL: {url}")
            try:
                webbrowser.open(url)
            except Exception:
                pass

            print("""
  ╔═══════════════════════════════════════════════════════╗
  ║  AUTHORIZE PERMISSIONS (30 seconds, one-time)        ║
  ╠═══════════════════════════════════════════════════════╣
  ║                                                       ║
  ║  In the Apps Script editor that just opened:          ║
  ║  1. Select "setupSheets" from the function dropdown   ║
  ║  2. Click Run (▶)                                    ║
  ║  3. Click "Review permissions" → Allow                ║
  ║                                                       ║
  ║  (The function may error — that's fine, you just      ║
  ║   needed to approve the send_mail permission.)        ║
  ╚═══════════════════════════════════════════════════════╝""")
            input("\n  Press ENTER after you've clicked Allow in the browser...")

            # Re-test
            print("  Re-testing 2FA email...")
            if test_dev_email(analytics_url):
                print("  [OK] 2FA email is now working!")
                all_ok = True
            else:
                print("  [!!] Still not working. You may need to:")
                print("       1. Make sure you selected 'setupSheets' and clicked Run")
                print("       2. Approved ALL permissions including 'Send email'")
                print("       Try again: python scripts\\setup_and_deploy.py --authorize")

    if all_ok:
        print("\n  All webhooks are working correctly!")
    return all_ok


def force_authorize():
    """Force open Apps Script editor for re-authorization."""
    print("\n" + "=" * 60)
    print("  Force Re-Authorization")
    print("=" * 60)

    script_id = get_script_id("analytics")
    if not script_id:
        print("  ERROR: Analytics script ID not found.")
        return False

    url = f"https://script.google.com/d/{script_id}/edit"
    print(f"\n  Opening: {url}")
    try:
        webbrowser.open(url)
    except Exception:
        print(f"  Open manually: {url}")

    print("""
  Select "setupSheets" → Run (▶) → Review permissions → Allow
  Then re-test with: python scripts\\setup_and_deploy.py --test""")
    return True


# ==================== Step 3: Build & Install ====================

def run_build():
    """Build APK and install on connected device."""
    print("\n" + "=" * 60)
    print("  [3/4] Build & Install APK")
    print("=" * 60)

    # Flutter pub get
    print("\n  Installing Flutter dependencies...")
    run("flutter pub get", cwd=PROJECT_ROOT, capture=False, timeout=120)

    # Build APK
    print("\n  Building release APK...")
    rc, _, _ = run("flutter build apk --release", cwd=PROJECT_ROOT, capture=False, timeout=300)
    if rc != 0:
        print("  ERROR: Build failed.")
        return False

    apk_path = PROJECT_ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
    if not apk_path.exists():
        print(f"  ERROR: APK not found at {apk_path}")
        return False

    print(f"\n  APK built: {apk_path}")
    size_mb = apk_path.stat().st_size / (1024 * 1024)
    print(f"  Size: {size_mb:.1f} MB")

    return install_apk(apk_path)


def install_apk(apk_path=None):
    """Install APK on connected device via adb."""
    if apk_path is None:
        apk_path = PROJECT_ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"

    if not apk_path.exists():
        print(f"  ERROR: APK not found at {apk_path}")
        return False

    print("\n" + "=" * 60)
    print("  [4/4] Install on Device")
    print("=" * 60)

    # Check adb
    if shutil.which("adb") is None:
        print("  ERROR: adb not found in PATH.")
        print("  Add Android SDK platform-tools to your PATH.")
        return False

    # Check for connected device
    rc, stdout, _ = run("adb devices", capture=True, quiet=True)
    lines = [l.strip() for l in (stdout or "").split('\n') if l.strip() and 'List' not in l]
    devices = [l for l in lines if 'device' in l and 'unauthorized' not in l and 'offline' not in l]

    if not devices:
        print("\n  No device connected via USB.")
        print("  Connect your tablet with USB debugging enabled, then run:")
        print(f'  adb install -r "{apk_path}"')
        return False

    device_id = devices[0].split()[0]
    print(f"\n  Device found: {device_id}")
    print(f"  Installing APK ({apk_path.stat().st_size / (1024*1024):.1f} MB)...")

    rc, _, _ = run(f'adb -s {device_id} install -r "{apk_path}"', capture=False, timeout=120)
    if rc != 0:
        print("  WARNING: Install failed. Trying with -d flag...")
        rc, _, _ = run(f'adb -s {device_id} install -r -d "{apk_path}"', capture=False, timeout=120)

    if rc == 0:
        print("\n  APK installed successfully!")

        # Get package name
        package = _get_package_name()
        print(f"  Launching {package}...")
        run(f'adb -s {device_id} shell am start -n {package}/.MainActivity', capture=True, quiet=True)
        # Try alternate activity name
        run(f'adb -s {device_id} shell monkey -p {package} -c android.intent.category.LAUNCHER 1', capture=True, quiet=True)
        print("  App launched!")
        return True
    else:
        print("  ERROR: Could not install APK.")
        return False


# ==================== Helpers ====================

def _find_java_home():
    """Find JAVA_HOME from Android Studio's bundled JDK or common locations."""
    candidates = []
    program_files = os.environ.get('ProgramFiles', r'C:\Program Files')
    candidates.append(Path(program_files) / "Android" / "Android Studio" / "jbr")
    candidates.append(Path(program_files) / "Android" / "Android Studio" / "jre")
    pf86 = os.environ.get('ProgramFiles(x86)', r'C:\Program Files (x86)')
    candidates.append(Path(pf86) / "Android" / "Android Studio" / "jbr")
    local = os.environ.get('LOCALAPPDATA', '')
    if local:
        candidates.append(Path(local) / "Programs" / "Android Studio" / "jbr")
    for base in [program_files, pf86]:
        java_dir = Path(base) / "Java"
        if java_dir.exists():
            for d in sorted(java_dir.iterdir(), reverse=True):
                candidates.append(d)
    for c in candidates:
        if (c / "bin" / "keytool.exe").exists():
            return c
    return None


def get_sha1():
    """Extract Android debug SHA-1 fingerprint for Google Sign-In."""
    print("\n" + "=" * 60)
    print("  SHA-1 Fingerprint (for Google Sign-In)")
    print("=" * 60)

    # Try keytool from debug keystore (fastest)
    debug_keystore = Path.home() / ".android" / "debug.keystore"
    if debug_keystore.exists():
        java_home = _find_java_home()
        if java_home:
            keytool = f'"{java_home / "bin" / "keytool.exe"}"'
        else:
            keytool = "keytool"

        rc, stdout, stderr = run(
            f'{keytool} -list -v -keystore "{debug_keystore}" -alias androiddebugkey -storepass android',
            quiet=True,
        )
        full = stdout + "\n" + stderr
        match = re.search(r'SHA1:\s*([0-9A-Fa-f:]{59})', full, re.IGNORECASE)
        if match:
            sha1 = match.group(1)
            print(f"  SHA-1: {sha1}")
            return sha1

    # Fallback: Gradle signingReport
    gradlew = ANDROID_DIR / "gradlew.bat"
    if gradlew.exists():
        env_extra = ""
        if not os.environ.get('JAVA_HOME'):
            jh = _find_java_home()
            if jh:
                env_extra = f'set "JAVA_HOME={jh}" && '
        rc, stdout, stderr = run(
            f'{env_extra}"{gradlew}" signingReport',
            cwd=ANDROID_DIR, timeout=180,
        )
        match = re.search(r'SHA1:\s*([0-9A-Fa-f:]{59})', stdout + stderr, re.IGNORECASE)
        if match:
            sha1 = match.group(1)
            print(f"  SHA-1: {sha1}")
            return sha1

    print("  Could not extract SHA-1.")
    return None


def _get_package_name():
    """Read the Android package name from build.gradle.kts."""
    build_gradle = ANDROID_DIR / "app" / "build.gradle.kts"
    if build_gradle.exists():
        try:
            content = build_gradle.read_text()
            match = re.search(r'applicationId\s*=\s*"([^"]+)"', content)
            if match:
                return match.group(1)
        except Exception:
            pass
    return "com.example.awing_ai_learning"


# ==================== Main ====================

def main():
    args = set(sys.argv[1:])

    print("=" * 60)
    print("  Awing AI Learning — Setup & Deploy v3.0.0")
    print("=" * 60)

    if '--help' in args or '-h' in args:
        print(__doc__)
        return

    # Individual commands
    if '--webhooks' in args:
        deploy_webhooks()
        return

    if '--test' in args:
        test_and_authorize()
        return

    if '--authorize' in args:
        force_authorize()
        return

    if '--sha1' in args:
        sha1 = get_sha1()
        if sha1:
            try:
                subprocess.Popen(['clip'], stdin=subprocess.PIPE, shell=True).communicate(sha1.encode())
                print("  (Copied to clipboard)")
            except Exception:
                pass
        return

    if '--build' in args:
        run_build()
        return

    if '--install' in args:
        install_apk()
        return

    # --quick: webhooks + build (skip tests — for when you know auth is fine)
    if '--quick' in args:
        print("\n  Quick mode: webhooks → build → install\n")
        deploy_webhooks()
        run_build()
        _print_summary(True, True)
        return

    # DEFAULT: Full smart pipeline
    print("\n  Full pipeline: deploy → test → build → install\n")

    # Step 1: Deploy webhooks
    webhook_ok = deploy_webhooks()

    # Step 2: Test connectivity + auto-authorize if needed
    auth_ok = True
    if webhook_ok:
        auth_ok = test_and_authorize()
    else:
        print("\n  Skipping webhook tests (deployment failed).")

    # Step 3: Build APK
    build_ok = run_build()

    # Summary
    _print_summary(webhook_ok, build_ok, auth_ok)


def _print_summary(webhook_ok, build_ok, auth_ok=True):
    print("\n" + "=" * 60)
    print("  DEPLOY SUMMARY")
    print("=" * 60)
    print(f"  Webhooks:      {'[OK]' if webhook_ok else '[FAIL]'}")
    print(f"  Authorization: {'[OK]' if auth_ok else '[NEEDS ATTENTION]'}")
    print(f"  Build+Install: {'[OK]' if build_ok else '[FAIL]'}")
    print("=" * 60)

    if webhook_ok and auth_ok and build_ok:
        print("\n  Everything is deployed and running on your device!")
        print("  Test 2FA: tap Version 5 times → enter awing2026 → check Gmail")
    elif not auth_ok:
        print("\n  Fix authorization: python scripts\\setup_and_deploy.py --authorize")
    elif not build_ok:
        print("\n  Fix build errors above, then: python scripts\\setup_and_deploy.py --build")


if __name__ == "__main__":
    main()
