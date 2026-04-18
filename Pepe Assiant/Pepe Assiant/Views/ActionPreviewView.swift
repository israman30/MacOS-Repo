import SwiftUI
import AppKit

struct ActionPreviewView: View {
    let actions: [CleanupAction]
    @Binding var selectedActions: Set<UUID>
    let onExecute: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectAll = false
    @State private var showingExecuteConfirmation = false
    
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
                    HStack(spacing: 8) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .accessibilityHidden(true)
                        Text(UIText.previewActions)
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: ActionPreviewLabels.Icon.xmark_circle_fill)
                    }
                    .accessibilityLabel(UIText.close)
                    .help(UIText.close)
                }
            }
        }
        .frame(minWidth: 820, idealWidth: 980, maxWidth: .infinity,
               minHeight: 640, idealHeight: 740, maxHeight: .infinity)
        .onAppear {
            updateSelectAllState()
        }
        .onChange(of: selectedActions) { _ , _ in
            updateSelectAllState()
        }
        .alert(SmartTidyRules.confirmExecuteTitle, isPresented: $showingExecuteConfirmation) {
            Button(ActionPreviewLabels.cancel, role: .cancel) { }
            Button(ActionPreviewLabels.proceed) {
                performExecute()
            }
        } message: {
            Text(String(format: SmartTidyRules.confirmExecuteMessage, selectedActions.count))
        }
    }
    
    private func performExecute() {
        onExecute()
        dismiss()
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: SystemIcons.checkmarkCircleFill)
                    .foregroundColor(AppTheme.success)
                    .font(.title2)
                    .accessibilityHidden(true)
                
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
            
            Rectangle()
                .fill(AppTheme.borderLight)
                .frame(height: 1)
        }
        .padding()
        .background(AppTheme.headerGradient)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UIText.summary)
        .accessibilityValue("\(selectedActions.count) \(UIText.of) \(actions.count) \(UIText.actionsSelected)")
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
                            .accessibilityHidden(true)
                        
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForActionType(actionType).opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabelForActionType(actionType))
                    .accessibilityValue("\(count)")
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
                    .foregroundColor(AppTheme.primaryDark)
                    .accessibilityLabel(selectAll ? UIText.deselectAll : UIText.selectAll)
                    .accessibilityValue("\(selectedActions.count) \(UIText.of) \(actions.count) \(UIText.actionsSelected)")
                    .accessibilityHint(UIText.selects_or_deselects_all_suggested_actions)
                }
            }
        }
        .listStyle(PlainListStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1)
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
                .accessibilityHint(UIText.closes_the_preview_without_making_changes)
                
                Button("\(UIText.executeSelected) (\(selectedActions.count))") {
                    if SmartTidyRules.alwaysAskBeforeAction {
                        showingExecuteConfirmation = true
                    } else {
                        performExecute()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .disabled(selectedActions.isEmpty)
                .accessibilityHint(UIText.executes_the_selected_cleanup_actions)
            }
            .padding()
        }
        .background(AppTheme.surface)
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
    
    private func accessibilityLabelForActionType(_ actionType: CleanupAction.ActionType) -> String {
        switch actionType {
        case .move:
            return "Move actions"
        case .archive:
            return "Archive actions"
        case .delete:
            return "Delete actions"
        case .compress:
            return "Compress actions"
        }
    }
}

// MARK: - Action Row View
struct ActionRowView: View {
    let action: CleanupAction
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection Checkbox
                Image(systemName: isSelected ? SystemIcons.checkmarkCircleFill : SystemIcons.circle)
                    .foregroundColor(isSelected ? AppTheme.primary : .secondary)
                    .font(.title3)
                    .accessibilityHidden(true)
                
                // Action Icon
                Image(systemName: iconForAction(action.action))
                    .foregroundColor(colorForAction(action.action))
                    .font(.title3)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                
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
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(action.file.name)
        .accessibilityValue("\(action.description), \(action.file.formattedSize), \(isSelected ? "Selected" : "Not selected")")
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
