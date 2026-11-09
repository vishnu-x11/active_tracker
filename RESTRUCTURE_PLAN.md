# Active Tracker: implementation plan (v3, approved design)

- **Branch:** `restructure_clean_arch` (from `Optimisation_and_fixes` ee05a77 plus the uncommitted local files).
- **Approved design:** https://claude.ai/artifact/Bwav53hxzjheeEeeT66zYq (20 screens, pastel glass, light and dark).
- **Previous design, kept for comparison:** https://claude.ai/artifact/VzFnMGgH5RHmNX2u5emDE8.
- **Updated 2026-11-06 (design version 67):** ten form and screen changes from the design review,
  listed as R7-R16 in section 1 and carried through sections 2, 7, 10, 11, 12 and 14.
- **Rewritten:** 2026-11-06. It now follows the approved design, the feature-based clean architecture of
  akbar-b2c-app `vis_htl_architecture_changes` (the hotel feature), and a review of how
  tickut-mobile-app uses Riverpod, go_router and profiling.

Contents:
1. Requirements
2. Approved design
3. Calculations
4. References: what we copy and what we avoid
5. Architecture
6. State management and rebuilds
7. Routing
8. Profiling and performance gates
9. Testing
10. Data
11. Feature specs
12. Phases
13. Removed from the app
14. Open questions

## 1. Requirements

| # | Requirement | Where it lands |
|---|---|---|
| R1 | Track daily data by scrolling dates (canteen-app style) | Activity tab date strip (screen 3). Home always shows today (changed in design review). |
| R2 | After first login ask weight and height, use them for burn estimates | Onboarding (1), Profile (5) |
| R3 | Log gym sessions, runs, water and protein, with custom amounts everywhere | Log picker (4), Gym (6), Run (8, 10), Hydration (14), Protein (16) |
| R4 | Daily totals: calories burned (gym + run), protein, water | Home "Burned today" card with glow bars (2) |
| R5 | Gym: total time plus muscle groups, giving estimated kcal | Gym log (6), Gym detail (7) |
| R6 | Run: distance, pace, time and calories, Strava style | Run log (8), Run detail (9), GPS recording (10, 11) |
| v2 | Weekly report, goals, streaks; GPS runs and records; reminders | Screens 11-13, 17-20 |

**Changes requested 2026-11-06 (design versions 63-67):**

| # | Requirement | Where it lands |
|---|---|---|
| R7 | Onboarding: weight and height are typed by hand like age (side by side, kg and cm), with no −/+ steppers | Onboarding (1) |
| R8 | Gym log: remove the last two fields (calorie override and note); the estimate is what is saved | Gym log (6) |
| R9 | Run log: a run recorded with GPS fills the run form from the phone's GPS (distance, time, pace, date, start), Strava / Nike Run Club style; otherwise everything is entered manually | Run log (8), GPS recording (10) |
| R10 | Water log: no time and no note field; a drink is stamped with the current time | Hydration add view (14) |
| R11 | Hydration history: only the last 7 days, one card per day (amount, day type, water / burn / protein rings), with no drink times | Hydration history (15) |
| R12 | Progress calendar: a round red "!" badge on each past day that missed any daily goal (burn, water or protein) | Progress (13) |
| R13 | Reminders: no quiet hours | Reminders (20) |
| R14 | Goals: the target can be typed; the steppers move 1 km for run distance (was 5) and 50 kcal for burn (was 250) | Goals (18) |
| R15 | Run log: no note ("How did it feel?") field | Run log (8) |
| R16 | Progress calendar: tapping a day opens a small dialog with that day's three daily goals (value / target, met or missed); no OK button, it closes with ✕ or a tap outside | Progress (13) |
| R17 | Sign in with a phone number and a 6-digit OTP code, alongside email + password and Google | Auth (P1) |

## 2. Approved design

### 2.1 Design system (lives in `lib/core/theme` and `lib/core/widgets`)

- **Glass.** Every card, control, tab bar and sheet is frosted glass over a soft coloured backdrop: four blurred
  "orbs" behind each screen's main content.
  - **Cards:** blur 28, white gradient (light 78% to 46%; dark 14% to 5%), a fine bright edge, a 1 px
    top highlight and a soft depth shadow.
  - **Controls:** blur 22, slightly brighter than cards.
  - **Tab bar, sheets and panels over maps:** blur 34.
- **Colours: pastel at full glow strength** (approved after comparing neon at 100%, 50% and 10% glow, and
  dimmed pastel).

  | Metric | Gradient |
  |---|---|
  | Burn, gym, primary buttons | `#F4BE95` to `#DB8065` (buttons `#F0AA82` to `#DB8065`) |
  | Water | `#A3CDEA` to `#7096D6` |
  | Protein | `#AEDFC7` to `#64AE8E` |
  | Run | `#C9B8EC` to `#9381CF` |
  | Alert | `#CC6670` |

- **Type:** Inter 400-700 with tabular figures.
  - Hero 52/700 (-2.4); screen title 30/700; section 17/700; card title 16/600; eyebrow 12/600 uppercase.
  - Never weight 800.
- **Theme:** light and dark, following the phone by default, with an override in Profile > Appearance.
- **Components:**
  - `Glass` (card, control, bar) and `PageBackdrop`;
  - `GradientButton`, the primary action, with a glow;
  - `GlassIconButton` (44 px round) and `IconTile` (gradient tile with glow);
  - the floating 5-slot tab bar with the + in the middle;
  - glow bars with a target line;
  - segmented control, date strip, stat tile, list row, map panel.

### 2.2 Screens and owning features

