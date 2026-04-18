import SwiftUI
import AppKit

struct ResultsView: View {
    let scanResults: ScanResults
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var fileOperations: FileOperations
    @State private var selectedCategory: FileCategory?
    @State private var selectedFileID: UUID?
    @State private var sortField: FileSortField = .size
    @State private var sortDirection: FileSortDirection = .descending
    @State private var showingLargeFiles = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Cards
                summaryCards
                
                // Large Files Banner
                largeFilesBanner
                
                // Category Tabs
                categoryTabs
                
                // Content Area
                contentArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(UIText.scanResults)
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .accessibilityHidden(true)
                        Text(UIText.scanResults)
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("Close")
                    .help("Close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(UIText.done) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingLargeFiles) {
            LargeFilesView(files: scanResults.largeFiles)
                .environmentObject(fileOperations)
        }
        .onChange(of: sortField) { _, _ in
            if let category = selectedCategory {
                let files = scanResults.filesByCategory[category] ?? []
                if selectedFileID == nil {
                    selectedFileID = files.sorted(by: sortField, direction: sortDirection).first?.id
                }
            }
        }
        .onChange(of: sortDirection) { _, _ in
            if let category = selectedCategory {
                let files = scanResults.filesByCategory[category] ?? []
                if selectedFileID == nil {
                    selectedFileID = files.sorted(by: sortField, direction: sortDirection).first?.id
                }
            }
        }
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                SummaryCard(
                    title: UIText.totalFiles,
                    value: "\(scanResults.totalFiles)",
                    icon: SystemIcons.doc,
                    color: .blue
                )
                
                SummaryCard(
                    title: UIText.totalSize,
                    value: scanResults.formattedTotalSize,
                    icon: SystemIcons.externaldrive,
                    color: .green
                )
                
                SummaryCard(
                    title: UIText.duplicates,
                    value: "\(scanResults.duplicates.values.flatMap { $0 }.count)",
                    icon: SystemIcons.docOnDoc,
                    color: .orange
                )
                
                SummaryCard(
                    title: UIText.similarFiles,
                    value: "\(scanResults.similarFiles.flatMap { $0 }.count)",
                    icon: "photo.on.rectangle.angled",
                    color: .teal
                )
                
                SummaryCard(
                    title: UIText.oldFiles,
                    value: "\(scanResults.oldFiles.count)",
                    icon: SystemIcons.clock,
                    color: .red
                )
                
