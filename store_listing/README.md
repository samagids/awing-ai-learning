# Google Play Store Submission Files

This directory contains all materials needed to submit **Awing AI Learning** to the Google Play Store.

## Files Included

### 1. **STORE_LISTING.md** (Primary Copy-Paste Source)
Contains the exact text to paste into Google Play Console:
- App name (30 chars)
- Short description (80 chars)
- Full description (4,000 chars)
- Category & keywords
- Content rating information
- Contact & privacy policy URLs
- Release notes & promotional text
- Store listing compliance checklist

**Usage:** Open in text editor, copy each section, paste into Play Console fields.

### 2. **privacy_policy.html** (Beautiful Styled Version)
Professional HTML privacy policy with:
- Responsive design (works on desktop & mobile)
- Styled with gradients and professional colors
- All COPPA requirements covered
- Google Sign-In & Firebase data handling explained
- User rights & data security sections
- Contact information & legal compliance

**Usage:** 
- Host on web server and link in Play Console
- Or upload directly to GitHub Pages
- URL example: `https://samagids.github.io/awing-ai-learning/privacy`

### 3. **privacy.md** (Markdown Version)
GitHub Pages compatible markdown version of the privacy policy.
- Same content as HTML version
- Better for version control (in Git)
- Renders nicely on GitHub

**Usage:** Place in `/docs/privacy.md` on GitHub, GitHub Pages auto-publishes at `https://samagids.github.io/repo-name/privacy`

### 4. **SUBMISSION_GUIDE.md** (Step-by-Step Instructions)
Complete walkthrough for submitting to Google Play:
- Phase 1: Developer account setup
- Phase 2: Store listing entry
- Phase 3: APK/AAB upload
- Phase 4: Privacy & security configuration
- Phase 5: Testing procedures
- Phase 6: Post-submission monitoring
- Common rejections & solutions
- Pre-launch verification checklist
- File location reference
- Timeline estimates

**Usage:** Follow step-by-step when ready to submit.

---

## Quick Start

### For Immediate Submission:

1. **Open `STORE_LISTING.md`** → Copy app description sections
2. **Go to [Google Play Console](https://play.google.com/console)**
3. **Paste into Store Listing > Main store listing**
4. **Upload privacy policy:**
   - Option A: Host `privacy_policy.html` on web server
   - Option B: Use GitHub Pages URL: `https://samagids.github.io/awing-ai-learning/privacy`
5. **Follow `SUBMISSION_GUIDE.md`** for remaining steps

### For First-Time Setup:

1. **Read `SUBMISSION_GUIDE.md`** Phase 1 (Developer Account)
2. **Follow all steps** in SUBMISSION_GUIDE.md
3. **Reference `STORE_LISTING.md`** for content
4. **Upload `privacy_policy.html`** for privacy policy

---

## Key Information

**App Details:**
- Name: Awing AI Learning
- Package: com.awing.awing_ai_learning
- Version: 1.2.0 (Build 4)
- Category: Education
- Target: Ages 5+
- Privacy: COPPA-compliant

**What's Included:**
- 1,700+ vocabulary words
- 3 difficulty levels (Beginner, Medium, Expert)
- 6 character voices
- Spaced repetition system
- Gamification (XP, badges, streaks)
- Contribution system
- Exam mode for teachers
- Dark mode
- Offline-first (no internet required)
- NO ads, NO tracking, NO in-app purchases

**Permissions Required:**
- `RECORD_AUDIO` — for pronunciation practice
- `INTERNET` — for Google Sign-In & Firebase sync (optional)

---

## Files Ready for Use

| File | Size | Purpose | Ready |
|------|------|---------|-------|
| STORE_LISTING.md | 12 KB | Copy-paste descriptions | ✓ |
| privacy_policy.html | 19 KB | Styled privacy policy page | ✓ |
| privacy.md | 9.5 KB | Markdown privacy policy | ✓ |
| SUBMISSION_GUIDE.md | 14 KB | Step-by-step guide | ✓ |

---

## Privacy Policy URLs

After hosting, use these URLs in Play Console:

**Option 1: GitHub Pages (Recommended)**
```
https://samagids.github.io/awing-ai-learning/privacy
```
(Place `privacy.md` in `/docs/` folder on GitHub, enable GitHub Pages)

**Option 2: Personal Website**
```
https://your-domain.com/awing-privacy-policy.html
```
(Upload `privacy_policy.html` to your server)

**Option 3: Direct GitHub Raw**
```
https://raw.githubusercontent.com/samagids/awing-ai-learning/main/docs/privacy.md
```
(Use raw GitHub link, though plain markdown renders less nicely)

---

## Content Verification Checklist

Before submitting, verify:

- [ ] All Awing words match official sources
- [ ] No fabricated phrases (all from PDF sources)
- [ ] Tone marks are correct (á high, à low, â falling, ǎ rising)
- [ ] 1,700+ vocabulary words present
- [ ] 6 character voices functional
- [ ] All lessons accessible
- [ ] Quizzes work with scoring
- [ ] Dark mode toggles
- [ ] No ads or tracking
- [ ] Google Sign-In optional (app works offline)
- [ ] Privacy policy URL works

---

## Support Resources

**Google Play Console:**
- https://play.google.com/console
- https://support.google.com/googleplay/android-developer/

**COPPA Compliance:**
- https://www.ftc.gov/news-events/news/2013/02/complying-coppa-frequently-asked-questions

**App Security:**
- https://developer.android.com/studio/publish/preparing
- https://firebase.google.com/docs/database/security

**Flutter Deployment:**
- https://flutter.dev/docs/deployment/android

---

## Contact Information

**Developer:** Dr. Guidion Sama, DIT  
**Email:** samagids@gmail.com  
**GitHub:** https://github.com/samagids/awing-ai-learning  
**App Homepage:** https://github.com/samagids/awing-ai-learning

---

## Next Steps

1. **Build APK:** `flutter build apk --release`
2. **Test on device:** Install and verify functionality
3. **Copy store text:** Use `STORE_LISTING.md`
4. **Create Play Console account:** $25 one-time fee
5. **Enter store listing:** Follow `SUBMISSION_GUIDE.md`
6. **Upload privacy policy:** Use `privacy_policy.html` or `privacy.md`
7. **Upload APK/AAB:** `build/app/outputs/`
8. **Submit for review:** Wait 24-48 hours
9. **Go live:** App appears on Play Store

---

**Last Updated:** April 12, 2026  
**Version:** 1.2.0  
**Status:** Ready for submission