| # | Screen | Route | Feature | Key elements in the approved design |
|---|---|---|---|---|
| 1 | Onboarding: body stats | `/onboarding` | `profile` | Step 2 of 3; weight (kg) and height (cm) typed by hand in side-by-side fields like age, no steppers (valid 30-250 kg, 120-230 cm); age optional, sex select; live BMI, protein, water and gym-hour kcal; error rings |
| 2 | Home (tab) | `/home` | `home` | Greeting; "Burned today" 1,117 kcal with **glow bars** for burn, water and protein (bars span 0-150% of the target, with a target line, "Target hit · +86%" or "44% to go"); quick log Gym, Run, Water, Protein; today's workouts; "This week" bars with +12%. **No date strip.** |
| 3 | Activity (tab) | `/activity` | `activity` | Month **date strip** (pick a day, tap again or "All days" for everything, "Today"); All / Gym / Runs filter; three stat tiles (the day or the week); list grouped by day with map thumbnails for runs |
| 4 | Log picker | `/log` (sheet) | `app` | Gym, Run, Record run with GPS, Water, Protein; "Logs are saved for today; change the date in each form" |
| 5 | Profile (tab) | `/profile` | `profile` | Identity, body tiles, daily targets with the +500 ml workout-day switch, Appearance System / Light / Dark, Reminders, Goals, Units, Log out |
| 6 | Log gym session | `/gym/new`, `/gym/:id/edit` | `gym` | Live kcal hero; date and start; time card (−/+ 15 min, typed h:m, 45m / 1h / 1.5h / 2h); 3×3 muscle tiles; custom group; intensity; exercises row; pinned save "Save session · 712 kcal". **No calorie override and no note.** |
| 7 | Gym session detail | `/gym/:id` | `gym` | Hero kcal; 3×2 stats (duration, intensity, groups, MET, kcal/h, started); muscle split; "How this was estimated"; share of the week's burn; ⋯ Edit / Delete |
| 8 | Log run | `/run/new`, `/run/new?recording=:id`, `/run/:id/edit` | `running` | Switch **GPS recording / Enter manually** at the top. **GPS:** route map, then distance, time and pace locked ("Auto-filled"), date, start–end and elevation from the recording, "Record again"; title "Save GPS run". **Manual:** a "Record with GPS" shortcut, then distance, time and pace where any two give the third (with avg speed), date and start. Both: title; type Outdoor / Treadmill / Trail / Other; effort 1-5; editable kcal; live preview (**no note**); "Save run · 405 kcal" |
| 9 | Run detail | `/run/:id` | `running` | Full-width map on top (GPS runs) with floating glass buttons; distance hero; 3×2 stats (duration, avg pace, calories, elevation, best km, avg speed); pace chart; splits; records link; ⋯ Edit / Share / Delete |
| 10 | GPS run recording | `/run/record` | `running` | Map; status pill Ready / Recording / Paused; timer; three rings (distance, current pace, kcal); lap and avg strip; **Start, then Pause + Finish, then Resume + Finish** (no swipe). **Finish opens the run log (8) filled from the recording.** |
| 11 | Recorded run + new records | `/run/:id?justRecorded=1` | `running` | As 9, plus the "2 new personal records" card; shown after saving a GPS run from 8 |
| 12 | Personal records | `/records` | `running` | Hexagon badges for 1K, 5K, 10K, 21K; totals; how records are found |
| 13 | Progress (tab) | `/progress` | `progress` | Week / Month / Year; streak card; run tiles; activity calendar (runs violet, gym-only orange, today ring, **round red "!" badge on past days that missed a daily goal**, legend "Goal missed", and a line under the calendar such as "2 days in November missed a daily goal. Most often: protein"; **tapping a past day or today opens a small glass dialog**: date, day type (Rest / Gym / Run / Run and gym), "2 of 3 goals met" chip, and one row per goal (burn, water, protein) with value / target, a thin bar and a green tick, red "!" or, for today, a grey clock; no OK button, it closes with ✕ or a tap outside; future days do nothing); achievements (5K Club, 200 km, Consistent, First 10K, Early Bird) |
| 14 | Hydration | `/water` | `hydration` | Glass tank filling to the target, then a full-blue "hydrated" state; ?, +, history buttons. **Add view:** drink cards plus an always-visible amount with −/+ 50 and ml/L; validation 1 ml-5 L. **No time and no note:** the entry is stamped with the current time |
| 15 | Hydration history | `/water/history` | `hydration` | **Last 7 days only** ("Last 7 days · 17.8 L"); one card per day: date, total ml, Rest / Workout / Hard day label, water, burn and protein rings; newest or oldest first. **No drink times, no expandable entries.** Older days still count in streaks and reports |
| 16 | Protein | `/protein` | `protein` | Hero grams and "to go"; target tube; quick add +10 to +40; Your foods; Logged today; custom entry (food, grams, time, save to my foods), validation 0.1-200 g |
| 17 | Weekly report | `/progress/week` | `progress` | Week switcher; 2,765 kcal +12%; day bars with the best day; tiles for gym, running, protein-target days and water-target days; muscles trained; best day; share card |
| 18 | Goals | `/progress/goals` | `progress` | Week / Month; ring cards (run goals violet); new goal: type, **typed target** with −/+ (1 session, **1 km**, **50 kcal**, 1 day per step; run distance takes one decimal; the stepper snaps to the next multiple), period; error "Enter a target above 0." |
| 19 | Streaks | `/progress/streaks` | `progress` | Streak hero; tiles; heat calendar (<500, 500-900, 900+ kcal, freeze day, today); freeze explanation |
| 20 | Reminders | `/reminders` | `reminders` | Five nudges with switches and times; workout days; validation. **No quiet hours.** |

The tab bar holds Home, Activity, (+), Progress and Profile. The detail and log screens have no tab bar.
**Sign-in screens are not in the 20-screen design yet.** They reuse the glass system:
- `/login`: email and password, "Forgot password?", **Continue with Google**, **Continue with phone**, link to sign up;
- `/login/signup`: name, email, password; afterwards the user is signed out and lands on login with
  "Account created. Sign in to continue." (kept from the old app);
- `/login/phone`: country code (+91 default) and number;
- `/login/phone/code`: 6 digit boxes with auto-fill from the SMS on Android, "Resend code in 0:30", "Change number";
- `/login/reset`: email, then "Check your inbox".

All sign-in routes nest under `/login`, so Back always returns to the sign-in screen. Onboarding is
two screens: `/onboarding` (step 2 of 3, body stats) and `/onboarding/target` (step 3 of 3, daily burn
target, 600 pre-filled, −/+ 50). Both offer Sign out.

**Health Connect / Apple Health is dropped** (decided 2026-11-06): no Health data screen, no heart rate
anywhere. The run screens' heart-rate tile became "Best km", and the bpm chart toggle was removed.

## 3. Calculations

These are pure Dart in `lib/core/formulas/formulas.dart`. **Done:** they are unit-tested in P0.

- **Gym kcal** = MET × kg × hours, rounded down.
  - MET = intensity base (light 3.5, moderate 5.0, hard 6.0) × the average muscle-group factor.
  - Factors: legs, back, full body 1.15; chest 1.05; shoulders 1.0; biceps, triceps, core 0.9;
    cardio 1.4; custom groups 1.0.
  - Example: 2 h of shoulders and triceps at moderate intensity and 75 kg gives MET 4.75 and 712 kcal.
- **Run kcal** = 1.04 × kg × km, **rounded down** (5.2 km is 405.6, shown as 405; confirmed 2026-11-06).
  The user can override it.
