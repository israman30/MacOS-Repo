# NeatOS

**Your friendly macOS file organization bot.** Transform messy desktops and file systems into organized spaces with natural language commands and smart cleanup actions.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Functionalities](#functionalities)
- [Updates](#updates)
- [How to Use](#how-to-use)
- [Technical Architecture](#technical-architecture)
- [Contributing](#contributing)
- [Copyright](#copyright)

---

## Overview

NeatOS is a native macOS application built with SwiftUI that helps you organize, clean, and archive files through a conversational interface. Simply type what you want—"clean my desktop," "find duplicates," "archive old files"—and NeatOS suggests and executes smart cleanup actions with full undo support.

---

## Features

### 🤖 Conversational Interface

- **Natural language commands** — Type requests in plain English
- **Quick action chips** — One-tap access: Desktop, Downloads, Documents, Find Duplicates, Clear Derived Data
- **Interactive chat bubbles** — Action buttons and real-time feedback
- **Keyword-based intent handling** — Recognizes "clean," "organize," "duplicate," "archive," "derived data," "xcode"

### 📁 Smart File Analysis

| Capability | Description |
|------------|-------------|
| **File Classification** | Categorizes by type: Images, Documents, Videos, Audio, Archives, Screenshots, Downloads, Unknown |
| **Duplicate Detection** | SHA256 hashing for exact duplicate files |
| **Similar Files** | Vision-based image similarity; base-name grouping for documents |
| **Age Analysis** | Identifies files older than 90 days for archiving |
| **Size Analysis** | Flags files larger than 500MB for compression |
| **Screenshot Detection** | Special handling for screenshot-named files |

### 🪟 Results Browser (Split View)

- **Master–detail layout** — Browse categorized files on the left, inspect details on the right
- **Sorting controls** — Sort by Size, Extension, or Format (ascending/descending)
- **Quick Look preview** — Rich file preview pane (images, PDFs, documents, etc.)
- **Large files review** — Banner + review sheet for \(≥ 500MB\) files

### 🔐 Sandbox-Friendly Folder Access

- **Permission prompts when needed** — Desktop / Downloads / Documents access via user selection
- **Persistent access** — Security-scoped bookmarks stored for future scans

### 🧹 Intelligent Cleanup Actions

- **Move** — Organize files into category folders
- **Archive** — Old files into `~/Archive/YYYY-MM/`
- **Delete** — Duplicates/similar files to Trash (not permanent)
- **Compress** — Large files to `~/Compressed/`
- **Auto-sort Downloads** — Files in Downloads 24+ hours → Documents/Screenshots/Videos/etc.

### 🔧 Xcode Cleaner

- Clears Xcode Derived Data via user-selected folder
- Uses security-scoped access for sandbox compatibility
- Reports freed disk space
- Accessible via menu (⌘⇧D) or quick chip

### 🔄 Undo & Safety

- **Undo stack** for move, archive, delete, compress
- **Preview and confirmation** before running actions
- **Conflict handling** for duplicate filenames
- **Trash-only deletion** — no permanent file removal

### ♿ Accessibility

- Full VoiceOver labels and hints
- Keyboard shortcuts: ⌘1 (Desktop), ⌘2 (Downloads), ⌘3 (Documents), ⌘⇧D (Derived Data), ⌘⇧Z (Undo)

---

## Functionalities

### Supported Locations

- **Desktop**
- **Downloads**
- **Documents**

### File Categories

| Category | Extensions |
|----------|------------|
| Images | JPG, PNG, GIF, HEIC, WebP, TIFF, BMP |
| Documents | PDF, DOC, DOCX, TXT, RTF, Pages, Key, Numbers, XLS, PPT |
| Videos | MP4, MOV, AVI, MKV, WebM, M4V |
| Audio | MP3, WAV, AAC, FLAC, M4A |
| Archives | ZIP, RAR, 7z, DMG, TAR, GZ |
| Screenshots | Auto-detected by name pattern |
| Downloads | Files from Downloads folder |
| Unknown | Unrecognized types |

### Smart Tidy Rules

- **Always ask before action** — User confirmation required
- **Downloads auto-sort** — 24-hour threshold; extension-to-folder mapping
- **Archive pattern** — `~/Archive/YYYY-MM/`
- **Compress pattern** — `~/Compressed/`

---

## Updates

### Recent Enhancements

- **Xcode Cleaner** — Clear Derived Data to reclaim disk space
- **Smart Tidy** — Downloads auto-sort with configurable rules
- **Vision-based similarity** — Image similarity detection via `VNGenerateImageFeaturePrintRequest`
- **NeatOS menu** — Dedicated menu with keyboard shortcuts
- **Results improvements** — Split-view browser, sorting, and file preview pane
- **Sandboxed scanning** — Security-scoped access + persisted folder bookmarks
- **Unified error handling** — Shared `AppError` enum + SwiftUI `appErrorAlert(...)` helper for consistent user-facing errors
- **Memory Guard** — RAM monitoring module (available for future integration)

### Version Info

- **macOS deployment target:** 15.5+
- **Xcode:** 16.4+
- **Swift:** 5.0+
- **Bundle ID:** `com.israman.somenews.Pepe-Assiant`

---

## How to Use

### Getting Started

1. **Launch the app** — Open NeatOS
2. **Type your request** — Use natural language (e.g., "clean my desktop")
3. **Use quick chips** — Or tap Desktop, Downloads, Documents, Find Duplicates, Clear Derived Data
4. **Review suggested actions** — Preview what will happen
5. **Execute or customize** — Select/deselect actions, then run
6. **Undo if needed** — Use the Undo button or ⌘⇧Z

### Example Commands

```
"Clean my desktop"
"Scan downloads folder"
"Find duplicate files"
"Archive old documents"
"Organize my files"
"Clear derived data"
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘1 | Scan Desktop |
| ⌘2 | Scan Downloads |
| ⌘3 | Scan Documents |
| ⌘⇧D | Clear Derived Data |
| ⌘⇧Z | Undo Last Action |

---

## Technical Architecture

### Project Structure

```
Pepe Assiant/
├── Pepe Assiant.xcodeproj
└── Pepe Assiant/
    ├── Pepe_AssiantApp.swift        # App entry point, NeatOS menu + shortcuts
    ├── ResultsView.swift            # Scan results (split view + preview)
    ├── Pepe_Assiant.entitlements    # Sandbox entitlements
    │
    ├── Views/
    │   ├── BotAssistantView.swift   # Main chat interface
    │   ├── ActionPreviewView.swift  # Action preview sheet
    │   ├── FileSortBar.swift        # Sorting controls
    │   ├── QuickLookPreview.swift   # Quick Look preview pane
    │   └── ContentView.swift
    │
    ├── File Engine/
    │   ├── FileManager.swift            # Models, categories, rules
    │   ├── FileScanner.swift            # Scanning & analysis
    │   ├── FileOperations.swift         # Move, archive, delete, compress
    │   └── FolderAccessController.swift # Security-scoped folder access
    │
    ├── Utilities/
    │   ├── Constants.swift              # Strings, paths, config
    │   ├── AppError.swift               # App-wide error type + normalization
    │   ├── View+AppErrorAlert.swift     # SwiftUI alert convenience
    │   └── AppTheme.swift               # Colors, gradients
    │
    ├── Xcode Cleaner/
    │   └── XcodeCleaner.swift           # Derived Data cleanup
    │
    ├── Memory Guard/
    │   └── MemoryGuard.swift            # RAM monitoring (future)
    │
    ├── Unused Resource Hunter/          # Optional resource analysis tooling
    │
    └── Assets.xcassets                  # App icon, accent color
```

### Technologies

- **SwiftUI** — UI framework
- **AppKit** — NSOpenPanel, NSWorkspace, NSImage
- **CryptoKit** — SHA256 for duplicate detection
- **Vision** — Image similarity
- **QuickLookUI / PDFKit** — File previews in Results
- **Foundation** — FileManager, URL, DateFormatter

### Building

1. Clone the repository
2. Open `Pepe Assiant/Pepe Assiant.xcodeproj` in Xcode
3. Build and run (⌘R)

---

## Contributing

We welcome contributions to NeatOS. Please read the following guidelines before submitting.

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment

### How to Contribute

1. **Fork** the repository
2. **Create a branch** — `git checkout -b feature/your-feature-name`
3. **Make changes** — Follow existing code style and conventions
4. **Test** — Ensure the app builds and runs correctly
5. **Commit** — Use clear, descriptive commit messages
6. **Push** — `git push origin feature/your-feature-name`
7. **Open a Pull Request** — Describe your changes and reference any issues

### Contribution Rules

- **Swift style** — Follow Swift API Design Guidelines and project conventions
- **Documentation** — Add comments for non-obvious logic; update README if needed
- **Accessibility** — New UI must include VoiceOver labels and hints
- **Sandbox** — All file operations must respect macOS sandbox and security-scoped access
- **No breaking changes** — Avoid modifying public APIs without discussion

### Pull Request Policies

- PRs should be focused on a single feature or fix
- Include a brief description of the change
- Ensure CI/build passes (if applicable)
- Maintainers may request changes before merging

### Reporting Issues

- Use the issue tracker for bugs and feature requests
- Include macOS version, Xcode version, and steps to reproduce
- For crashes, attach relevant logs if possible

---

## Copyright

© 2026 Israel Manzo. All rights reserved.

This project is developed as a demonstration of macOS file management capabilities using SwiftUI and native macOS APIs. The NeatOS name and branding are part of this project.

---

**NeatOS** — Making file organization as easy as having a conversation! 🗂️✨
