# Session 58 Audit — Triage Report

**Files audited:** `lib/screens/expert/conversation_screen.dart` and
`lib/screens/stories_screen.dart`
**Reference:** 2007 Awing English Dictionary (Alomofor Christian, CABTAL)
— 3,094 vision-extracted entries across 18 JSON files in
`contributions/dictionary_extract/`.
**Method:** Tone-stripped headword match (Unicode NFD + combining-mark
strip) → exact-tone match → suffix-stripped stem fallback.

> **Awaiting Dr. Sama's batch approval before any inline Dart edits.**
> Per the Session 52 protocol, no `lib/screens/*.dart` modifications
> happen until each row in this report is marked **APPROVE / SKIP /
> REPLACE**.

---

## 1. Headline numbers

| File | Strings extracted | Tokens | EXACT | TONE_VARIANT | STEM_MATCH | ABSENT |
|---|---|---|---|---|---|---|
| stories_screen.dart | 100 | 96 | 28 | 20 surface forms | 2 | 46 |
| conversation_screen.dart | 26 | 33 | 9 | 11 surface forms | 1 | 12 |

The audit script's TONE_VARIANT bucket counts surface forms — a single
word capitalised at sentence start (e.g. `Mǎ` vs `mǎ`) shows up here
even though the lemma is identical. Most TONE_VARIANT lines are
benign sentence-initial caps; only ~10 across both files are real tone
errors.

---

## 2. Stories (`stories_screen.dart`)

### 2a. Confirmed correct — no action

EXACT matches (28 lemmas, all attested in dict):
afoonə · alá'ə · apô · ayáŋə · azó'ə · fê · júnə · ko · kwágə · kə ·
lê · mǎ · nchîndê · ndzě · ngwáŋə · ngwûə · nkadtə · nkǐə · náŋə ·
nô · nə · nəpóolə · pə · sóŋə · tsó'ə · yə · zó'ə · əshûə

Sentence-initial caps of EXACT/correct words (drop from review queue):
Alá'ə · Apô · Ayáŋə · Mǎ · Ngwûə · Tsó'ə · Yîə · Yə

### 2b. Real tone errors — proposed fixes

| # | Lines | Current (wrong) | Dict says | Proposed fix | Sentence context |
|---|---|---|---|---|---|
| S1 | 411, 759 vocab | `ashî'nə` (falling) | `ashi'nə` (no diacritic) | **ashi'nə** | "Ashî'nə sagɔ́!" (Story 6, Father: "Very good!") and StoryVocabulary `'good'`. Same word as the `descriptiveWords` entry already corrected to `ashi'nə` in Session 52. |
| S2 | 462 | `jíə` (high) | `jîə` (falling) | **jîə** | "Mɔ́ŋkə jíə, yə sóŋə..." (Story 7, "The child ate"). Dict gloss for jîə = "eat / know". |
| S3 | 277 vocab | `nəlwîə` (falling) | `nəlwíə` (high) | **nəlwíə** | StoryVocabulary `'nose'` in Story 4. (Sentence at line 260 already uses `nəlwîə` — must update both.) |
| S4 | 260 | `nəlwîə` (falling) | `nəlwíə` (high) | **nəlwíə** | "Apɛ̌ɛlə náŋə afûə nəlwîə ne nkǐə" (Story 4). |
| S5 | 192 | `pimə` (means "looked at") | dict pímə = "believe / confess" | **náŋə** | Story 3 line 192: "Mbe'tə pɛ́nə pimə akoobɔ́". Same wrong-word pattern Session 52 already replaced 3× elsewhere; this 4th occurrence was missed. |

### 2c. Tone forms that need Dr. Sama's call (cannot be resolved from dict alone)