- **Run maths:**
  - Pace = time / km; speed = km / h. Any two of distance, time and pace give the third.
  - Clock input accepts `h:mm:ss`, `mm:ss` or minutes.
- **Water target** = 35 ml × kg, plus 500 ml on a day with a gym session or run (a Profile switch).
- **Protein target** = 1.6 g × kg (adjustable 1.2-2.2).
- **Burn target:** the user sets it. Onboarding shows 600 kcal as an editable suggestion, and Profile > Daily targets edits it at any time; Home's burn bar and target line follow it. There is **no upper or lower range**: any whole number above 0 is accepted. BMI is kg / m².
- **Weight stored per session:** every session stores the weight it was logged with, so a later change
  never rewrites past burns.

## 4. References: what we copy and what we avoid

### 4.1 Akbar `vis_htl_architecture_changes`, hotel feature (layer shape)

| Akbar pattern (with source) | Decision |
|---|---|
| Feature folders `domain/{entities,repositories,usecases}`, `data/{models,data_source,repositories}`, `presentation/{controllers,screens,widgets}` | **Copy the shape**, with consistent names: `use_cases/`, `data_sources/`, `notifiers/`, `states/` (Akbar mixes `usecases` / `use_cases` and has no `states/`) |
| `sealed Result<T>` with `Ok` / `Err` (`core/result.dart`) and a `sealed Failure` hierarchy (`core/failure.dart`) | **Copy.** **Done** in `lib/core/result.dart`; failures are adjusted to local storage plus sync |
| `try` / `catch` only in `RepositoryImpl`, mapping to a `Failure` via `_toFailure` | **Copy.** In our app the data sources are SQLite and Firestore; the repository maps `DatabaseException` to `StorageFailure` and Firebase errors to `SyncFailure` |
| Use cases take the repository contract by constructor and return `Future<Result<Entity>>`; rules such as retry live there; flags come in as parameters | **Copy.** One use case per action, exposed as `call()` |
| DTO ↔ entity mapping as `toEntity()` / `toRow()` extensions in `data/models/mappers/`; DTOs never leave `data/` | **Copy** (DTO = SQLite row / Firestore map) |
| Immutable `const` entities, but mostly without `==` | **Copy and fix:** every entity and state gets value equality (hand-written `==` or records), so `select` can skip rebuilds |
| Navigation and legacy coupling behind injected `*Exits` / `*Host` interfaces | **Adapt:** notifiers never navigate. Widgets navigate with typed route helpers from `ref.listen` side effects |
| `HotelBinding` registering data source → repository → use case → controllers (`permanent: true`) | **Replace with providers:** `presentation/providers.dart` per feature (6.1) |
| Stale-response guard with a `_requestId` counter | **Copy** as an `if (!ref.mounted) return;` check and a request id in notifiers that load by key |
| Tests mirror `lib/`; hand-written fakes that implement the contracts and answer from a queue; no mocking library; controllers tested with real use cases over fake repositories | **Copy.** Notifiers are tested with a `ProviderContainer` that overrides the repository providers |

### 4.2 Tickut (Riverpod 3.2.1, go_router 17, the same stack)

| Tickut pattern (with source) | Decision |
|---|---|
| `modules/<x>/presentation/manager/{providers,notifiers,states}`; use cases exposed as `Provider` (`hotelDetailsUseCaseProvider`, `hotel_details_provider.dart:16`) | **Copy** the provider-per-use-case idea. **But** Tickut builds the data source and repository inside the provider (`HotelDetailsRepositoryImpl(HotelDetailsDataSourceImpl())`), so tests cannot replace one layer. **We** give each layer its own provider |
| `Notifier` + state + `copyWith`; `ref.watch(p.select(...))` (191 uses); scoped `Consumer` (244) | **Copy** and make `select` the rule |
| About 500 `ref.watch` calls without `select`, e.g. `ref.watch(roomDataProvider).inProgress` (`hotel_city_selection_screen.dart:167`) | **Avoid.** Watching the whole state rebuilds on every field change |
| `ref.watch` inside a notifier method (`hotel_details_notifier.dart:114`) | **Avoid.** Use `ref.watch` only in `build()`; methods use `ref.read` |
| Legacy `StateProvider` (`flutter_riverpod/legacy.dart`, 207 uses, e.g. `isContentLoading`, `roomAndRAtesError`) | **Avoid.** Use small `Notifier`s, or put the field in the screen state |
| Mutable state fields (`bool isLoading; bool inProgress;` in `hotel_details_state.dart:19-23`) and `GoogleMapController` / `Set<Marker>` inside state (lines 16, 33) | **Avoid.** States are immutable with `==`; platform controllers live in the widget's `State` |
| Use cases return nullable values (`Future<HotelDetailsContentEntity?>`); errors surface as `null` | **Avoid.** Return `Result` (Akbar style) |
| Only ~12 `autoDispose` of ~540 providers | **Avoid.** Screen state is `autoDispose`; caches use `keepAlive` on purpose |
| One `GoRouter` with all paths as `AppRoutes` string constants (`routes.dart:55-119`) | **Partly copy.** Path constants stay, but **each feature owns its routes** (`<feature>_routes.dart`), assembled in `app/router.dart` |
| Tabs in a plain `ShellRoute` (`routes.dart:135`): a tab loses its state on switch | **Avoid.** Use `StatefulShellRoute.indexedStack` (**done** in P0) |
| `state.extra as Map<String, dynamic>` to pass arguments (17 places, e.g. `routes.dart:338-340`) | **Avoid.** Pass ids in the path (`/run/:id`) and load by id; deep links and restoration keep working |
| A `redirect` that only handles maintenance mode; no auth guard | **Improve:** redirect on auth and onboarding state, with `refreshListenable` driven by the auth provider |
| `ProviderScope` without observers (`main.dart:47`); no perf tests; no rebuild tracking | **Improve:** add `RebuildLogger` and the integration perf gate (**done** in P0) |
| Strict analyzer errors (`always_declare_return_types`, `avoid_positional_boolean_parameters`...) | **Copy** the strictness; ours also makes missing `const` an error (**done**) |
| Widget tests: `ProviderScope(overrides: [...])` with mocktail (`test/hotel/hotel_search_test.dart`) | **Copy the overrides**, using hand-written fakes instead of mocktail (Akbar style) |

## 5. Architecture

### 5.1 Layout

