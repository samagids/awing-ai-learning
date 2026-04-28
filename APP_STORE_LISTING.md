# App Store Connect Listing — Awing AI Learning

This is the iOS App Store Connect equivalent of `STORE_LISTING.md` (Play Store). Field
definitions and character limits below match Apple's current App Store Connect schema
(2026-04). Differences from Play Store are flagged inline.

---

## App Information

### Name (30 char max — Apple)

```
Awing AI Learning
```

(17 / 30)

Apple rules: no feature words like "Pro" or "Free", no emoji, no promotional language,
no category names. The current name passes all checks.

### Subtitle (30 char max — Apple-specific)

```
Learn Awing — Cameroon Bantu
```

(28 / 30)

Apple subtitle is a one-line value prop shown directly below the app name. Cannot
match the name. Apple does NOT search-rank the subtitle, but it heavily influences
tap-through rate from search results. Reads cleanly on the new compact app card layout.

Alternates rejected: "Awing language for kids" (15 chars, kid-only positioning is
tighter than the truth), "Awing alphabet, words, quizzes" (32 — over limit by 2).

### Promotional Text (170 char max — editable without review)

```
1,500+ Awing words from the 2007 dictionary. Six native-sounding character voices.
Quizzes, stories, classroom exam mode. Free, offline-first, kid-friendly.
```

(160 / 170)

Apple-specific field that does NOT trigger app review when changed. Use it for short-
term announcements (new content drops, feature highlights). Visible above the
description on the product page.

### Description (4000 char max)

```
Awing AI Learning is a free, interactive language learning app designed to teach the
Awing language — a Grassfields Bantu language spoken by about 19,000 people in the
Mezam division, North West Province, Republic of Cameroon. Built for kids and
beginners, the app features colorful lessons, fun quizzes, and pronunciation practice
across three difficulty levels.

BEGINNER LEVEL

• Awing alphabet — 22 consonants and 9 vowels, each with audio and example words
• Vocabulary — over 600 everyday words across body parts, animals, food, family,
  actions, and more
• Phrases & greetings — common conversational openers verified from the 2005 Awing
  Orthography Guide
• Tones — basic awareness of high, mid, low, rising, and falling tones
• Numbers — counting one through ten in Awing
• Pronunciation practice — record yourself and compare to native-style references
• 10 quiz packs of 20 multiple-choice questions each
• Spaced repetition review of words you missed

MEDIUM LEVEL

• Short everyday sentences from the orthography guide
• Consonant clusters — prenasalized (mb, nd, ng, nj), palatalized (ty, ky, py),
  labialized (kw, tw, gw)
• Vowels & syllables — including the 7 long vowels and contrastive minimal pairs
• Noun classes — singular/plural patterns across the language's 9+ noun classes
• Sentence building exercises with word-by-word breakdowns
• Difficult words — high-difficulty vocabulary surfaced only at this level
• Writing quiz — fill-in-the-blank sentences

EXPERT LEVEL

• Tone mastery — advanced tone identification across minimal pairs
• Sound changes — allophonic rules drawn from the 2009 Awing Phonological Sketch
• Elision rules — long and short forms of words
• Long-form conversations and role-play dialogues
• Expert quiz — paragraph-length fill-in-the-blank challenges, 10 quiz packs

STORIES MODE

• Original short stories with sentence-by-sentence progression
• Awing text alongside English translation
• Per-story vocabulary highlights and comprehension quizzes

CLASSROOM EXAM MODE

• Teachers host a Kahoot-style live exam over local Wi-Fi
• Students join with a 6-digit PIN — no internet required
• Teacher monitors progress live and approves each student
• Filter exam content by source (vocabulary, alphabet, phrases, tones, mixed) and by
  category (body parts, animals, food, etc.)

VOICE & AUDIO

• Six character voices — boy, girl, young man, young woman, man, woman — chosen by
  difficulty level
• Audio for over 7,500 words and phrases included
• Pronunciation references from authentic native speaker recordings where available

GAMIFICATION

• XP system — earn points for lessons, quizzes, and badges
• 9 achievement badges across vocabulary, tone mastery, streaks, and more
• Daily streak tracking
• Per-profile progress so siblings can each have their own learning track

PRIVACY & SAFETY

• Sign in with Google (Sign in with Apple available where required)
• Cloud progress sync via Firebase — encrypted in transit
• Parent PIN to reset child progress and access settings
• Anonymous opt-out analytics
• No third-party advertising, no in-app purchases, no in-app browser

ABOUT THE AWING LANGUAGE

Awing is a tonal Grassfields Bantu language with three pitch levels (high, mid, low)
plus rising and falling tones. It has a rich consonant system including prenasalized
stops and palatalized clusters. The app's linguistic content is based on the 2005
Awing Orthography Guide (Alomofor & Anderson), the 2009 Awing Phonological Sketch
(van den Berg, SIL Cameroon), and the 2007 Awing English Dictionary (CABTAL).

Created by Dr. Guidion Sama to help preserve and promote the Awing language for
future generations.

Contact: samagids@gmail.com
```