                SummaryCard(
                    title: UIText.largeFiles,
                    value: "\(scanResults.largeFiles.count)",
                    icon: SystemIcons.arrowUpCircle,
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AppTheme.headerGradient)
        .accessibilityLabel("Summary")
    }
    
    // MARK: - Large Files Banner
    private var largeFilesBanner: some View {
        Group {
            if !scanResults.largeFiles.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: SystemIcons.arrowUpCircleFill)
                        .foregroundColor(.purple)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Large files detected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(scanResults.largeFiles.count) file(s) ≥ \(LargeFileRules.thresholdMB) MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Review") {
                        showingLargeFiles = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
                    .accessibilityLabel("Review large files")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.08))
                .overlay(
                    Rectangle()
                        .fill(AppTheme.borderLight)
                        .frame(height: 1),
                    alignment: .bottom
                )
            }
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FileCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        fileCount: scanResults.filesByCategory[category]?.count ?? 0,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        let files = scanResults.filesByCategory[category] ?? []
                        selectedFileID = files.sorted(by: sortField, direction: sortDirection).first?.id
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AppTheme.headerGradient)
        .accessibilityLabel("Categories")
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = FileCategory.allCases.first { scanResults.filesByCategory[$0]?.isEmpty == false }
            }
            if let category = selectedCategory {
                let files = scanResults.filesByCategory[category] ?? []
                selectedFileID = files.sorted(by: sortField, direction: sortDirection).first?.id
            }
        }
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            if let category = selectedCategory,
               let files = scanResults.filesByCategory[category],
               !files.isEmpty {
                HSplitView {
                    FileListView(
                        files: files,
                        category: category,
                        sortField: $sortField,
                        sortDirection: $sortDirection,
                        selectedFileID: $selectedFileID
                    )
                    .frame(minWidth: 460, idealWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    Group {
                        if let id = selectedFileID,
                           let file = files.first(where: { $0.id == id }) {
                            FileDetailPanel(file: file)
                                .environmentObject(fileOperations)
                        } else {
                            emptyDetailView
                        }
                    }
                    .frame(minWidth: 420, idealWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .layoutPriority(1)
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: SystemIcons.folder)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            Text("No files found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Select a different category or scan a different location")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No files found. Select a different category or scan a different location.")
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 34))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            
            Text("Select a file")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Its details will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Select a file to view details.")
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .accessibilityHidden(true)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(width: 120, height: 80)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .shadow(color: AppTheme.primary.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: FileCategory
    let fileCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .accessibilityHidden(true)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if fileCount > 0 {
                    Text("(\(fileCount))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.opacity(0.2) : AppTheme.cardBackground)
            .foregroundColor(isSelected ? category.color : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(category.rawValue) category with \(fileCount) files")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Shows files in the \(category.rawValue) category.")
    }
}

// MARK: - File List View
struct FileListView: View {
    let files: [FileInfo]
    let category: FileCategory
    @Binding var sortField: FileSortField
    @Binding var sortDirection: FileSortDirection
    @Binding var selectedFileID: UUID?
    
    var body: some View {
        VStack(spacing: 10) {
            FileSortBar(field: $sortField, direction: $sortDirection)
                .padding(.horizontal)
                .padding(.top, 10)
            
            List(selection: $selectedFileID) {
                ForEach(files.sorted(by: sortField, direction: sortDirection)) { file in
                    FileRowView(
                        file: file,
                        isSelected: selectedFileID == file.id
                    ) {
                        selectedFileID = file.id
                    }
                    .tag(file.id)
                }
            }
            .listStyle(PlainListStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - File Row View
struct FileRowView: View {
    let file: FileInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // File Icon
            Image(systemName: iconForFile(file))
                .foregroundColor(file.category.color)
                .font(.title3)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !file.extension.isEmpty {
                        Text(file.extension.uppercased())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.borderLight.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .accessibilityLabel("Extension")
                            .accessibilityValue(file.extension)
                    }
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(file.modificationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if file.isOld {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Old")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if file.isLarge {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Large")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .background(isSelected ? AppTheme.primary.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(file.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Double tap to view file details")
    }

    private var accessibilityValue: String {
        var parts: [String] = [
            file.formattedSize,
            "modified \(formatDate(file.modificationDate))"
        ]
        if file.isOld { parts.append("Old") }
        if file.isLarge { parts.append("Large") }
        return parts.joined(separator: ", ")
    }
    
    private func iconForFile(_ file: FileInfo) -> String {
        switch file.category {
        case .images:
            return "photo"
        case .documents:
            return "doc.text"
        case .videos:
            return "video"
        case .audio:
            return "music.note"
        case .archives:
            return "archivebox"
        case .screenshots:
            return "camera"
        case .downloads:
            return "arrow.down.circle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - File Detail Panel (Right side)
struct FileDetailPanel: View {
    let file: FileInfo
    @EnvironmentObject private var fileOperations: FileOperations
    @State private var showingCompressionOptions = false
    @State private var operationError: AppError?
    
    var body: some View {
        VStack(spacing: 0) {
            FilePreviewPane(url: file.url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.surface)
            
            Rectangle()
                .fill(AppTheme.borderLight)
                .frame(height: 1)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fileHeader
                    fileProperties
                    quickActions
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .background(AppTheme.surface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - File Header
    private var fileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: iconForFile(file))
                .font(.system(size: 64))
                .foregroundColor(file.category.color)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(file.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(file.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(file.category.color.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - File Properties
    private var fileProperties: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Properties")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PropertyRow(title: "Size", value: file.formattedSize)
                PropertyRow(title: "Type", value: fileTypeValue)
                PropertyRow(title: "Created", value: formatDate(file.creationDate))
                PropertyRow(title: "Modified", value: formatDate(file.modificationDate))
                PropertyRow(title: "Location", value: file.url.deletingLastPathComponent().lastPathComponent)
                
                if file.isOld {
                    PropertyRow(title: "Age", value: "\(file.daysSinceModified) days old")
                }
            }
        }
    }

    private var fileTypeValue: String {
        let ext = file.extension.trimmingCharacters(in: .whitespacesAndNewlines)
        if ext.isEmpty {
            return file.category.rawValue
        }
        let kind = file.formatDisplayName
        return "\(kind) (.\(ext.lowercased()))"
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                QuickActionButton(
                    title: "Reveal in Finder",
                    icon: "magnifyingglass",
                    color: .teal
                ) {
                    NSWorkspace.shared.activateFileViewerSelecting([file.url])
                }
                
                QuickActionButton(
                    title: "Move to Organized Folder",
                    icon: "folder",
                    color: .blue
                ) {
                    // Implement move action
                }
                
                if file.isOld {
                    QuickActionButton(
                        title: "Archive File",
                        icon: "archivebox",
                        color: .orange
                    ) {
                        // Implement archive action
                    }
                }
                
                if file.isLarge {
                    QuickActionButton(
                        title: "Compress File",
                        icon: "zip",
                        color: .purple
                    ) {
                        showingCompressionOptions = true
                    }
                }
                
                QuickActionButton(
                    title: "Move to Trash",
                    icon: "trash",
                    color: .red
                ) {
                    Task {
                        let ok = await fileOperations.moveToTrash(file)
                        if !ok {
                            operationError = ErrorHandler.message("Could not move the file to Trash.", title: "Operation failed")
                        }
                    }
                }
            }
        }
        .confirmationDialog("Compress \(file.name)", isPresented: $showingCompressionOptions, titleVisibility: .visible) {
            Button("Compress (keep original)") {
                Task {
                    let ok = await fileOperations.compressKeepingOriginal(file)
                    if !ok { operationError = ErrorHandler.message("Could not compress the file.", title: "Operation failed") }
                }
            }
            Button("Compress & Replace (delete original)", role: .destructive) {
                Task {
                    let ok = await fileOperations.compressAndReplace(file)
                    if !ok { operationError = ErrorHandler.message("Could not compress the file.", title: "Operation failed") }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you want to compress this file.")
        }
        .appErrorAlert($operationError)
    }
    
    private func iconForFile(_ file: FileInfo) -> String {
        switch file.category {
        case .images:
            return "photo"
        case .documents:
            return "doc.text"
        case .videos:
            return "video"
        case .audio:
            return "music.note"
        case .archives:
            return "archivebox"
        case .screenshots:
            return "camera"
        case .downloads:
            return "arrow.down.circle"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Property Row
struct PropertyRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Performs this quick action.")
    }
} 

// MARK: - Large Files View
struct LargeFilesView: View {
    let files: [FileInfo]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var fileOperations: FileOperations
    
    @State private var operationError: AppError?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if fileOperations.isProcessing {
                    VStack(spacing: 8) {
                        ProgressView(value: fileOperations.processingProgress)
                            .progressViewStyle(.linear)
                            .tint(.purple)
                        Text(fileOperations.currentOperation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(AppTheme.surfaceElevated)
                }
                
                List {
                    Section {
                        ForEach(files.sorted { $0.size > $1.size }) { file in
                            HStack(spacing: 12) {
                                Image(systemName: icon(for: file))
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 8) {
                                        Text(file.formattedSize)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(file.largeFileTypeSingularLabel)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(file.formatDisplayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if !file.extension.isEmpty {
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(file.extension.uppercased())
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.borderLight.opacity(0.18))
                                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Menu {
                                    Button("Reveal in Finder") {
                                        NSWorkspace.shared.activateFileViewerSelecting([file.url])
                                    }
                                    Button("Compress (keep original)") {
                                        Task {
                                            let ok = await fileOperations.compressKeepingOriginal(file)
                                            if !ok { operationError = ErrorHandler.message("Could not compress the file.", title: "Operation failed") }
                                        }
                                    }
                                    Button("Compress & Replace (delete original)", role: .destructive) {
                                        Task {
                                            let ok = await fileOperations.compressAndReplace(file)
                                            if !ok { operationError = ErrorHandler.message("Could not compress the file.", title: "Operation failed") }
                                        }
                                    }
                                    Divider()
                                    Button("Move to Trash", role: .destructive) {
                                        Task {
                                            let ok = await fileOperations.moveToTrash(file)
                                            if !ok { operationError = ErrorHandler.message("Could not move the file to Trash.", title: "Operation failed") }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Large Files")
                    } footer: {
                        Text("Threshold: \(LargeFileRules.thresholdMB) MB. ZIP compression may not significantly reduce already-compressed media like videos.")
                    }
                }
                .listStyle(.inset)
            }
            .navigationTitle("Large Files")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
            .appErrorAlert($operationError)
        }
        .frame(minWidth: 760, idealWidth: 920, maxWidth: .infinity,
               minHeight: 620, idealHeight: 740, maxHeight: .infinity)
    }
    
    private func icon(for file: FileInfo) -> String {
        switch file.largeFileKind {
        case .photos:
            return "photo"
        case .videos:
            return "video"
        case .audio:
            return "music.note"
        case .books, .documents:
            return "doc.text"
        case .archives:
            return "archivebox"
        case .other:
            return "doc"
        }
    }
}
