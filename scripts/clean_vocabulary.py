#!/usr/bin/env python3
"""
Remove OCR garbage entries from awing_vocabulary.dart

This script identifies and removes 59 OCR artifact entries that slipped through
the dictionary extraction process from the Awing English Dictionary PDF.

Garbage types:
1. Sentence fragments from PDF introduction (definitions that start with "Awing has", "reading,", etc.)
2. OCR artifacts in Awing field (text like "owel", "ofo", "eedle v", "ot to fall")
3. Dictionary structural elements (pipe chars, brackets, numbered entries)
"""

import re

# Line numbers and awing field values of entries to remove (from comprehensive audit)
GARBAGE_ENTRIES = {
    1112: 'ariety of',
    1114: 'asal prefixes',
    1150: 'eedle v',
    1152: 'ery early',
    1153: 'et np',
    1154: 'ext to each',
    1177: 'jwaa',  # Has corrupted definition with pipes and phonetic fragments
    1286: 'o problem pronouncing',
    1287: 'ofo',
    1288: 'owel',
    1289: 'owels',
    1310: 'sfooghsams',
    1371: 'asal consonant',
    1427: 'ssy ngdba akoobs',
    1460: 'eedle n',
    1524: 'alue n',
    1535: 'arrow place',
    1549: 'chwitd ngona',
    1564: 'ice versa',
    1575: 'kwed ndotia',
    1577: 'kwiga md nwins',
    1591: 'mofoomea',  # Has corrupted definition
    1601: 'owels and',
    1602: 'owels and diphthongs',
    1654: 'anua nefoona',
    1668: 'chaakd mangyé',
    1675: 'ery close',
    1701: 'mbdga ati',
    1704: 'na mbaema',
    1744: 'akona ngasans',
    1745: 'akoya ngasana',
    1761: 'chib nowtia',
    1763: 'ji nti mojio',
    1790: 'pay santé',
    1817: 'ast and dry',
    1825: 'ia sex',
    1841: 'nachwéla',  # Has pipe character in definition
    1843: 'napem na atia',
    1845: 'ndtumbia',
    1852: 'nofand',  # Has pipes and corrupted definition
    1859: 'ogha megheems',
    1860: 'ot to fall',
    1872: 'a ae',
    1873: 'acent vowels',
    1875: 'achia tapone',
    1881: 'aftio oghama',
    1890: 'akama atsab nité',
    1895: 'akoma mba',
    1911: 'alandnkyia',  # Has pipes and corrupted definition
    1926: 'ame in',
    1927: 'ame of animal',
    1947: 'arious levels',
    1952: 'asal consonants',
    1953: 'asal prefix',
    1997: 'chi mya',
    2008: 'ery long',
    2075: 'mokeemsd',  # Has pipes in definition
    2106: 'ndu atsama',
    2127: 'nka kwin',
    2128: 'nkeend akydamo',
    2131: 'nkoy ndopa',
    2159: 'ocant place',
    2162: 'onu katana',
    2165: 'ot coming here',
    2166: 'ot high',
    2167: 'ot syllabic',
    2171: 'ow extinct',
    2172: 'ow he',
    2173: 'owel in question',
    2220: 'umber of entries',
    2221: 'uts and egussi',
}

def remove_garbage_entries(filepath):
    """Remove garbage entries from awing_vocabulary.dart"""

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Track which lines to remove (by line number in file)
    lines_to_remove = set()

    # For each garbage entry, find and mark the entire AwingWord() line for removal
    for awing_field in GARBAGE_ENTRIES.values():
        # Escape special regex chars
        escaped_awing = re.escape(awing_field)
        pattern = rf"AwingWord\(awing:\s*'{escaped_awing}'"

        for i, line in enumerate(lines):
            if re.search(pattern, line):
                lines_to_remove.add(i)
                print(f"Found garbage entry at line {i+1}: awing='{awing_field}'")
                break

    # Remove marked lines
    cleaned_lines = [line for i, line in enumerate(lines) if i not in lines_to_remove]

    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(cleaned_lines)

    print(f"\nRemoved {len(lines_to_remove)} garbage entries")
    print(f"File has {len(lines)} lines originally, now {len(cleaned_lines)} lines")
    print(f"Change: -{len(lines_to_remove)} lines")

    return len(lines_to_remove)

if __name__ == '__main__':
    import sys

    vocab_file = '/sessions/vibrant-lucid-albattani/mnt/Awing/lib/data/awing_vocabulary.dart'

    if len(sys.argv) > 1:
        vocab_file = sys.argv[1]

    print(f"Cleaning {vocab_file}...")
    count = remove_garbage_entries(vocab_file)
    print(f"\nDone! Removed {count} OCR garbage entries.")