```
lib/
  main.dart                     Firebase init, open AppDatabase, ProviderScope(observers, overrides)  [done]
  main_legacy.dart              old GetX entry, unused, deleted in P6                                  [done]
  app/
    app.dart                    MaterialApp.router, light/dark themes, themeMode                     [done]
    router.dart                 assembles feature routes, StatefulShellRoute, auth redirect          [shell done]
    shell.dart                  floating glass tab bar + centre "+"                                  [done]
    log_sheet.dart              screen 4
  core/
    result.dart                 Result, Ok, Err, Failure hierarchy                                   [done]
    formulas/formulas.dart      section 3                                                            [done]
    storage/app_database.dart   schema (section 10)                                                  [done]
    providers/core_providers.dart  appDatabase, firebaseAuth, authState, themeMode, selectedDay, dayKey  [done]
    diagnostics/rebuild_logger.dart                                                                  [done]
    firebase/firebase_options.dart                                                                   [done]
    theme/app_palette.dart, app_theme.dart   section 2.1                                             [done]
    widgets/glass.dart, buttons.dart   Glass, PageBackdrop, GradientButton, GlassIconButton, IconTile [done]
    widgets/...                 DateStrip, GlowBar, SegmentedControl, StatTile, ListRow, MapPanel (with their first feature)
    sync/                       SyncQueue, SyncEngine, FirestoreGateway (P6)
  features/
    auth/          splash, login, signup, Google, phone OTP, reset, logout
    profile/       body stats, targets, appearance, onboarding
    home/          today dashboard (reads other features through their domain)
    activity/      day list across gym + runs, date strip
    gym/           gym sessions
    running/       manual runs, GPS recording, run points, personal records
    hydration/     water entries, drink presets, history
    protein/       protein entries, my foods
    progress/      day/week/month aggregates, streaks, goals, achievements, weekly report
    reminders/     local notifications
```

**Cross-feature aggregates.** Day totals, week reports and streaks need gym, run, water and protein
together. They live in `progress/domain` as use cases (`GetDayTotals`, `GetWeekReport`, `GetStreak`).
They read through `progress/data`, which runs aggregate SQL across the tables. Home and Activity read
those use cases through their providers. **No feature imports another feature's `data/` or
`presentation/`.**

**Public file per feature (clarified in P2).** Some features are read by others: Home and Activity
read `progress` totals, and `progress` reads the user's targets from `profile`. Such a feature has one
file at its root that lists what others may use (`progress/progress.dart`, `profile/profile_api.dart`):
read providers, entities and shared widgets. Other features import only that file, never a path
inside `data/` or `presentation/`.

### 5.2 Feature template

```
features/<feature>/
  domain/
    entities/            immutable, const, value equality, no JSON / SQL
    repositories/        abstract <X>Repository -> Future<Result<T>> / Stream<T>
    use_cases/           <Verb><Noun> (e.g. LogWater): constructor(repository), Future<Result<T>> call(...)
  data/
    models/              row / document DTOs: fromRow, toRow, fromDoc, toDoc
    models/mappers/      extension on DTO { toEntity() }, extension on entity { toRow() }
    data_sources/        abstract <X>LocalDataSource + Impl (sqflite); <X>RemoteDataSource + Impl (Firestore). They throw.
    repositories/        <X>RepositoryImpl: the only try/catch; exception -> Failure; enqueues sync
  presentation/
    providers.dart       data source -> repository -> use case providers (plain Provider, keepAlive)
    notifiers/           <Screen>Notifier (Notifier / AsyncNotifier, autoDispose)
    states/              <Screen>State: immutable, copyWith, ==
    screens/             one file per route; StatelessWidget layout of ConsumerWidget leaves
    widgets/             section widgets
  <feature>_routes.dart  path constants + GoRoute list + typed location helpers
test/features/<feature>/
  data/{models,repositories}   domain/use_cases   presentation/{notifiers,screens}   fakes.dart
```

### 5.3 Layer rules

1. `domain/` imports only `core/result.dart`, `core/formulas/` and its own domain. It never imports
   Flutter, Riverpod, sqflite, Firebase or `data/`.
2. Only data sources throw. Only `RepositoryImpl` catches, and each method ends in a mapping to a
   `Failure`. Nothing above `data/` sees an exception.
3. Use cases hold the business rules: validation (1 ml-5 L water, 0.1-200 g protein, time not in the
   future), kcal estimates and the "any two of three" run maths. They return a `Result`.
4. Notifiers depend only on use-case providers and core providers, never on another feature's notifier.
   They handle results with an exhaustive `switch` on `Ok` / `Err`.
5. Widgets never call repositories or use cases directly; they call notifier methods.
6. Navigation happens in widgets (button handlers or `ref.listen`), never in notifiers.
7. Tests mirror `lib/` and use hand-written fakes that implement the contracts.

## 6. State management and rebuilds

### 6.1 Provider wiring per feature (replaces Akbar's binding and Tickut's inline construction)

```dart
// features/hydration/presentation/providers.dart
final waterLocalDataSourceProvider = Provider<WaterLocalDataSource>(
  (ref) => WaterLocalDataSourceImpl(ref.watch(appDatabaseProvider)),
);
final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => WaterRepositoryImpl(ref.watch(waterLocalDataSourceProvider), ref.watch(syncQueueProvider)),
);
final logWaterProvider = Provider((ref) => LogWater(ref.watch(waterRepositoryProvider)));
final hydrationDayProvider = AsyncNotifierProvider.autoDispose
    .family<HydrationDayNotifier, HydrationDay, String>(HydrationDayNotifier.new);
```

Each layer has its own provider, so a test overrides exactly one layer:
`waterRepositoryProvider.overrideWithValue(FakeWaterRepository())`.

### 6.2 Provider layout

| Provider | Type | Lifetime | Notes |
|---|---|---|---|
| `appDatabaseProvider`, `firebaseAuthProvider`, `authStateProvider`, `themeModeProvider`, `selectedDayProvider` | core | app | **done** |
| `profileProvider` | `AsyncNotifier<Profile>` | keepAlive | weight and targets used by every estimate |
| `dayTotalsProvider(dayKey)` | `FutureProvider.family` | autoDispose + 2-minute keepAlive timer | burn (gym, run), water, protein, targets; Home, Activity tiles, history rings |
| `dayActivitiesProvider(dayKey)` | `FutureProvider.family` | autoDispose | workouts for Home and Activity; separate from totals so a water add does not rebuild the list |
| `activeDaysProvider(monthKey)` | `FutureProvider.family` | autoDispose | dots on the Activity date strip and the Progress calendar |
| `weekReportProvider(weekKey)`, `streakProvider`, `goalsProvider`, `achievementsProvider` | Async / family | autoDispose | progress |
| `gymFormProvider`, `runFormProvider`, `waterAddProvider`, `proteinEntryProvider` | `Notifier.autoDispose` | screen | form state; derived values (kcal, pace) as getters on the immutable state |
| `runRecorderProvider` | `Notifier` with a location `StreamSubscription` | while recording | state machine idle / recording / paused / finished; UI ticker throttled to 1 Hz. On Finish it saves a draft run and its points, then goes to `/run/new?recording=<syncId>` |