(approx 3,650 / 4,000)

### Keywords (100 char max — comma-separated, no spaces, NO words from title)

```
awing,bantu,cameroon,african,language,kids,vocabulary,quiz,phonics,tonal,grassfields,classroom
```

(98 / 100)

Apple keyword rules:
- No spaces between commas (every space costs a char)
- Do NOT repeat words from name/subtitle (Apple already indexes those — wastes budget)
- Avoid plurals if singular is in title
- No category names like "education" (Apple already uses category for ranking)
- Multi-word phrases use commas (Apple stitches related words automatically)

Words rejected to fit budget: "language" appears once vs. competing alternatives;
"learn" was redundant with subtitle; "africa" lost to "african" (more specific search);
"alphabet" lost to "phonics" (broader category).

### What's New (4000 char max — Apple — much bigger than Play Store's 500)

```
1.11.0 — Vocabulary expansion + audio overhaul

VOCABULARY
• Over 1,300 new words added from the 2007 Awing English Dictionary, bringing the
  total to roughly 3,200 words
• Cleaner, single-sentence English glosses across the entire dictionary
• 21 dictionary-conflict glosses corrected against the published source

AUDIO
• Native speaker recordings now play as the priority pronunciation source for all
  words Dr. Sama has voiced
• Six character voices regenerated end-to-end with cleaner Bantu phoneme handling
• gh / ɣ words now pronounce correctly instead of being spelled letter-by-letter

CONTENT
• 30 new phrases, 40 new sentences, and 4 new short conversations sourced and
  filtered from the Awing New Testament corpus — religious markers stripped
• Six new short stories
• 10 new expert-level paragraph quizzes

EXAM MODE
• Filter exam content by source (vocabulary, alphabet, phrases, tones, mixed)
• Multi-select category filter for vocabulary-based exams
• Question prompts now read in a kid-friendly voice and never reveal the answer
  through the picture

INTERFACE
• All quiz and exam screens are now scrollable on small phones
• Picture and answer layout reorganized for one-handed use
• Dark mode toggle removed — too many screens had hardcoded colors and were
  unreadable in dark; we will rebuild this properly in a future release

CLOUD & SAFETY
• Per-profile progress now syncs to Firebase Cloud Firestore — switching devices no
  longer loses your child's progress
• Parent PIN to reset child progress
• Native-speaker-recorded contributions are now wired through the contribution
  approval flow, so future updates can integrate community recordings
```

(approx 1,650 / 4,000)

### Category

- Primary: **Education**
- Secondary: **Reference**

### Age Rating (computed from questionnaire)

Same answers as Play Store IARC questionnaire — all "no" except "Unrestricted Web
Access = No" — yields an age rating of **4+**. Lowest possible Apple rating.

### Pricing

**Free** — no in-app purchases, no subscriptions.

### Availability

All territories where Apple App Store operates. No territorial restrictions.

### Routing App Coverage