| # | Lines | Token | Dict candidates | Question for Dr. Sama |
|---|---|---|---|---|
| S6 | 69, 73, 87, 95 | `koŋə` / `Koŋə` (= "owl") | dict: `kóŋə` "crawl" / `koŋə̂` "yell with hate" — neither = owl | Is "owl" a real Awing word `koŋə` (homonym not in dict)? Or should the title animal be a different word? |
| S7 | 304 | `ndê` (= "house/home") | dict: `ndě` (rising) = "neck / elder" | Is `ndê` for "house" correct, or should this be a different word entirely? |
| S8 | 333, 466 | `ndê` (= "home") | same as S7 | "Ngwûə ŋwàŋə ndê" / "Yə ŋwàŋə ndê ne mǎ" — same homonym question. |
| S9 | 367, 371 | `kə̂ŋə` (= "early") | dict: `kəŋə` "steep place" / `kəŋə̂` "shut" — neither = early | "Tǎ ghɛnɔ́ afoonə kə̂ŋə" — does `kə̂ŋə` mean "early"? If not, propose replacement. |
| S10 | 367 | `Tǎ` (caron, = "father") | dict: `tă` (breve, = "father / parent") | Same rising-tone phoneme written two different ways (caron vs breve). Standardize to which? Orthography PDF p.7 uses `ǎ` (caron). |
| S11 | many | `yǐə` (rising, = "come") | dict: `yîə` (falling) = demonstrative / future-tense marker | Session 30 already ruled `yǐə` (rising) is the correct "come" verb per Orthography p.8. **No fix — keep as-is.** Listed here only to confirm we don't reverse the Session 30 ruling. |

### 2d. ABSENT — likely-valid lexical items missing from 2007 dictionary

These appear in stories but are not in the dictionary. They are
plausibly real Awing words that the 2007 reference simply didn't
catalogue. **Need Sama confirmation before being treated as canonical
in vocabulary lists, but no edit needed for stories.**

| Class | Tokens |
|---|---|
| Functional / grammar | `ne` (and/with), `nyɛ́ə` (was/were copula) |
| Verb inflected forms | `ghɛnɔ́` (went), `ŋwàŋə` (return), `mîə` (swallow), `tɔ̀ə` (plant), `tɔnɔ́` (hot), `kə́ərə` (run), `shɔ́ŋə` (climb), `kwɨ̌nə` (ask), `wâakɔ́`, `wiŋɔ́`, `wíŋɔ́` (happy/big), `sagɔ́` (very — PDF-attested, Session 30) |
| Lexical content (animals/nature/things) | `akoobɔ́` (forest), `aləmə` (cloud), `amú'ɔ́` (banana), `asɨ́ə` (houses pl.), `atîə` (tree/fire), `lámɔ́sə` (orange), `mbe'tə` (shoulder/young person), `mbəŋə` (rain), `mɔ́numə` (sun), `mətéenɔ́` (market — PDF-attested), `ngɔ́bə` (chicken), `ngəsáŋɔ́` (corn), `nəgoomɔ́` (plantain), `pɛ́nə` (dance), `pəlɛ́ə` (people), `pəyə` (fathers? — possible plural of `yə`), `əmɔ́` (one) |
| Proper nouns / dialogue particles | `Apɛ̌ɛlə` (character name), `Cha'tɔ́` / `cha'tɔ́` (greeting), `Mbɔ́ɔnɔ́` (thank you), `Mɔ́ŋkə` (child), `Pəmǎ` / `pəmǎ` (mothers pl.), `ndèe` (politeness particle, "again") |
| OCR / segmentation artifact | `shûə` (false split — `əshûə` was tokenised twice; ignore) |

### 2e. ABSENT — capitalised duplicates (no extra question)

`Aləmə`, `Mbe'tə`, `Mbəŋə`, `Mɔ́numə`, `Məkəŋɔ́` (= "pots", plural of
`nəkəŋɔ́`), `Ngɔ́bə` — same lemmas as 2d, just sentence-initial caps.

### 2f. STEM_MATCH (informational only, no fix)

`nəkəŋɔ́` → stems to `nəkəŋ` "pot" (regular noun-class inflection, OK)
`pə̀ə` → stems to `pə` "then" (verb form, OK)

---

## 3. Conversations (`conversation_screen.dart`)

### 3a. Confirmed correct — no action

EXACT matches (9 lemmas):
ajúmə · apô · ko · kwa'ə · kə · mǎ · mə · nə · pə

Sentence-initial caps of EXACT words: `Apô`, `Ko`, `Mǎ`, `Yə`.

### 3b. Real tone errors — proposed fixes

| # | Tokens | Dict says | Proposed fix | Notes for Sama |
|---|---|---|---|---|
| C1 | `Kó` / `kó` (high tone) | `ko` (no diacritic) = "take / listen" | **Ko / ko** | Audit shows `ko` is the EXACT match. Confirm `kó` is not a separate verb. |
| C2 | `Wo` (no diacritic) | `wô` (falling) = demonstrative "that" | **Wô** if the conversation means "that" | Need to see the conversational context — `Wo'!` may be a discourse marker, not the demonstrative. |
| C3 | `ntô` (falling) | `nto` (no diacritic) = "trousers" | **nto** if "trousers" intended | If `ntô` means something else in dialogue (interjection?), keep as-is. |
| C4 | `po` (no diacritic) | dict has `pô` (demonstrative "those") OR `pó` (and / with) | **pô** or **pó** depending on grammatical role | Possibly a third lemma "they" pronoun not in dict. |
| C5 | `zə` (no diacritic) | `zə̂` (falling) = demonstrative "that (already discussed)" | **zə̂** if demonstrative intended | Otherwise leave. |
| C6 | `yǐə` (rising) | `yîə` (falling) | **No fix — Session 30 ruling stands** | Same as S11 above; keep `yǐə` for "come". |