**After a write:** the use case returns the affected `dayKey`, and the notifier invalidates only
`dayTotalsProvider(key)` and `dayActivitiesProvider(key)`. Only widgets watching that day rebuild.

### 6.3 Rebuild rules

1. **Watch with `select`.** For example `ref.watch(dayTotalsProvider(k).select((t) => t.value?.waterMl))`.
   Each Home glow bar watches one number.
2. **Leaf consumers.** Screens are `StatelessWidget` layouts of `ConsumerWidget` leaves; only route
   arguments are read at page level.
3. **`const` wherever it compiles.** A missing `const` is an analyzer **error** (done).
4. **Immutable values with `==`.** States, entities and view data use `final` fields and value equality.
   Records are used for small tuples.
5. **No computation in `build`.** Derived values come from state getters or computed providers.
6. **Lists:** `ListView.builder` / `SliverList` with `ValueKey(syncId)`; the date strip is a horizontal
   builder with a fixed `itemExtent`.
7. **Paint isolation:** every `Glass` is a `RepaintBoundary` (done). Charts, rings, the map and the run
   timer get their own boundary.
8. **Blur budget:** `BackdropFilter` is the most expensive widget on screen.
   - At most ~12 glass surfaces are visible at once.
   - Long lists use a cheaper `Glass` variant without blur (gradient + edge only) when they scroll fast.
   - Section 8 measures this.
9. **Animations:** `TweenAnimationBuilder` on the leaf (glow-bar fill, tank level, rings).
10. **Text fields:** the `TextEditingController` lives in a `ConsumerStatefulWidget`; changes reach the
    notifier through `onChanged`, debounced 150 ms for calculations; a focused field is never rebuilt
    from state.
11. **Side effects** (snackbars, navigation, haptics) only in `ref.listen`.
12. **`ref.watch` only in `build()`**; notifier methods use `ref.read`.
13. **Heavy work** (best-effort search over GPS points, weekly aggregates over months) runs in
    `Isolate.run`.

## 7. Routing (go_router 17)

- **Tabs:** `StatefulShellRoute.indexedStack` with branches `/home`, `/activity`, `/progress` and
  `/profile`, so each tab keeps its scroll position and state (**done**).
  - The + button pushes `/log` as a sheet.
- **Feature-owned routes.** Each feature exports `<feature>_routes.dart` with:
  - path constants;
  - a `List<RouteBase>`;
  - typed location helpers, e.g. `RunRoutes.detail(id) => '/run/$id'`.

  `app/router.dart` only assembles them. Nobody writes a path string by hand.
- **Arguments through the path and query, never `extra`.** Screens take ids (`/gym/:id`, `/run/:id`,
  `/run/:id?justRecorded=1`, `/run/new?recording=:id`) and load from the repository. Deep links, back stacks and state
  restoration keep working.
- **Redirect:**
  - Signed out goes to `/login` (`/login/phone` and `/login/phone/code` are also open while signed out).
  - Signed in without a profile goes to `/onboarding`.
  - Otherwise auth routes go to `/home`.
  - `refreshListenable` is a `ChangeNotifier` bridged from `authStateProvider` and `profileProvider`.
  - The redirect reads providers with `ref.read` inside the router provider.
- **Detail and log routes** sit outside the shell, so they have no tab bar. Log screens use
  `fullscreenDialog`.
- **Transitions:** default platform transitions; the Log picker is a modal bottom sheet route with the
  glass sheet.
- **Errors:** a glass "Not found" page with a Home button.

## 8. Profiling and performance gates

- **Debug:**
  - `RebuildLogger` (`ProviderObserver`) counts updates per provider (done).
  - DevTools "Track widget rebuilds".
- **Profile builds for timing:** `flutter run --profile` with DevTools Performance (UI and raster
  threads; watch the raster thread because of the blur), CPU profiler and Memory (leaks after leaving a
  screen).
- **Automated gate:** `integration_test/perf_test.dart` with `test_driver/perf_driver.dart` (done for tab
  switching). It fails when the p90 frame build is over 8 ms or more than 1% of frames are janky.
  Scenarios to add:
  - scroll the Activity date strip 30 days (P2);
  - add 10 water entries (P5);
  - type in the run form (P4);
  - scroll the Activity list with 200 entries (P2).
- **Rebuild tests:** wrap each Home glow bar in a build counter, add a water entry, and assert only the
  water bar rebuilt.
- **Targets:**
  - Home first frame under 1.5 s on a mid-range Android device.
  - Changing the day shows cached totals within one frame and fresh totals in under 50 ms.
  - No rebuilds of unrelated widgets.
  - GPS screen at a steady 60 fps.
  - Raster p90 under 12 ms with the glass on.

## 9. Testing

| Layer | What | How |
|---|---|---|
| core | formulas, `Result`, schema constraints, theme tokens | plain unit tests; `sqflite_common_ffi` in-memory DB (done: 13 + 3 tests) |
| data | mappers (row ↔ entity), repositories (exception → `Failure`, sync enqueue) | fake data sources that answer from a queue (Akbar style) |
| domain | use cases: validation, estimates, run maths, streak and freeze rules, best efforts | fake repositories |
| presentation | notifiers: state transitions, stale-response guard, invalidation of the right `dayKey` | `ProviderContainer(overrides: [...])` |
| widgets | screens render each state in light and dark; navigation; the rebuild counts in section 8 | `ProviderScope(overrides)` + plain theme (google_fonts needs the network) (done: shell tests) |
| integration | perf gate, critical flows (onboarding → log → Home totals) | device or emulator |

**Gates for every phase:**
- `flutter analyze`: no issues;
- `flutter test`: all green;
- `flutter build apk --debug`: succeeds.

## 10. Data

### 10.1 Local (done in P0: `core/storage/app_database.dart`)

The new file is `active_tracker_v2.db`, separate from the old app's `active_tracker.db` (schema v9), so
the two never interfere.

**Sync columns on every log table:**
- `sync_id` (UUID, also the Firestore doc id);
- `updated_at` (epoch ms; the newest write wins);
- `deleted` (soft delete so deletes sync);
- `synced` (0 until Firestore has it).

The `day` column is the local `yyyy-MM-dd`, indexed with `deleted`.