N/A — not a navigation app.

---

## Privacy Nutrition Labels

Apple requires a structured per-app privacy disclosure shown on the product page.
The form is filled at App Store Connect → App Privacy → Edit. Below is the answer
key for every prompt.

### Step 1 — Does this app collect data?

**Yes.**

### Step 2 — For each data type below, click "Yes" if collected.

| Apple category | Collected? | What it is |
|---|---|---|
| **Contact Info → Email Address** | YES | Google Sign-In email |
| **Contact Info → Name** | YES | Google Sign-In display name |
| **Contact Info → Phone Number** | no | — |
| **Contact Info → Physical Address** | no | — |
| **Contact Info → Other User Contact Information** | no | — |
| **Health & Fitness** | no | — |
| **Financial Info** | no | — |
| **Location → Precise Location** | no | — |
| **Location → Coarse Location** | no | — |
| **Sensitive Info** | no | — |
| **Contacts** | no | — |
| **User Content → Emails or Text Messages** | no | — |
| **User Content → Photos or Videos** | no | — |
| **User Content → Audio Data** | YES | Pronunciation recordings the user submits as contributions, or as part of the optional "record yourself" pronunciation practice (recordings stay on-device unless user explicitly shares) |
| **User Content → Gameplay Content** | no | — |
| **User Content → Customer Support** | no | — |
| **User Content → Other User Content** | YES | Text-based contribution suggestions (corrected spellings, new words) |
| **Browsing History** | no | — |
| **Search History** | no | — |
| **Identifiers → User ID** | YES | Google account UID + Firebase Auth UID |
| **Identifiers → Device ID** | YES | Anonymous device identifier for analytics (random hex, not tied to advertising ID, not the IDFA) |
| **Purchases** | no | — |
| **Usage Data → Product Interaction** | YES | Lessons viewed, quizzes taken, scores, session length |
| **Usage Data → Advertising Data** | no | — |
| **Usage Data → Other Usage Data** | no | — |
| **Diagnostics → Crash Data** | YES | Error events caught by AnalyticsService.logError |
| **Diagnostics → Performance Data** | no | We do not collect FPS, hangs, or render time metrics |
| **Diagnostics → Other Diagnostic Data** | no | — |
| **Other Data Types** | no | — |

### Step 3 — For each YES, fill the four follow-up questions.

#### Email Address (Contact Info)

- **Is it linked to the user's identity?** Yes
- **Is it used for tracking?** No
- **Purposes:**
  - App Functionality (sign-in, account recovery, cloud sync key)
  - Analytics — NO
  - Product Personalization — NO
  - Developer's Advertising or Marketing — NO
  - Third-Party Advertising — NO
  - Other Purposes — NO

#### Name (Contact Info)

- **Linked to identity?** Yes
- **Used for tracking?** No
- **Purposes:**
  - App Functionality (greeting, profile display)

#### Audio Data (User Content)

- **Linked to identity?** Yes (only when user signed in)
- **Used for tracking?** No
- **Purposes:**
  - App Functionality (contribution submission, pronunciation comparison)

#### Other User Content (text contributions)

- **Linked to identity?** Yes
- **Used for tracking?** No
- **Purposes:**
  - App Functionality

#### User ID

- **Linked to identity?** Yes (it IS the identity key)
- **Used for tracking?** No
- **Purposes:**
  - App Functionality (Firebase Auth, cloud sync)

#### Device ID (anonymous analytics ID)

- **Linked to identity?** No — random hex string, not the IDFA, not tied to email
- **Used for tracking?** No
- **Purposes:**
  - Analytics

#### Product Interaction

- **Linked to identity?** No — analytics events keyed on the anonymous device ID
- **Used for tracking?** No
- **Purposes:**
  - Analytics

#### Crash Data

- **Linked to identity?** No
- **Used for tracking?** No
- **Purposes:**
  - App Functionality (debugging — Dr. Sama receives error logs to fix bugs)

### Step 4 — Tracking declaration

