# Repository Guidelines

## Project Structure & Modules
- `ComfyNotch/`: Swift app sources (App, Core, Coordinators, Views, Widgets, Extensions, Assets).
- `ComfyNotchTests/` and `ComfyNotchUITests/`: XCTest unit and UI tests (`*Tests.swift`, `*UITests.swift`).
- `ComfyNotch.xcodeproj/`: Xcode project.
- `web/`: Vite + React site (Tailwind, ESLint).
- `cli/`: ComfyX CLI (CMake-based) for local build/packaging workflows.
- `Scripts/`: helper shell scripts (build, archive, DMG, appcast).

## Build, Test, and Development
Swift app (Xcode):
```bash
open ComfyNotch.xcodeproj               # develop in Xcode
xcodebuild -project ComfyNotch.xcodeproj \
  -scheme ComfyNotch -configuration Debug build
xcodebuild -project ComfyNotch.xcodeproj \
  -scheme ComfyNotch -destination 'platform=macOS' test
```
Web (inside `web/`):
```bash
npm install
npm run dev     # local server
npm run build   # production build
npm run lint    # ESLint rules
```
CLI (inside `cli/`): see `cli/README.md` and `compile.sh`.
Release helpers: see `Scripts/build.sh`, `build_archive.sh`, `create_dmg.sh`.

## Coding Style & Naming
- Swift: 4‑space indent, `UpperCamelCase` types, `lowerCamelCase` vars/funcs, one type per file. Prefer structs/enums, value semantics, and clear access control. Keep files under the relevant module folder (e.g., new coordinators → `ComfyNotch/Coordinators`).
- Tests: mirror source paths; name tests after the type (`SettingsModelTests.swift`).
- Web: follow ESLint config in `web/eslint.config.js`; React 19 + Vite; Tailwind utility classes.

## Testing Guidelines
- Framework: XCTest for unit and UI tests.
- Naming: `test<Behavior>_<Condition>()` and group with `// MARK:` sections.
- Run: from Xcode or `xcodebuild ... test` (see above). Add unit tests for models/helpers; add UI tests for critical user flows.

## Commit & Pull Requests
- Commits: present‑tense, concise, scoped messages (e.g., "Fix Settings persistence on fresh launch"). Group related changes; avoid mixed concerns.
- PRs: include summary, rationale, screenshots for UI changes, test notes, and linked issues. Ensure `npm run lint` (web) and all Xcode tests pass.

## Security & Configuration
- macOS app may require Developer ID signing for archives; see `Scripts/ExportOptions.plist` and release scripts.
- Do not commit secrets or signing artifacts. Private frameworks are used; verify compatibility with target macOS versions.