| Table | Columns (besides the sync columns) |
|---|---|
| `profile` | id = 'me', weight_kg, height_cm, age?, sex?, burn_target_kcal, protein_g_per_kg, water_ml_per_kg, workout_water_boost, theme_mode |
| `gym_sessions` | day, started_at, title, duration_min (>0), intensity, muscle_groups (JSON), weight_kg, kcal (no override, no note: R8) |
| `runs` | day, started_at, title, run_type, source (manual / gps), draft (1 between Finish and Save on a GPS run; excluded from every total), distance_m, moving_sec, elevation_m?, effort?, weight_kg, kcal, kcal_override? (no note: R15) |
| `run_points` | run_sync_id → runs (cascade), seq, lat, lng, alt?, t |
| `water_entries` | day, at (set to now when added), ml (1-5000) (no note: R10) |
| `protein_entries` | day, at, grams (0-200), food, note |
| `user_presets` | kind (water / food / muscle_group / run_type), label, value, unit, sort |
| `goals` | kind, period (week / month), target, created_at |

**Still to add with their features:**
- `personal_records` (P9);
- `streak_freezes` (P8);
- reminder settings (in the `profile` row or a small table, P10).

### 10.2 Sync (P6)

- Firestore path: `users/{uid}/{collection}/{sync_id}`.
- The repository writes locally first and marks `synced = 0`.
- `SyncEngine` pushes unsynced rows when online:
  - `set` for live rows;
  - `delete` for soft-deleted rows;
  - backoff, with at most 5 tries per row.
- It pulls changes since the last pull time; the newest `updated_at` wins.
- It is triggered by a connectivity change, by app resume and after a write (debounced).

### 10.3 Old data

**Start fresh (decided 2026-11-06).** Nothing is migrated. The new app uses only
`active_tracker_v2.db` and Firestore under the new collections. The old database file and Hive boxes
are deleted from the device on first launch in P6, together with the old code.

## 11. Feature specs (design → domain)

| Feature | Use cases | Key provider / state |
|---|---|---|
| `profile` | `GetProfile`, `SaveBodyStats` (typed weight and height, validates 30-250 kg, 120-230 cm, age 13-100, burn target any whole number above 0), `UpdateTargets` (burn target, protein ratio, water per kg, workout boost), `SetThemeMode` | `profileProvider`; `OnboardingState` (fields, errors, live targets) |
| `home` | none of its own; uses `progress` `GetDayTotals` and `GetWeekSummary` | glow bar leaves select one metric each; workouts list from `dayActivitiesProvider(today)` |
| `activity` | `GetActivities(range, filter)` | `ActivityState` (selected day or all, filter); the date strip writes `selectedDayProvider` |
| `gym` | `LogGymSession`, `UpdateGymSession`, `DeleteGymSession`, `GetGymSession`, `EstimateGymKcal` (formulas), `SaveCustomMuscleGroup` | `GymFormState` (date, start, minutes, groups, intensity, errors); getters `kcal`, `met` |
| `running` | `LogRun`, `UpdateRun`, `DeleteRun`, `GetRun`, `SolveRunMetrics` (any two of three), `RecordRun` (start / pause / resume / finish), `SaveRunDraft` (on Finish: draft run + points), `GetRunDraft`, `ConfirmRunDraft` (Save: draft → 0), `DiscardRunDraft`, `SaveRunPoints`, `FindBestEfforts`, `DetectNewRecords`, `GetRecords` | `RunFormState` with `source` (gps / manual); in gps mode distance, time, pace, date and start are read-only from the draft, and switching to manual discards the draft after a confirm; `RunRecorderState`; `RunDetailState` |
| `hydration` | `LogWater` (1-5000 ml, ml/L, stamped now), `DeleteWater`, `GetWaterDay`, `GetWaterWeek` (7 day totals for history), `GetDrinkPresets` | `WaterAddState` (amount text, unit, preset picked, error); tank level from day totals |
| `protein` | `LogProtein` (0.1-200 g), `DeleteProtein`, `GetProteinDay`, `SaveFood`, `GetFoods` | `ProteinEntryState` |
| `progress` | `GetDayTotals`, `GetActiveDays`, `GetMissedGoalDays(month)` (past days where burn, water or protein ended under target; today and future never count), `GetDayGoals(dayKey)` (value and target for each goal, for the day dialog; built on `GetDayTotals`), `GetWeekReport`, `GetPeriodStats` (week / month / year), `GetStreak` (freeze rule), `GetGoals`, `AddGoal` (target > 0; km to one decimal, others whole), `RemoveGoal`, `GetAchievements` | family providers by key; `missedGoalDaysProvider(monthKey)` |
| `auth` | `SignInWithEmail`, `SignUpWithEmail`, `SendPasswordReset`, `SignInWithGoogle`, `SendPhoneCode` (E.164 number, +91 default; returns a verification id or, on Android auto-retrieval, signs in directly), `VerifyPhoneCode` (6 digits), `ResendPhoneCode` (uses the resend token, after 30 s), `SignOut` (Firebase and Google) | `LoginState`; `PhoneAuthState` (number, verificationId, resendToken, seconds left, error); the verification id stays in this notifier, never in the route |
| `reminders` | `GetReminderSettings`, `SaveReminderSettings` (time validation), `ScheduleReminders` | `RemindersState` |

## 12. Phases

The old GetX app stays compiling, but unused, until P6 deletes it with the `get` dependency, so every
phase builds.