### 3c. ABSENT — likely-valid dialogue particles missing from 2007 dictionary

These are conversational words used in greetings and replies. Most
are probably real but the 2007 dictionary is lexical, not
conversational, so it doesn't catalogue them. **All need Sama
confirmation; no automatic edits.**

| Token | Likely meaning | Question |
|---|---|---|
| `Cha'tɔ́` / `cha'tɔ́` | greeting "hello" | Is this the standard Awing hello? |
| `Ee` | affirmative "yes" | Confirm spelling. |
| `Ndèe` / `ndèe` | "again / please" politeness particle | Confirm spelling/tones. |
| `Tifwə` | possibly honorific or "good morning" | Real word? Spelling? |
| `Wə` / `wə` | pronoun "you" (singular)? | Real Awing 2sg pronoun? |
| `asé` | possibly "place / sit" or imperative | Real word? |
| `fɛ́ə` | ? | Need gloss + verification. |
| `lɛ́ə` | ? | Need gloss + verification. |
| `nəgoomɔ́` | "plantain" | Same as in stories — likely valid. |
| `wǎ` | ? | Need gloss + verification. |

### 3d. STEM_MATCH (informational only)

`kwátə` → stems to `kwa` "four" (regular numeral inflection, OK).

---

## 4. Recommended action plan

**Tier 1 — apply now if Dr. Sama approves all of §2b and §3b** (8 dict-
attested tone fixes, no semantic risk):

```
stories_screen.dart:
  L 192:  pimə    → náŋə        (S5: replace wrong-word, mirror Session 52)
  L 260:  nəlwîə  → nəlwíə      (S4)
  L 277:  nəlwîə  → nəlwíə      (S3, vocab list)
  L 411:  ashî'nə → ashi'nə     (S1, vocab list)
  L 462:  jíə     → jîə         (S2)
  L 759:  ashî'nə → ashi'nə     (S1, vocab list)

conversation_screen.dart (pending Sama's call on each):
  Kó / kó → Ko / ko     (C1, after Sama confirms no separate kó verb)
  ntô     → nto          (C3, only if "trousers" intended)
  zə      → zə̂           (C5, only if "that-demonstrative" intended)
```

Each change carries an inline `// Session 58 audit: was "X" — dict
says "Y"` comment per Session 52 convention.

**Tier 2 — needs Sama's gloss verdict** (§2c S6–S9, conversations C2,
C4, plus the 12 ABSENT dialogue particles in §3c). These are content
or dialogue questions, not tone-mark questions, so cannot be resolved
from the dictionary alone.

**Tier 3 — defer** (§2d ABSENT lexical items). Stories use these in
sentences; the words are likely real Awing but absent from the 2007
reference. No story-screen edit is needed regardless of outcome —
only relevant when these words show up in `awing_vocabulary.dart` or
in quiz/exam distractor pools.

**Out of scope — no action:** §2a, §2e, §2f, §3a, §3d, plus the §2c
S11 / §3b C6 `yǐə` ruling already locked in by Session 30.

---

## 5. Next concrete steps after Dr. Sama's review

1. Mark each row in §2b, §2c, §3b, §3c as **APPROVE / SKIP / REPLACE
   (with text)**.
2. Apply Tier 1 fixes inline with `// Session 58 audit:` comments.
3. Re-run `python3 audit_screens.py` — verify EXACT count rises and
   TONE_VARIANT count drops accordingly.
4. Resume Variant D bake-off:
   `python scripts\xtts_bakeoff.py setup` →
   `python scripts\xtts_bakeoff.py synthesize` →
   `python scripts\bakeoff.py html` → user listening test.
5. Version bump 1.9.0+32 → 1.9.1+33 via the 4-place sync protocol
   (pubspec.yaml, about_screen.dart, analytics_service.dart,
   cloud_backup_service.dart) once §2b corrections + Session 52 gloss
   corrections ship together.

---

*Generated 2026-04-22 from audit_screens.py canonical run.*
