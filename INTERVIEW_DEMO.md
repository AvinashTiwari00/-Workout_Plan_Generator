Current onboarding: see `ONBOARDING_REVIEW.md`. Signup now collects credentials; fitness preferences are entered in profile setup.

﻿# Interview demo changes

Implemented without adding dependencies or changing the SQLite schema/version.
Existing uncommitted work was present before this review and was preserved.

Changed behavior/files:
- `lib/screens/workoutDetail_screen.dart`: start/complete states, authenticated repository save, synchronous duplicate-tap guard, retry on failure, disabled empty workouts.
- `lib/providers/user_provider.dart`, `lib/screens/dashboard_screen.dart`: reload stored dashboard statistics after categories return; history and weight tracker entry points.
- `lib/screens/Dashboard/workout_history_screen.dart`: load authenticated user's persisted history with loading/error/empty states.
- `lib/services/workout_plan_service.dart`, `lib/repositories/dashboard_user_builder.dart`, `lib/screens/workout_categories_screen.dart`: shared profile-aware generation; days clamped to 1–7, experience adjusts sets, equipment-free home/outdoor/unknown-location fallback.
- `lib/screens/Dashboard/weight_tracker_screen.dart`, `lib/repositories/weight_repository.dart`: persisted weight list and latest weight, finite positive values up to 500 kg, dashboard refresh.
- `lib/screens/login_screen.dart`, `lib/screens/signup_screen.dart`, `lib/screens/user_input_screen.dart`: guarded submissions and exception feedback; signup numeric validation and days-per-week selector; login scrolls above the keyboard.
- `lib/widgets/exercise_tile.dart`, detail, dashboard, and welcome: built-in exercise icons and remote-image error fallbacks. Categories already had a remote fallback.
- `test/workout_flow_test.dart`: generation matrix, repository account isolation/order, weekly dashboard updates, weights and duplicate completion taps.
- `test/schema_migration_test.dart`: isolated temporary database instead of using the default database path.
- `test/widget_test.dart`: replace obsolete counter test with empty-workout guard test.
- `lib/main.dart`: formatting only during dart format; pre-existing routing changes retained.

Validation executed:
- Dart format completed successfully using the installed Dart SDK.
- `flutter test --no-pub`: all 5 tests passed.
- `flutter analyze --no-pub`: no errors or warnings; 27 informational lints (mostly existing withOpacity deprecations, filename/style). Exit code 1 due to infos.
- `flutter build apk --debug --no-pub`: succeeded; APK at `build/app/outputs/flutter-apk/app-debug.apk`.

Limitations:
- Completion is self-reported, without a timer or per-exercise tracking. Leaving before completion discards the in-memory session.
- Duplicate protection applies to one open workout session. Deliberately starting another session records another completion.
- Plans remain deterministic templates. Gym schedules truncate/repeat to requested length; home sessions reuse a small equipment-free routine. Weekly progress still displays active days out of seven, rather than a personalized rest-day calendar.
- Incomplete existing accounts resume profile setup, which now includes experience, workout location and days per week. Existing values are prefilled.
- Guest workouts cannot persist logs; use an authenticated account for the demo.
- Signup creates the account and initial profile transactionally. Profile completion and initial weight are saved in a separate atomic transaction; unchanged latest weights are not duplicated. If interrupted, resume through the saved session or Login.
- No connected Android device was available for an on-device smoke test.

Manual Android demonstration (preserve app data; do not uninstall or clear storage):
1. Connect a phone with USB debugging, or start an Android emulator. Run `flutter devices`, then `flutter run -d <android-device-id>`.
2. Log in to an existing account. Check wrong-password feedback and duplicate-username signup feedback.
3. For a test account, sign up, then choose Home, Beginner, and 3 days in profile setup. Confirm three categories, no equipment exercises, and two sets. Compare a Gym/Advanced account (four sets).
4. Open a workout, tap Start, then Complete rapidly twice. Return through categories to dashboard. Completed count should increase once; this week's count and today's activity should update.
5. Open Workout History and confirm one new entry. Reopen the app, log in, and confirm persistence.
6. Open Weight Tracker. Save a decimal weight; check newest-first history and the dashboard weight after Back. Try blank, negative, and nonnumeric input.
7. Switch accounts and confirm workout/weight data isolation. Test airplane mode: screens should remain usable with image fallbacks.
8. Open a workout and leave before Complete; confirm no completion is saved. Check the login screen with the Android keyboard open.

