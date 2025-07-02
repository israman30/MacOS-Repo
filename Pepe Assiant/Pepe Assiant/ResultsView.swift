import SwiftUI

struct ResultsView: View {
    let scanResults: ScanResults
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: FileCategory?
    @State private var showingFileDetail = false
    @State private var selectedFile: FileInfo?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Cards
                summaryCards
                
                // Category Tabs
                categoryTabs
                
                // Content Area
                contentArea
            }
            .navigationTitle(UIText.scanResults)
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(UIText.done) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFileDetail) {
            if let file = selectedFile {
                FileDetailView(file: file)
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
        .background(Color(.darkGray))
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
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.darkGray))
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = FileCategory.allCases.first { scanResults.filesByCategory[$0]?.isEmpty == false }
            }
        }
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        Group {
            if let category = selectedCategory,
               let files = scanResults.filesByCategory[category],
               !files.isEmpty {
                FileListView(
                    files: files,
                    category: category,
                    onFileSelected: { file in
                        selectedFile = file
                        showingFileDetail = true
                    }
                )
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: SystemIcons.folder)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No files found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Select a different category or scan a different location")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.darkGray))
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
        .background(Color(.darkGray))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
            .background(isSelected ? category.color.opacity(0.2) : Color(.darkGray))
            .foregroundColor(isSelected ? category.color : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(category.rawValue) category with \(fileCount) files")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - File List View
struct FileListView: View {
    let files: [FileInfo]
    let category: FileCategory
    let onFileSelected: (FileInfo) -> Void
    
    var body: some View {
        List {
            ForEach(files.sorted { $0.modificationDate > $1.modificationDate }) { file in
                FileRowView(file: file) {
                    onFileSelected(file)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - File Row View
struct FileRowView: View {
    let file: FileInfo
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // File Icon
            Image(systemName: iconForFile(file))
                .foregroundColor(file.category.color)
                .font(.title3)
                .frame(width: 24)
            
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
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(file.name), \(file.formattedSize), modified \(formatDate(file.modificationDate))")
        .accessibilityHint("Double tap to view file details")
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

// MARK: - File Detail View
struct FileDetailView: View {
    let file: FileInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // File Header
                    fileHeader
                    
                    // File Properties
                    fileProperties
                    
                    // Quick Actions
                    quickActions
                }
                .padding()
            }
            .navigationTitle("File Details")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - File Header
    private var fileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: iconForFile(file))
                .font(.system(size: 64))
                .foregroundColor(file.category.color)
            
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
        .background(Color(.darkGray))
        .cornerRadius(12)
    }
    
    // MARK: - File Properties
    private var fileProperties: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File Properties")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PropertyRow(title: "Size", value: file.formattedSize)
                PropertyRow(title: "Type", value: file.formattedSize)
                PropertyRow(title: "Created", value: formatDate(file.creationDate))
                PropertyRow(title: "Modified", value: formatDate(file.modificationDate))
                PropertyRow(title: "Location", value: file.url.deletingLastPathComponent().lastPathComponent)
                
                if file.isOld {
                    PropertyRow(title: "Age", value: "\(file.daysSinceModified) days old")
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
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
                        // Implement compress action
                    }
                }
                
                QuickActionButton(
                    title: "Move to Trash",
                    icon: "trash",
                    color: .red
                ) {
                    // Implement delete action
                }
            }
        }
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
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.darkGray))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
    }
} 
