import SwiftUI
import UniformTypeIdentifiers

enum FileSortField: String, CaseIterable, Identifiable {
    case size = "Size"
    case fileExtension = "Extension"
    case format = "Format"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .size:
            return "internaldrive"
        case .fileExtension:
            return "number"
        case .format:
            return "doc.badge.gearshape"
        }
    }
    
    var helperText: String {
        switch self {
        case .size:
            return "Largest or smallest files first."
        case .fileExtension:
            return "Groups by file extension (.pdf, .jpg, .zip)."
        case .format:
            return "Groups by file kind (PDF document, JPEG image)."
        }
    }
}

enum FileSortDirection: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .ascending:
            return "arrow.up"
        case .descending:
            return "arrow.down"
        }
    }
}

struct FileSortBar: View {
    @Binding var field: FileSortField
    @Binding var direction: FileSortDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label("Sort files", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Sort by", selection: $field) {
                    ForEach([FileSortField.size, .fileExtension, .format]) { option in
                        Label(option.rawValue, systemImage: option.icon).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .help("Choose how to sort this list.")
                
                Button {
                    direction = (direction == .ascending) ? .descending : .ascending
                } label: {
                    Image(systemName: direction.icon)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 28, height: 24)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.bordered)
                .help(direction == .ascending ? "Ascending order" : "Descending order")
                .accessibilityLabel("Sort direction")
                .accessibilityValue(direction.rawValue)
            }
            
            Text(field.helperText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

extension FileInfo {
    var formatDisplayName: String {
        let ext = self.extension.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ext.isEmpty else { return category.rawValue }
        if let type = UTType(filenameExtension: ext) {
            return type.localizedDescription ?? type.preferredFilenameExtension?.uppercased() ?? ext.uppercased()
        }
        return ext.uppercased()
    }
}

extension Array where Element == FileInfo {
    func sorted(by field: FileSortField, direction: FileSortDirection) -> [FileInfo] {
        func compareComparable<T: Comparable>(_ a: T, _ b: T) -> Bool {
            direction == .ascending ? (a < b) : (a > b)
        }
        
        func compareString(_ a: String, _ b: String) -> Bool {
            let result = a.localizedCaseInsensitiveCompare(b)
            switch direction {
            case .ascending:
                return result == .orderedAscending
            case .descending:
                return result == .orderedDescending
            }
        }
        
        return self.sorted { lhs, rhs in
            switch field {
            case .size:
                if lhs.size != rhs.size { return compareComparable(lhs.size, rhs.size) }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .fileExtension:
                let le = lhs.extension
                let re = rhs.extension
                if le.isEmpty != re.isEmpty { return !le.isEmpty } // keep "no extension" last
                if le != re { return compareString(le, re) }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .format:
                let lf = lhs.formatDisplayName
                let rf = rhs.formatDisplayName
                if lf != rf { return compareString(lf, rf) }
                if lhs.extension.isEmpty != rhs.extension.isEmpty { return !lhs.extension.isEmpty } // keep "no extension" last
                if lhs.extension != rhs.extension { return compareString(lhs.extension, rhs.extension) }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }
}

