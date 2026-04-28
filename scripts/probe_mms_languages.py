#!/usr/bin/env python
"""
Probe Meta MMS TTS model availability on HuggingFace.

For each candidate language code, does a HEAD request against
  https://huggingface.co/facebook/mms-tts-{code}
and reports 200 (model exists) vs 404 (no model published).

Candidates are organized by genetic distance to Awing (closest first).
No dependencies beyond stdlib — works in any Python 3.x.

Usage:  python scripts\\probe_mms_languages.py
"""
import sys
import urllib.request
import urllib.error
from collections import defaultdict

# Organized closest-to-Awing first. Awing = azo (not in MMS).
# Tier 1 is Awing's own Ngemba subgroup. Tier 6 is non-Bantu longshots.
CANDIDATES = [
    # (tier_label, code, english_name)
    ("1 Ngemba (Awing's own subgroup)",      "bfd", "Bafut"),
    ("1 Ngemba (Awing's own subgroup)",      "nge", "Ngemba / Mankon"),
    ("1 Ngemba (Awing's own subgroup)",      "pny", "Pinyin"),

    ("2 Eastern Grassfields (Bamileke/Bamum)", "bbj", "Ghomala"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "byv", "Medumba"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "fmp", "Fe'fe'"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "ybb", "Yemba"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "nnh", "Ngiemboon"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "jgo", "Ngomba"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "nwe", "Ngwe"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "bax", "Bamum (Shupamem)"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "mhk", "Bali Mungaka"),
    ("2 Eastern Grassfields (Bamileke/Bamum)", "nla", "Ngombale"),

    ("3 Ring Grassfields",                    "bkm", "Kom"),
    ("3 Ring Grassfields",                    "lns", "Lamnso'"),
    ("3 Ring Grassfields",                    "bbk", "Babanki"),
    ("3 Ring Grassfields",                    "agq", "Aghem"),

    ("4 Momo Grassfields",                    "ngj", "Ngie"),
    ("4 Momo Grassfields",                    "mnf", "Mundani"),

    ("5 Southern Bantoid non-Grassfields (Cameroon)", "bss", "Akoose  (Session 8 baseline)"),
    ("5 Southern Bantoid non-Grassfields (Cameroon)", "mcu", "Mambila (Session 8 baseline)"),
    ("5 Southern Bantoid non-Grassfields (Cameroon)", "mcp", "Makaa   (Session 8 baseline)"),
    ("5 Southern Bantoid non-Grassfields (Cameroon)", "bas", "Basaa"),
    ("5 Southern Bantoid non-Grassfields (Cameroon)", "dua", "Duala"),
    ("5 Southern Bantoid non-Grassfields (Cameroon)", "ewo", "Ewondo"),
    ("5 Southern Bantoid non-Grassfields (Cameroon)", "fan", "Fang"),

    ("6 Non-Bantu longshots / reference",     "hau", "Hausa"),
    ("6 Non-Bantu longshots / reference",     "ful", "Fulfulde"),
    ("6 Non-Bantu longshots / reference",     "yor", "Yoruba  (bonus: 3-tone system)"),
    ("6 Non-Bantu longshots / reference",     "ibo", "Igbo    (bonus: tonal)"),
    ("6 Non-Bantu longshots / reference",     "swh", "Swahili (current baseline)"),
]


def check(code: str, timeout: float = 10.0):
    """
    HEAD-request the HF model page. Returns (ok: bool, status: str).
    Follows redirects. 200 = model exists; 404 = no model published.
    """
    url = f"https://huggingface.co/facebook/mms-tts-{code}"
    req = urllib.request.Request(url, method="HEAD",
                                 headers={"User-Agent": "mms-probe/1.0"})
    try:
        resp = urllib.request.urlopen(req, timeout=timeout)
        return True, str(resp.status)
    except urllib.error.HTTPError as e:
        return False, str(e.code)
    except urllib.error.URLError as e:
        return False, f"NET:{e.reason}"
    except Exception as e:
        return False, f"ERR:{e.__class__.__name__}"


def main() -> int:
    print("Probing MMS TTS availability on HuggingFace...")
    print("Checking facebook/mms-tts-{code} for each candidate.\n")

    available = []
    unavailable = []
    by_tier = defaultdict(list)
    for tier, code, name in CANDIDATES:
        by_tier[tier].append((code, name))

    for tier in sorted(by_tier.keys()):
        print(f"\nTier {tier}")
        print("-" * (len(tier) + 5))
        for code, name in by_tier[tier]:
            ok, status = check(code)
            marker = "[OK]" if ok else "[--]"
            # Show the 200/404/timeout code on the right.
            print(f"  {marker}  {code:5s}  {name:40s}  [{status}]")
            sys.stdout.flush()
            if ok:
                available.append((code, name, tier))
            else:
                unavailable.append((code, name, tier))

    print()
    print("=" * 68)
    print(f"SUMMARY: {len(available)} available, {len(unavailable)} not found")
    print("=" * 68)

    if available:
        print("\nAvailable candidates (closest-to-Awing first):")
        for code, name, tier in available:
            print(f"  {code:5s}  {name:40s}  (tier {tier.split()[0]})")

    if unavailable:
        print("\nNo published MMS model for:")
        unavail_codes = ", ".join(code for code, _, _ in unavailable)
        print(f"  {unavail_codes}")

    print()
    print("Next step: run the diagnostic word battery against each")
    print("available model and compare to native YouTube extractions.")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
