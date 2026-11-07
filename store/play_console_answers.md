# Play Console answers for Boomlets

Prepared from what the app actually does (v0.5.1). Package: `com.manpreetgugga.boomlets`.

## App content

| Section | Answer |
|---|---|
| Privacy policy | https://manpreetgugga.github.io/boomlets/privacy.html |
| Ads | **Yes**, the app contains ads (AdMob rewarded + interstitial) |
| App access | All functionality is available without special access (no login) |
| Target audience | **13–15, 16–17, 18 and over**. Not under 13 |
| Appeals to children? | No (cozy cartoon look, but not designed for children; no under-13 age groups selected) |
| Content rating (IARC) | Category: Game. Cartoon violence: mild (pods pop cartoon critters, no blood). No sex, language, drugs, gambling. No user interaction/chat, no sharing of location, no digital purchases. Ads: yes |
| News app | No |
| Government app | No |
| Financial features | None |
| Health | None |
| Data safety | See below |
| Advertising ID | **Yes**, the app uses the advertising ID. Purposes: Advertising or marketing, Analytics, Fraud prevention/security |

## Data safety form

**Does your app collect or share any of the required user data types?** Yes

**Is all of the user data collected by your app encrypted in transit?** Yes

**Do you provide a way for users to request that their data is deleted?** Yes, users can request it via the contact link in the privacy policy (the data is not tied to an account, so in practice: uninstall, reset advertising ID, or turn off Play stats)

### Data types

| Data type | Collected | Shared | Processed ephemerally | Required or optional | Purposes |
|---|---|---|---|---|---|
| Location > Approximate location (from IP) | Yes | Yes (Google AdMob) | No | Required | Advertising or marketing, Analytics, Fraud prevention |
| App activity > App interactions (levels played, ad views) | Yes | No | No | Optional (Play stats switch) | Analytics |
| App info and performance > Crash logs | Yes | No | No | Optional (Crash reports switch) | App functionality, Analytics |
| App info and performance > Diagnostics | Yes | No | No | Optional | App functionality, Analytics |
| Device or other IDs (advertising ID, app instance ID) | Yes | Yes (Google AdMob) | No | Required | Advertising or marketing, Analytics, Fraud prevention |

Notes:
- "Shared" means sent to a third party for its own purposes. Google AdMob counts as sharing; Firebase Analytics acts as a service provider for us, so its data is "collected", not "shared". The same goes for Firebase Crashlytics (crash logs, since v0.5.1).
- No personal info (name, email, phone), no financial info, no messages, photos, files, contacts, calendar or precise location.

## Monetisation setup

- AdMob app: `ca-app-pub-6111568882988372~4882656897` (Boomlets, Android).
- Ad units: Rewarded "Boomlets Rewarded Extra Life" `ca-app-pub-6111568882988372/7230598573`; Interstitial "Boomlets Interstitial Between Levels" `ca-app-pub-6111568882988372/4604435236`.
- After the store listing is live: in AdMob, **Apps > Boomlets > App settings > Link to an app store**, and set up `app-ads.txt` (needs the developer website in the Play listing; see below).
- AdMob **Privacy & messaging > GDPR**: create a European regulations message for Boomlets, using the privacy policy URL above. Without it, the consent form cannot show and ads in the EEA/UK stay limited.

## app-ads.txt

Line: `google.com, pub-6111568882988372, DIRECT, f08c47fec0942fa0` (also in `docs/app-ads.txt`).

AdMob reads it from the root of the developer website's domain, for example `https://manpreetgugga.github.io/app-ads.txt`. That root is served by a repository named `manpreetgugga.github.io`; the `boomlets` repository's Pages site only covers `/boomlets/`. Set the Play listing's website to `https://manpreetgugga.github.io` and put the file in that repository.
