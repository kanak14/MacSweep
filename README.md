# MacSweep

MacSweep is a native SwiftUI macOS storage advisor and cleaner built for developers who need to reclaim disk space without blindly deleting files.

It helps you find Xcode clutter, simulator data, package-manager caches, generated project artifacts, old downloads, logs, backups, Trash contents, and other large removable storage so you can review it and clean it up with confidence.

<img width="1036" height="704" alt="Screenshot 2026-08-19 at 4 57 11 PM" src="https://github.com/user-attachments/assets/c79c807e-6f75-4b0d-94e2-e6166c27cf03" />

<img width="1031" height="707" alt="Screenshot 2026-08-19 at 4 57 32 PM" src="https://github.com/user-attachments/assets/a9c372ef-4244-4fa4-8d03-35996358380e" />


## Why MacSweep

Development machines collect a lot of temporary data over time. Derived Data grows, simulators pile up, `node_modules` sprawls, Docker caches expand, and old archives linger long after they are useful.

MacSweep is designed for that reality. Instead of acting like a one-click "clean everything" app, it shows what is taking space, labels the risk, and lets you decide what to remove.

## Key Features

- Native macOS app built with SwiftUI.
- Developer-focused scanning for Xcode, simulators, package managers, and generated project artifacts.
- Storage review for downloads, old files, logs, backups, Trash, and application leftovers.
- Risk labels that help separate regeneratable data from items that should be reviewed carefully.
- Conservative cleanup defaults that prefer moving items to Bin through Finder semantics.
- Immediate per-item cleanup results and local receipts for cleanup history.

## What MacSweep Can Scan

### Developer storage

- Xcode Derived Data, test results, device support, and documentation caches.
- Simulator caches, devices, and runtimes.
- Homebrew, SwiftPM, CocoaPods, npm, Yarn, pnpm, Gradle, Maven, Flutter/Dart, and JetBrains caches.
- Generated project folders such as `node_modules`, `.build`, `.next`, `.dart_tool`, Pods, Carthage builds, and coverage output.
- Docker-reported reclaimable images, build cache, stopped containers, and networks through Docker's native prune command. Volumes are retained.

### General storage

- Large or old files in user-selected scan folders.
- Installer packages, archives, and likely duplicate downloads.
- General application caches, old logs, and diagnostic reports.
- Local iCloud-copy eviction when the item reports that it is safely uploaded.
- iOS device backups, Trash contents, and conservative app-leftover suggestions.

### Review and cleanup workflow

- Risk labels for each cleanup item.
- Target-based selection before cleanup.
- Actual volume-capacity reporting.
- Cleanup results, local receipts, and folder-permission awareness.

## Safety First

MacSweep is intentionally conservative.

- All ordinary filesystem items, including caches and regeneratable developer data, are moved to Bin through Finder semantics.
- Permanent deletion is reserved for items that are already inside Bin and is labeled explicitly.
- Simulator changes use `xcrun simctl` rather than editing CoreSimulator internals.
- Symbolic links and protected system locations are rejected by the cleanup engine.
- Archives, backups, application leftovers, and unknown caches are never preselected.
- Every cleanup shows an immediate per-item result and produces a local receipt.

MacSweep cannot promise that clearing a cache has zero effect. Regeneratable items can still require a rebuild, reindex, or re-download later, and the interface explains that tradeoff before cleanup.

## Who It Is For

MacSweep is especially useful for:

- iOS developers
- macOS developers
- full-stack developers using Xcode plus Node.js, Docker, or multiple package managers
- anyone whose Mac loses large amounts of space to build artifacts and temporary development data

## How To Use

1. Launch MacSweep.
2. Run a scan to discover reclaimable storage.
3. Review the suggested categories and items.
4. Check each item's risk label and cleanup action.
5. Select the items you want to clean.
6. Confirm cleanup.
7. Review the cleanup results and local receipt history.

## Run Locally

Open `Package.swift` in Xcode and run the `MacSweep` executable, or use:

```sh
swift run MacSweep
```


## Project Status

MacSweep is under active development. The current focus is improving scan coverage, refining cleanup safety, and polishing the storage-review experience for macOS developers.

## License

See `LICENSE`.
