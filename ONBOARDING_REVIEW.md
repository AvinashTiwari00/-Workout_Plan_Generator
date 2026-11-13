# Authenticated onboarding review

Current flow:
- Startup runs Splash. A valid stored session opens Dashboard only when the profile is complete; otherwise it resumes fitness profile setup. With no session, Welcome shows Get Started and Login.
- Get Started opens Signup, which collects only username and password. The existing UserRepository transaction creates exactly one account and its initially incomplete profile. Signup writes no weight.
- Successful signup persists the authenticated ID and opens the existing User Input screen. This screen collects age, gender, height, weight, goal, experience, location and days per week. Available stored fields are prefilled.
- Login and Splash use the same completeness check and destination helper.
- Successful authentication clears Welcome/Login/Signup routes. Completing setup clears its route too. Android Back cannot expose old authentication screens.

Data safety:
- SQLite schema/version, password hashing, session key, workout generation and workout logging are unchanged. No dependencies added.
- A profile is complete when valid age/height, gender, goal, experience, workout location and days (1–7), plus a valid saved weight, exist. Older accounts missing these values resume setup without automatic database changes.
- Profile completion updates the existing account/profile and initial weight in one transaction. An unchanged latest weight is not inserted again. Username conflicts return before any changes. Existing workout/weight history is retained.
- Loading failures block submission and offer Retry; unknown stored data is not overwritten with defaults. Existing values are shown; defaults apply only to missing choices.
- Back is blocked while authentication or profile writes are in progress. If interrupted after account creation, the saved session resumes setup; if the session was not yet persisted, Login recovers the same account. Signup failures after account creation disable repeat creation and provide a Login link.
- Guest setup code remains reusable but is no longer reachable from Welcome. The Dashboard now provides confirmed logout; see `DASHBOARD_REVIEW.md`.
- Unsaved form edits are in memory and may be lost if the app is killed. Stored profile fields and history remain intact.

Changed files in this pass:
- `lib/main.dart`: startup route runs Splash.
- `lib/screens/welcome_screen.dart`: only Get Started → Signup and Login remain.
- `lib/screens/signup_screen.dart`: credentials only, shared routing, account-creation guard and Login recovery link.
- `lib/screens/login_screen.dart`: shared routing and Back guard during login.
- `lib/screens/splash_screen.dart`: shared routing, recoverable session-load error, clears stale memory for a missing session/account.
- `lib/screens/user_input_screen.dart`: prefill workout preferences, loading/retry guard, atomic profile completion, clear route stack. Existing usernames containing digits remain valid.
- `lib/utils/authenticated_navigation.dart`: shared session persistence/completeness routing helper.
- `lib/models/user_models.dart`: profile completeness predicate; no stored fields added.
- `lib/repositories/user_repository.dart`: completeness query and transactional completion method using existing tables.
- `lib/providers/user_provider.dart`: clear stale dashboard user when setting an incomplete account session.
- `test/onboarding_navigation_test.dart`: eight tests for signup through setup, login, persisted session, incomplete/interrupted setup, preserving saved values, Back navigation, idempotent weight saves and completeness requirements.
- `INTERVIEW_DEMO.md`: adjust older demo instructions to the new flow.

Validation executed:
- Dart format on all modified Dart files.
- `flutter test --no-pub`: all 15 tests passed (8 new tests plus 7 existing tests).
- `flutter analyze --no-pub`: zero errors/warnings, 26 existing informational lints; exit code 1 because of infos. These are 21 withOpacity deprecations, three missing-brace style infos, one filename info and one unnecessary toList info.
- `flutter build apk --debug --no-pub`: succeeded. Updated APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- No on-device onboarding smoke test was performed in this pass.

Manual Android steps (do not uninstall or clear existing app data):
1. Install/update the debug APK or run `flutter run -d <android-device-id>`. Use a separate test emulator for a new signed-out installation if your current installation already has a saved session.
2. On Welcome verify only Get Started and Login. Get Started opens a credentials-only Signup. Before submitting, Back should still return to Welcome.
3. Sign up with a new username. Expect Profile Setup, with no return path to Signup via Back. Force-stop and relaunch before completing setup; expect the same account's setup, not another signup.
4. Fill profile/body details and choose experience, location, goal and days. Tap Continue twice quickly. Expect Dashboard, one initial weight record, and no return path to Signup/Login/Setup via Back.
5. Relaunch: Splash should open Dashboard directly with the same weight and workout statistics.
6. On a signed-out test installation with an existing complete account, use Login. Expect Dashboard directly. For an older incomplete account, expect prefilled setup; complete only missing data and confirm existing history remains.
7. Try a duplicate username and wrong password. Neither should create or reset data. If account creation succeeded but session persistence was interrupted, use Login with the same credentials.
8. Complete a workout and open history/weekly progress; save a new weight to confirm existing workout functionality remains intact.

