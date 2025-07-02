import SwiftUI

struct ActionPreviewView: View {
    let actions: [CleanupAction]
    @Binding var selectedActions: Set<UUID>
    let onExecute: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectAll = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Summary
                summaryHeader
                
                // Actions List
                actionsList
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle(UIText.previewActions)
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(UIText.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            updateSelectAllState()
        }
        .onChange(of: selectedActions) { _ , _ in
            updateSelectAllState()
        }
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: SystemIcons.checkmarkCircleFill)
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(UIText.readyToOrganize)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(selectedActions.count) \(UIText.of) \(actions.count) \(UIText.actionsSelected)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Action Type Summary
            actionTypeSummary
            
            Divider()
        }
        .padding()
        .background(Color(.darkGray))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(UIText.summary): \(selectedActions.count) \(UIText.of) \(actions.count) \(UIText.actionsSelected)")
    }
    
    // MARK: - Action Type Summary
    private var actionTypeSummary: some View {
        let actionCounts = Dictionary(grouping: actions.filter { selectedActions.contains($0.id) }, by: { $0.action })
            .mapValues { $0.count }
        
        return HStack(spacing: 16) {
            ForEach(CleanupAction.ActionType.allCases, id: \.self) { actionType in
                if let count = actionCounts[actionType], count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: iconForActionType(actionType))
                            .foregroundColor(colorForActionType(actionType))
                            .font(.caption)
                        
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForActionType(actionType).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Actions List
    private var actionsList: some View {
        List {
            Section {
                ForEach(actions) { action in
                    ActionRowView(
                        action: action,
                        isSelected: selectedActions.contains(action.id)
                    ) {
                        toggleAction(action.id)
                    }
                }
            } header: {
                HStack {
                    Text(UIText.suggestedActions)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(selectAll ? UIText.deselectAll : UIText.selectAll) {
                        toggleSelectAll()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                Button(UIText.cancel) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("\(UIText.executeSelected) (\(selectedActions.count))") {
                    onExecute()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(selectedActions.isEmpty)
            }
            .padding()
        }
        .background(Color(.darkGray))
    }
    
    // MARK: - Helper Methods
    private func toggleAction(_ id: UUID) {
        if selectedActions.contains(id) {
            selectedActions.remove(id)
        } else {
            selectedActions.insert(id)
        }
    }
    
    private func toggleSelectAll() {
        if selectAll {
            selectedActions.removeAll()
        } else {
            selectedActions = Set(actions.map { $0.id })
        }
    }
    
    private func updateSelectAllState() {
        selectAll = selectedActions.count == actions.count && !actions.isEmpty
    }
    
    private func iconForActionType(_ actionType: CleanupAction.ActionType) -> String {
        switch actionType {
        case .move:
            return SystemIcons.folder
        case .archive:
            return SystemIcons.archivebox
        case .delete:
            return SystemIcons.trash
        case .compress:
            return SystemIcons.zip
        }
    }
    
    private func colorForActionType(_ actionType: CleanupAction.ActionType) -> Color {
        switch actionType {
        case .move:
            return .blue
        case .archive:
            return .orange
        case .delete:
            return .red
        case .compress:
            return .purple
        }
    }
}

// MARK: - Action Row View
struct ActionRowView: View {
    let action: CleanupAction
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? SystemIcons.checkmarkCircleFill : SystemIcons.circle)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isSelected ? UIText.deselectAction : UIText.selectAction)
            
            // Action Icon
            Image(systemName: iconForAction(action.action))
                .foregroundColor(colorForAction(action.action))
                .font(.title3)
                .frame(width: 24)
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(action.file.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(action.file.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Destination
            VStack(alignment: .trailing, spacing: 2) {
                Text(action.destination)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Image(systemName: SystemIcons.arrowRight)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(action.file.name), \(action.description), \(action.file.formattedSize)")
        .accessibilityHint("Double tap to \(isSelected ? UIText.doubleTapToDeselect : UIText.doubleTapToSelect)")
    }
    
    private func iconForAction(_ actionType: CleanupAction.ActionType) -> String {
        switch actionType {
        case .move:
            return SystemIcons.folder
        case .archive:
            return SystemIcons.archivebox
        case .delete:
            return SystemIcons.trash
        case .compress:
            return SystemIcons.zip
        }
    }
    
    private func colorForAction(_ actionType: CleanupAction.ActionType) -> Color {
        switch actionType {
        case .move:
            return .blue
        case .archive:
            return .orange
        case .delete:
            return .red
        case .compress:
            return .purple
        }
    }
}

// MARK: - Action Type Extension
extension CleanupAction.ActionType: CaseIterable {
    static var allCases: [CleanupAction.ActionType] {
        [.move, .archive, .delete, .compress]
    }
} 
