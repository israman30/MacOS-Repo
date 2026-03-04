# Pepe Assistant - File Organization Bot

A friendly macOS assistant that helps you organize, clean, and archive files with natural language commands.

## 🎯 Core Promise

Transform messy desktops and file systems into organized spaces with simple commands like:
- "Clean my desktop"
- "Find duplicates"
- "Archive old files"
- "Organize downloads"

## ✨ Key Features

### 🤖 Conversational Interface
- Natural language processing for file organization requests
- Friendly, helpful tone with clear explanations
- Interactive chat bubbles with action buttons
- Real-time progress feedback during operations

### 📁 Smart File Analysis
- **File Classification**: Automatically categorizes files by type (images, documents, videos, etc.)
- **Duplicate Detection**: Finds duplicate files using SHA256 hashing
- **Age Analysis**: Identifies old files (90+ days) for archiving
- **Size Analysis**: Flags large files (>500MB) for compression
- **Screenshot Detection**: Special handling for screenshot files

### 🧹 Intelligent Cleanup Actions
- **Move**: Organize files into categorized folders
- **Archive**: Compress old files into dated archives
- **Delete**: Safely move duplicates to trash
- **Compress**: Reduce storage space for large files

### 🔄 Undo & Safety
- Complete undo functionality for all operations
- Preview actions before execution
- Safe file operations (move to trash, not permanent deletion)
- Conflict resolution for duplicate filenames

### ♿ Accessibility Support
- Full VoiceOver compatibility
- Keyboard navigation support
- High contrast mode support
- Plain language UI elements

## 🚀 How to Use

### Getting Started
1. Launch the app
2. Type your request in natural language
3. Review suggested actions
4. Execute cleanup operations
5. Use undo if needed

### Example Commands
```
"Clean my desktop"
"Scan downloads folder"
"Find duplicate files"
"Archive old documents"
"Organize my files"
```

### Supported Locations
- Desktop
- Downloads folder
- Documents folder

## 🏗️ Technical Architecture

### Core Components

#### FileManager.swift
- File information models and data structures
- File categorization system
- Sorting rules and cleanup actions

#### FileScanner.swift
- Directory scanning and file analysis
- Duplicate detection using SHA256 hashing
- File metadata extraction
- Progress tracking

#### FileOperations.swift
- File movement, archiving, and deletion
- Undo stack management
- Conflict resolution
- Safe file operations

#### BotAssistantView.swift
- Main conversational interface
- Natural language processing
- Chat message handling
- Action coordination

#### ActionPreviewView.swift
- Preview cleanup actions before execution
- Action selection and customization
- Summary statistics

#### ResultsView.swift
- Detailed file analysis results
- Category-based file browsing
- File detail inspection
- Quick action buttons

### File Categories
- **Images**: JPG, PNG, GIF, HEIC, etc.
- **Documents**: PDF, DOC, TXT, etc.
- **Videos**: MP4, MOV, AVI, etc.
- **Audio**: MP3, WAV, AAC, etc.
- **Archives**: ZIP, RAR, DMG, etc.
- **Screenshots**: Auto-detected screenshot files
- **Downloads**: Files from download folder
- **Unknown**: Unrecognized file types

### Sorting Rules
- **Date-based**: Archive files older than 90 days
- **Type-based**: Move files to appropriate category folders
- **Size-based**: Flag files larger than 500MB
- **Duplicate-based**: Keep newest, suggest deletion of others
- **Frequency-based**: Archive rarely accessed files

## 🔧 Development

### Requirements
- macOS 12.0+
- Xcode 14.0+
- Swift 5.7+

### Building
1. Clone the repository
2. Open `Pepe Assiant.xcodeproj` in Xcode
3. Build and run the project

### Project Structure
```
Pepe Assiant/
├── Pepe_AssiantApp.swift      # App entry point
├── ContentView.swift          # Main content view
├── BotAssistantView.swift     # Conversational interface
├── FileManager.swift          # Data models and rules
├── FileScanner.swift          # File analysis engine
├── FileOperations.swift       # File operations manager
├── ActionPreviewView.swift    # Action preview interface
├── ResultsView.swift          # Results display
└── Assets.xcassets/          # App assets
```

## 🛡️ Safety Features

### File Protection
- All deletions move files to trash (not permanent)
- Undo functionality for all operations
- Conflict resolution prevents overwrites
- Progress tracking for long operations

### User Control
- Preview all actions before execution
- Selective action execution
- Cancel operations at any time
- Clear feedback on all operations

## 🎨 UI/UX Design

### Design Principles
- **Friendly**: Conversational, helpful tone
- **Clear**: Plain language, no jargon
- **Safe**: Preview and confirm all actions
- **Accessible**: Full accessibility support
- **Responsive**: Real-time feedback and progress

### Visual Design
- Modern SwiftUI interface
- Category-based color coding
- Intuitive icons and symbols
- Consistent spacing and typography
- Dark mode support

## 🔮 Future Enhancements

### Planned Features
- Custom sorting rules
- Scheduled cleanup operations
- Cloud storage integration
- Advanced duplicate detection
- File usage analytics
- Batch operations
- Export/import settings

### Potential Integrations
- Apple Shortcuts
- Spotlight search
- Finder integration
- Notification Center
- Menu bar app

## 📄 License

This project is developed as a demonstration of macOS file management capabilities using SwiftUI and native macOS APIs.

## 🤝 Contributing

This is a demonstration project showcasing file organization capabilities. Feel free to explore the code and adapt it for your own projects.

---

**Pepe Assistant** - Making file organization as easy as having a conversation! 🗂️✨ 