| Phase | Work | Done when |
|---|---|---|
| **P0** | Riverpod 3 + go_router + uuid; strict lints; `Result` / `Failure`; formulas + tests; new database + tests; theme tokens and glass widgets; shell with floating tab bar; `RebuildLogger`; perf harness; new `main.dart` | **Done 2026-11-06.** Analyze clean, 23 tests green. **Debug APK build not yet verified:** Gradle needs network to fetch AGP 8.11.1, which the agent sandbox blocked. Run `flutter build apk --debug` locally. |
| **P1** | `auth` (splash, login, signup, Google, **phone number + OTP** (R17), reset, logout) restyled in glass; `profile` onboarding (typed weight and height, R7; burn target step); auth + onboarding redirect | **Code done 2026-11-06.** Analyze clean, 62 tests green. Removed the unused `tflite_flutter` dependency (its Gradle config broke the Kotlin compile). **Not verified:** the debug APK (the disk filled up during the build) and sign-in against real Firebase on a device (email, Google and phone, one fresh-install run each). |
| **P2** | `progress` day aggregates (`GetDayTotals`, `GetActiveDays`, `GetWeekBurn`, `GetActivities`); **Home** (glow bars, quick log, workouts, this week); **Activity** (date strip, filter, grouped list); perf scenarios | **Code done 2026-11-06.** Analyze clean; tests green per folder (core 16, auth 22, profile 12, progress 8, activity 5, home 2, app 8). Quick-log tiles and the + button open the log picker until P3-P5; workout rows and glow bars are not tappable until their detail screens exist. **Not done:** the perf scenarios (date strip, 200-row list) and a device run; the disk is too full to build. |
| **P3** | `gym` log (no override, no note: R8), detail, edit, delete; Log picker | **Done 2026-11-06.** 712 kcal example verified; Home and Activity update after save and delete. 6 tests. |
| **P4** | `running` manual log (no note: R15; GPS / manual switch), detail, edit, delete | **Done 2026-11-06.** 5.2 km in 29:35 gives 5:41 /km and 405 kcal; editing keeps GPS points. 9 tests. |
| **P5** | `hydration` (tank, add view with custom amount and no time/note, 7-day history) and `protein` (quick add, foods, custom entry) | **Done 2026-11-06.** Undo on every add. 7 tests. |
| **P6** | `profile` screen + appearance + editable targets; Firestore sync engine; delete the old database file and Hive boxes on first launch; **delete old GetX code and the `get` dependency** (and Hive); remove the analyzer excludes | **Done 2026-11-06.** Profile tab; two-way sync (`core/sync`: push unsynced rows, pull newer ones, tombstones, GPS points inside the run document, local data cleared when another account signs in; `firestore.rules` limits each user to `users/{uid}`); old `active_tracker.db` and Hive files removed on launch; old GetX code, 19 unused packages and all analyzer excludes removed (backup: `../active_tracker_legacy_backup_2026-11-06.tgz`). DB v4 adds `app_settings`. `firestore.rules` deployed to active-health-f8654 on 2026-11-06 (this replaced the old rules, so the old app's top-level collections such as `foodLogs` are no longer readable by any app; decided: start fresh). |
| P7 | Test pass across layers; rebuild-count tests; DevTools profiling on a device (blur cost); polish | **Partly done 2026-11-06.** 121 tests green across 12 folders; debug APK builds. Perf scenarios added (tab switch, All / Gym / Runs filter, date strip); list rows draw without live blur. **Not run:** the perf gate needs a device in profile mode. |
| **P8** | `progress` tab (calendar with missed-goal badges and the day goals dialog: R12, R16), weekly report, goals (typed target, 1 km / 50 kcal steps), streaks, achievements | **Done 2026-11-06.** Missed goals start from the first logged day. 17 tests. |
| **P9** | GPS recording (Start / Pause / Resume / Finish), run points, map panel, auto-pause, **Finish → run log filled from GPS** (draft run), best efforts, records, recorded-run screen | **Done 2026-11-06** (geolocator + flutter_map on OpenStreetMap, no API key; DB v3 adds `run_points.segment`). 16 tests. Records while the app is open on screen; **no background tracking or auto-pause** yet. |
| **P10** | `reminders` (five nudges, no quiet hours) | **Done 2026-11-06.** flutter_local_notifications 22 (23 needs Android SDK 37, which this AGP cannot resolve). Today's conditional nudges are dropped once met and the plan is redone on launch, after each log and on settings changes; later days are narrowed when the app next opens. 5 tests. **Not verified on a device.** |

**Device runs are needed at:**
- P1 (sign-in);
- P3 (first real write);
- P6 (sync);
- P7 (performance);
- P9 (outdoor GPS on Android and iOS).

## 12a. Changes after the first device run (2026-11-06)

- **Palette:** neon (burn `#FFB15C`→`#FF4F2E`, water `#5CC8FF`→`#2F6BFF`, protein `#7CF0B8`→`#14B87A`,
  run `#C79BFF`→`#7B4DFF`, CTA `#FF9A5C`→`#FF4F2E`). The design artifact is still pastel.
- **Hydration:** one screen (tank, then drink cards and amount, pinned Add); the separate add view
  is gone. Undo messages leave after 4 s and float above the Add bar.
- **Whole cards are tap targets:** `Glass` lays its content out at the card's size
  (`StackFit.passthrough`); before, content shrank to the top-left corner, so only the icon area
  responded. `TapGlass` is a glass card that is one tap target.
- **Sizes:** quick-log tiles as designed (84 px tall, 24 px radius, 36 px icon tile, 12 px label);
  icons inside tiles and buttons slightly larger; tab icons 24 px.
- **Every device:** text scale limited to 0.85x-1.3x; every main screen is tested at 320 px wide with
  1.3x text (no overflow).
- **Speed:** Inter bundled (no font download); live blur only on bars (tab bar, sheets, save bars,
  map panel); first sync after 2 s, write syncs after 1 s; reminder planning after 8 s with the
  10-year timezone data.
- **New phone, existing account:** the profile is fetched from Firestore before onboarding is shown.
- **GPS screen:** opens on the runner's current position with a blue dot that follows them before
  and during recording.

## 12b. Next features (market research, 2026-11-09)

These seven features are what the leading apps have and Active Tracker lacks. The leading apps are
Strava, Runna, Nike Run Club, Runkeeper and Garmin for running, and Hevy, Strong and Fitbod for the gym.
They are in order of value for the effort. **All seven were built on 2026-11-09** (status below the
table); there was no separate design pass, the screens reuse the glass components.

| Phase | Feature | What it does | How (first idea) | Done when |
|---|---|---|---|---|
| **P11** | **Background GPS + auto-pause** | A run keeps recording with the screen off or another app open. Recording pauses itself when the runner stops (traffic lights) and resumes when they move. | geolocator's Android foreground service (`AndroidSettings.foregroundNotificationConfig`, a "Recording run" notification) and iOS `allowBackgroundLocationUpdates` + `UIBackgroundModes: location`. Auto-pause when speed stays under ~0.5 m/s for 5 s, which opens a new `segment` (already in DB v3). | A 5 km outdoor run with the screen locked matches the distance of the same run with the screen on; stops show as pauses in the splits. |
| **P12** | **Audio cues** | Spoken pace, distance and time each km (and at pause/resume), with no new screens. | `flutter_tts`; a pure `CueSchedule` in `running/domain` decides what to say from `TrackMath` totals. Settings: on/off and every 0.5 / 1 / 2 km. Ducks music. | Cues are heard each km on a device with the screen locked; the schedule has unit tests. |
| **P13** | **Exercise-level gym logging** | Sets × reps × kg per exercise, with the previous session's numbers shown while logging, a rest timer that starts after each set, and a PR alert (heaviest set, best estimated 1RM). | New `exercises` (built-in list + custom) and `gym_sets` tables (DB v5, synced like the other log tables). The session keeps muscle groups and kcal; muscle groups come from the exercises. Estimated 1RM by Epley (`kg × (1 + reps / 30)`). | A session with 3 exercises logs, syncs to a second phone and shows "Last time: 60 kg × 8"; a heavier set shows a PR badge. |
| **P14** | **Interval / target-pace runs** | Structured runs (warm-up, n × work/rest, cool-down) or a target pace, with spoken "faster / slower" and step changes. | Builds on P12. A `RunWorkout` entity (steps by distance or time) stored as a preset; the recorder reports the current step. | A 4 × 400 m session on a device announces each step change and the pace against the target. |
| **P15** | **Muscle recovery heat map** | A body map that colours each muscle group by recovery (0-100 %), on the Gym side of Activity or Progress. | Computed from data already logged: each session's muscle groups, intensity and time, with recovery over ~48-72 h. Later it uses P13 set volume. A pure function in `gym/domain`. | The map matches a hand-worked example (legs trained hard yesterday ≈ 40 %); it has unit tests. |
| **P16** | **Shareable cards** | A share image for a run (map, distance, pace, time) or a gym session (exercises, volume), in the neon style. | Render a card widget off-screen with `RepaintBoundary.toImage`, share with `share_plus`. | Sharing to WhatsApp / Instagram from a device shows the card. |
| **P17** | **Routines / templates** | Save a gym session as a routine ("Push day") and start a new session from it, prefilled with the last weights. | A `routines` table (exercise list + target sets) synced like presets; needs P13. | Starting "Push day" prefills every exercise with last session's numbers. |

**Status 2026-11-09:** code done for P11-P17; analyze clean; 159 tests green (core 23, app 22,
features 114). DB version 5: `gym_sessions.exercises` (JSON) and a synced `routines` table. New
packages: `flutter_tts` (voice) and `share_plus` (share cards).
- **P11:** recording switches to a background location stream on Start (Android foreground service
  with a "Recording your run" notification; iOS background location + blue indicator; manifest and
  Info.plist updated). Auto-pause after 8 s without 5 m of movement; the paused seconds are taken
  off the clock; moving again resumes in a new segment. A run settings sheet (tune icon) turns it off.
- **P12:** voice coach with splits every 0.5 / 1 / 2 km or off, plus start, pause, auto-pause,
  resume and finish. Settings are kept in `app_settings` (`run.settings`).
- **P13:** optional Exercises section in the gym log: built-in list of 32 exercises plus custom
  ones, sets × kg × reps, "Last time" line, sets prefilled from the last session, rest timer
  (90 s, ±15 s, skip) after each completed set, PR badge and message (Epley 1RM), volume. The
  quick log (time + muscle groups) still works without exercises. The detail screen lists the sets.
- **P14:** workouts in the run settings sheet: free, target pace (spoken "speed up" / "ease off" at
  most once a minute, ±10 s slack) or intervals (warm-up, repeats × metres, rest seconds,
  cool-down). Auto-pause is off during intervals so rests keep counting.
- **P15:** muscle recovery screen (`/gym/recovery`), reached from the Progress header and from every gym
  session. It is calculated from the last 72 h of sessions; set volume is not used yet.
- **P16:** share cards (route drawn from GPS points, or the session's exercises) from the run and
  gym detail screens, rendered to PNG and shared through the system sheet.
- **P17:** "Save as routine" in the gym log; routine chips start a new session prefilled with
  the last weights; long-press a chip to delete it.

**Not verified (needs a device):** the debug APK (the agent sandbox could not download sqlite3's
prebuilt Android library, so run `flutter build apk --debug` locally), background recording with
the screen locked, spoken cues and music ducking, the share sheet, and iOS. On Android 14+ the
foreground-service notification needs notification permission, which the reminders already request.

**Decided by default (2026-11-09; change if needed):** a permanent notification while recording
(foreground service only, no `ACCESS_BACKGROUND_LOCATION`); the quick gym log stays alongside
exercises; a built-in exercise list ships with the app. Health Connect / Apple Health stays dropped.

**Not planned:** social feed / segments / leaderboards, route builder, live location sharing,
training plans, watch apps and an AI coach. The market has them, but each is large and needs a
backend or other devices.

## 13. Removed from the app

- Nutrition logging (calories, carbs, fat), training exercises, the BMI screen, the daily log (mood,
  notes, calendar), analytics, premium and pricing, and the mock screens.
- Health Connect / Apple Health: the screen, the integration and heart rate (decided 2026-11-06).

Their code goes in P6 and stays in git history.

Removed 2026-11-09: the `web/` platform folder (the app is Android and iOS only; sqflite has no web
support) and the unused `cupertino_icons` package.

## 14. Decisions and open questions

**Decided 2026-11-06:**
- **Old data:** start fresh; there is no migration (section 10.3).
- **Burn target:** the user sets it. 600 kcal is only the suggestion shown in onboarding; it can be
  edited in Profile at any time.
- **Run calories:** round down (405 for 405.6).

- **Health Connect / Apple Health:** dropped completely, including heart rate.
- **Burn target range:** no limit, only a positive whole number.
- **Sign-in methods (R17):** email + password (with reset by email), Google, and phone number with a
  6-digit OTP. Firebase setup for phone: enable the Phone provider; add the Android SHA-1 and SHA-256
  of the debug and release keys (Play Integrity, with reCAPTCHA fallback); upload the APNs key for iOS
  silent push. Firebase test phone numbers are used in development so no SMS is sent. A phone-only
  user has no email, so the profile and sync key on `uid`, never on email.
- **iOS sign-in config is incomplete:** `ios/Runner/GoogleService-Info.plist` has no `CLIENT_ID` /
  `REVERSED_CLIENT_ID` and `Info.plist` has no URL types, so Google sign-in and the phone reCAPTCHA
  fallback will not work on iOS until the plist is downloaded again from Firebase and the reversed
  client id is added as a URL scheme. Android is configured.
- **Profile per account:** the `profile` row is keyed by the Firebase `uid` (schema version 2), so a
  second account on the same device gets its own onboarding. Log tables are not per-account yet;
  this is settled with sync in P6.
- **Sign in with Apple:** not included for now. Needed before an iOS App Store release that offers
  Google sign-in (guideline 4.8).
- **R7-R16 (design versions 63-67):** see section 1. Gym calorie override and note, run note, water
  note and time, quiet hours and drink times in history are gone. Missed goals show as a round badge;
  tapping a day shows its goals in a dialog without an OK button. A GPS run is saved as a draft on Finish and
  confirmed from the run log, so the form takes an id in the path, not `extra`.

Nothing is open. P11-P17 defaults are listed in section 12b.