**Does this app collect data that is linked to the user or device for tracking
purposes (Apple's definition: linking user/device data with third-party data for
advertising or measurement)?**

**No.**

The app does not include third-party advertising SDKs. Analytics data (event logs,
device ID) is collected for the developer's own product improvement and is not
shared with data brokers or used for cross-app/cross-website ad tracking.

### Step 5 — App Tracking Transparency (ATT) prompt

**Required?** No. The app does not need to call `requestTrackingAuthorization` because
it does not access the IDFA and does not use any tracking SDK. No ATT prompt will
be shown to users.

---

## Required URLs

| Field | URL |
|---|---|
| Privacy Policy URL | `https://samagids.github.io/awing-ai-learning/privacy-policy.html` |
| Marketing URL (optional) | leave blank for v1 |
| Support URL | `mailto:samagids@gmail.com` (or a GitHub Issues link if preferred) |
| App Routing | N/A |

Note: Apple requires an HTTP(S) Privacy Policy URL — `mailto:` is not accepted there.
The same URL used for Play Store works.

---

## Sign in with Apple (Guideline 4.8 — IMPORTANT)

Since the app offers **Sign in with Google** as a third-party identity provider, App
Store Review Guideline 4.8 ("Login Services") REQUIRES that the app also offer at
least one option that meets these criteria:
- Limits data collection to name and email
- Allows the user to keep their email private
- Does not track users across apps without consent

**Sign in with Apple meets all three criteria.** Without it, Apple will reject the
build at review.

Implementation notes for v1.11.x:
- Add `sign_in_with_apple` Flutter package (~1MB, Apple-only on iOS)
- In `lib/screens/auth/login_screen.dart`, conditionally show "Sign in with Apple"
  button when `Platform.isIOS` (preserves Android UI unchanged)
- Wire `AuthService.signInWithApple()` mirroring the existing `signInWithGoogle()`
  shape — same UserAccount return type
- In Firebase Console → Authentication → Sign-in method → enable Apple provider
- In Apple Developer portal → Certificates, Identifiers & Profiles → Identifiers →
  edit `com.awing.awingAiLearning` → Capabilities tab → enable "Sign in with Apple"
- This requires the Apple Developer account to be approved first (in flight)

This is a hard blocker for App Store approval — must be done before submitting v1
to Apple.

---

## Submission Checklist

- [ ] Apple Developer account approved (in flight, ~48 hours from 2026-04-26)
- [ ] Sign in with Apple implemented in lib/screens/auth/login_screen.dart
- [ ] Apple Developer Identifier `com.awing.awingAiLearning` registered with Sign in
      with Apple capability
- [ ] Firebase Auth → Apple provider enabled
- [ ] App Store Connect entry created (app name, bundle ID, primary language, SKU)
- [ ] Distribution certificate generated (auto via Xcode or manual via Developer
      portal)
- [ ] Provisioning profile generated for `com.awing.awingAiLearning`
- [ ] `ios/ExportOptions.plist` updated with real Team ID and Provisioning Profile
      name
- [ ] GitHub Actions iOS secrets configured: BUILD_CERTIFICATE_BASE64, P12_PASSWORD,
      BUILD_PROVISION_PROFILE_BASE64, KEYCHAIN_PASSWORD
- [ ] iOS-sized screenshots generated (6.9" iPhone Pro Max 1320×2868 + 6.5"
      iPhone Plus 1284×2778). iPad screenshots NOT required (TARGETED_DEVICE_FAMILY=1).
- [ ] App icon 1024×1024 PNG (no alpha, no rounded corners — Apple applies the
      mask) — repurpose `store_listing/icon_512.png` upscaled
- [ ] Privacy Nutrition Labels filled per § above
- [ ] Age Rating questionnaire completed (yields 4+)
- [ ] Build uploaded via Xcode Organizer or Transporter
- [ ] First release submitted for review

---

*This file mirrors STORE_LISTING.md (Play Store) for App Store Connect submission.
Update both when adding a new version.*
