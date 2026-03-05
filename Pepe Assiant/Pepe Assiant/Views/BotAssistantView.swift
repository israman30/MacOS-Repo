import SwiftUI
import Foundation

struct BotAssistantView: View {
    @StateObject private var fileScanner = FileScanner()
    @StateObject private var fileOperations = FileOperations()
    @StateObject private var xcodeCleaner = XcodeCleaner()
    @State private var scanResults: ScanResults?
    @State private var selectedActions: Set<UUID> = []
    @State private var showingActionPreview = false
    @State private var showingResults = false
    @State private var userInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isProcessing = false
    
    private let fileManager = FileManager.default
    
    // MARK: - Chat Message
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
        let action: BotAction?
        
        enum BotAction {
            case scanDesktop
            case scanDownloads
            case scanDocuments
            case cleanAll
            case showResults
            case clearDerivedData
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Rectangle()
                .fill(AppTheme.borderLight)
                .frame(height: 1)
            
            // Chat Area
            chatArea
                .background(AppTheme.surface)
            
            Rectangle()
                .fill(AppTheme.borderLight)
                .frame(height: 1)
            
            // Input Area
            inputArea
        }
        .background(AppTheme.surface)
        .onAppear {
            addWelcomeMessage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pepeScanDesktop)) { _ in
            addBotMessage(BotMessages.scanDesktopMessage, action: .scanDesktop)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pepeScanDownloads)) { _ in
            addBotMessage(BotMessages.scanDownloadsMessage, action: .scanDownloads)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pepeScanDocuments)) { _ in
            addBotMessage(BotMessages.scanDocumentsMessage, action: .scanDocuments)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pepeClearDerivedData)) { _ in
            clearDerivedData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pepeUndo)) { _ in
            Task { await fileOperations.undoLastAction() }
        }
        .sheet(isPresented: $showingActionPreview) {
            ActionPreviewView(
                actions: scanResults?.suggestedActions ?? [],
                selectedActions: $selectedActions,
                onExecute: executeSelectedActions
            )
        }
        .sheet(isPresented: $showingResults) {
            ResultsView(scanResults: scanResults ?? ScanResults(
                totalFiles: 0,
                filesByCategory: [:],
                duplicates: [:],
                similarFiles: [],
                oldFiles: [],
                largeFiles: [],
                suggestedActions: []
            ))
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: SystemIcons.sparkles)
                    .font(.title2)
                    .foregroundStyle(AppTheme.userBubbleGradient)
                    .accessibilityHidden(true)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(AppConstants.appName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(AppConstants.appDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(AppConstants.appName). \(AppConstants.appDescription)")
            
            Spacer()
            
            if fileOperations.canUndo {
                Button("\(UIText.undo) (\(fileOperations.undoCount))") {
                    Task {
                        await fileOperations.undoLastAction()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(UIText.undo)
                .accessibilityValue("\(fileOperations.undoCount)")
                .accessibilityHint("Reverts the most recent file operation.")
            }
        }
        .padding()
        .background(AppTheme.headerGradient)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.borderLight),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(UIText.pepeAssistantHeader)
    }
    
    // MARK: - Chat Area
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message) { action in
                            handleBotAction(action)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    if fileScanner.isScanning {
                        scanningProgressView
                    }
                    
                    if fileOperations.isProcessing {
                        processingProgressView
                    }
                }
                .padding()
            }
            .accessibilityLabel("Conversation")
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Scanning Progress View
    private var scanningProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                    .accessibilityHidden(true)
                Text("\(UIText.scanning) \(fileScanner.currentScanLocation)...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: fileScanner.scanProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(AppTheme.primary)
                .frame(height: 6)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UIText.scanningProgress)
        .accessibilityValue("\(Int(fileScanner.scanProgress * 100))% \(UIText.complete)")
    }
    
    // MARK: - Processing Progress View
    private var processingProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                    .accessibilityHidden(true)
                Text(fileOperations.currentOperation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: fileOperations.processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(AppTheme.primary)
                .frame(height: 6)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UIText.processingProgress)
        .accessibilityValue("\(Int(fileOperations.processingProgress * 100))% \(UIText.complete)")
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Quick action chips
            quickActionChips
            
            HStack(spacing: 12) {
                TextField(UIText.messageInputPlaceholder, text: $userInput)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .onSubmit {
                        sendMessage()
                    }
                    .accessibilityLabel(UIText.messageInputField)
                    .accessibilityHint("Type your message to the assistant.")
                
                Button(action: sendMessage) {
                    let isEmpty = userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if isEmpty {
                        Image(systemName: SystemIcons.arrowUpCircleFill)
                            .font(.title2)
                            .foregroundStyle(Color.secondary)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: SystemIcons.arrowUpCircleFill)
                            .font(.title2)
                            .foregroundStyle(AppTheme.userBubbleGradient)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(UIText.sendMessage)
                .accessibilityHint("Sends your message.")
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.borderLight),
            alignment: .top
        )
    }
    
    // MARK: - Quick Action Chips
    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickChip(title: "Desktop", icon: SystemIcons.folder, accentColor: AppTheme.chipColors[0]) {
                    addBotMessage(BotMessages.scanDesktopMessage, action: .scanDesktop)
                }
                QuickChip(title: "Downloads", icon: SystemIcons.arrowDownCircle, accentColor: AppTheme.chipColors[1]) {
                    addBotMessage(BotMessages.scanDownloadsMessage, action: .scanDownloads)
                }
                QuickChip(title: "Documents", icon: SystemIcons.doc, accentColor: AppTheme.chipColors[2]) {
                    addBotMessage(BotMessages.scanDocumentsMessage, action: .scanDocuments)
                }
                QuickChip(title: "Find Duplicates", icon: SystemIcons.docOnDoc, accentColor: AppTheme.chipColors[3]) {
                    addBotMessage(BotMessages.duplicateMessage, action: .scanDesktop)
                }
                QuickChip(title: XcodeCleanerText.chipTitle, icon: SystemIcons.hammer, accentColor: AppTheme.accent) {
                    clearDerivedData()
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        let userMessage = ChatMessage(text: trimmedInput, isUser: true, timestamp: Date(), action: nil)
        messages.append(userMessage)
        userInput = ""
        
        // Process user input and generate bot response
        processUserInput(trimmedInput)
    }
    
    // MARK: - Process User Input
    private func processUserInput(_ input: String) {
        let lowercasedInput = input.lowercased()
        
        if lowercasedInput.contains(UserInputKeywords.clean) || lowercasedInput.contains(UserInputKeywords.organize) {
            if lowercasedInput.contains(UserInputKeywords.desktop) {
                addBotMessage(BotMessages.scanDesktopMessage, action: .scanDesktop)
            } else if lowercasedInput.contains(UserInputKeywords.download) {
                addBotMessage(BotMessages.scanDownloadsMessage, action: .scanDownloads)
            } else if lowercasedInput.contains(UserInputKeywords.document) {
                addBotMessage(BotMessages.scanDocumentsMessage, action: .scanDocuments)
            } else {
                addBotMessage(BotMessages.chooseLocationMessage, action: nil)
            }
        } else if lowercasedInput.contains(UserInputKeywords.scan) || lowercasedInput.contains(UserInputKeywords.check) {
            addBotMessage(BotMessages.scanGeneralMessage, action: .scanDesktop)
        } else if lowercasedInput.contains(UserInputKeywords.duplicate) {
            addBotMessage(BotMessages.duplicateMessage, action: .scanDesktop)
        } else if lowercasedInput.contains(UserInputKeywords.archive) || lowercasedInput.contains(UserInputKeywords.old) {
            addBotMessage(BotMessages.archiveMessage, action: .scanDesktop)
        } else if lowercasedInput.contains(UserInputKeywords.derivedData) || (lowercasedInput.contains(UserInputKeywords.xcode) && (lowercasedInput.contains(UserInputKeywords.clean) || lowercasedInput.contains("clear"))) {
            addBotMessage(BotMessages.clearDerivedDataMessage, action: .clearDerivedData)
        } else {
            addBotMessage(BotMessages.helpMessage, action: nil)
        }
    }
    
    // MARK: - Add Bot Message
    private func addBotMessage(_ text: String, action: ChatMessage.BotAction?) {
        let botMessage = ChatMessage(text: text, isUser: false, timestamp: Date(), action: action)
        messages.append(botMessage)
        
        if let action = action {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                handleBotAction(action)
            }
        }
    }
    
    // MARK: - Handle Bot Action
    private func handleBotAction(_ action: ChatMessage.BotAction) {
        Task {
            switch action {
            case .scanDesktop:
                await scanDirectory(getDesktopURL())
            case .scanDownloads:
                await scanDirectory(getDownloadsURL())
            case .scanDocuments:
                await scanDirectory(getDocumentsURL())
            case .cleanAll:
                if let results = scanResults {
                    selectedActions = Set(results.suggestedActions.map { $0.id })
                    showingActionPreview = true
                }
            case .showResults:
                showingResults = true
            case .clearDerivedData:
                clearDerivedData()
            }
        }
    }
    
    // MARK: - Scan Directory
    private func scanDirectory(_ directory: URL) async {
        let results = await fileScanner.scanDirectories([directory])
        
        await MainActor.run {
            scanResults = results
            showScanResults(results)
        }
    }
    
    // MARK: - Show Scan Results
    private func showScanResults(_ results: ScanResults) {
        let fileCount = results.totalFiles
        let totalSize = results.formattedTotalSize
        let actionCount = results.suggestedActions.count
        
        var message = String(format: BotMessages.foundFilesMessage, fileCount, totalSize)
        
        if actionCount > 0 {
            message += String(format: BotMessages.suggestActionsMessage, actionCount)
            addBotMessage(message, action: .showResults)
        } else {
            message += BotMessages.alreadyOrganizedMessage
            addBotMessage(message, action: nil)
        }
    }
    
    // MARK: - Execute Selected Actions
    private func executeSelectedActions() {
        guard let results = scanResults else { return }
        
        let actions = results.suggestedActions.filter { selectedActions.contains($0.id) }
        
        Task {
            let success = await fileOperations.executeActions(actions)
            
            await MainActor.run {
                if success {
                    addBotMessage(BotMessages.cleanupSuccessMessage, action: nil)
                } else {
                    addBotMessage(BotMessages.cleanupErrorMessage, action: nil)
                }
            }
        }
    }
    
    // MARK: - Clear Derived Data (Xcode Cleaner)
    private func clearDerivedData() {
        Task {
            let freed = await xcodeCleaner.clearDerivedData()
            await MainActor.run {
                if let bytes = freed, bytes > 0 {
                    addBotMessage(String(format: XcodeCleanerText.successMessage, xcodeCleaner.formattedBytes(bytes)), action: nil)
                } else if xcodeCleaner.lastError != nil {
                    addBotMessage(String(format: XcodeCleanerText.errorMessage, xcodeCleaner.lastError ?? "Unknown error"), action: nil)
                }
                // If nil and no error, user cancelled—no message needed
            }
        }
    }
    
    // MARK: - Add Welcome Message
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            text: AppConstants.appTagline,
            isUser: false,
            timestamp: Date(),
            action: nil
        )
        messages.append(welcomeMessage)
    }
    
    // MARK: - Get Directory URLs
    private func getDesktopURL() -> URL {
        fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
    }
    
    private func getDownloadsURL() -> URL {
        fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }
    
    private func getDocumentsURL() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// MARK: - Quick Chip
struct QuickChip: View {
    let title: String
    let icon: String
    var accentColor: Color = AppTheme.primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accentColor.opacity(0.12))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: BotAssistantView.ChatMessage
    let onAction: (BotAssistantView.ChatMessage.BotAction) -> Void
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userBubble
            } else {
                botBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        Text(message.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.userBubbleGradient)
            .foregroundColor(.white)
            .cornerRadius(18)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("You")
            .accessibilityValue(message.text)
    }
    
    private var botBubble: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.cardBackground)
                .foregroundColor(.primary)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.borderLight, lineWidth: 1)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Assistant")
                .accessibilityValue(message.text)
            
            if let action = message.action {
                actionButton(for: action)
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func actionButton(for action: BotAssistantView.ChatMessage.BotAction) -> some View {
        Button(action: { onAction(action) }) {
            HStack(spacing: 6) {
                Image(systemName: iconForAction(action))
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text(textForAction(action))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.primary.opacity(0.15))
            .foregroundColor(AppTheme.primaryDark)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(textForAction(action))
        .accessibilityHint(accessibilityHintForAction(action))
    }

    private func accessibilityHintForAction(_ action: BotAssistantView.ChatMessage.BotAction) -> String {
        switch action {
        case .scanDesktop:
            return "Scans your Desktop for files to organize."
        case .scanDownloads:
            return "Scans your Downloads for files to organize."
        case .scanDocuments:
            return "Scans your Documents for files to organize."
        case .cleanAll:
            return "Reviews and cleans up suggested items."
        case .showResults:
            return "Shows details of the scan results."
        case .clearDerivedData:
            return "Clears Xcode Derived Data to free disk space."
        }
    }
    
    private func iconForAction(_ action: BotAssistantView.ChatMessage.BotAction) -> String {
        switch action {
        case .scanDesktop, .scanDownloads, .scanDocuments:
            return SystemIcons.magnifyingglass
        case .cleanAll:
            return SystemIcons.checkmarkCircle
        case .showResults:
            return SystemIcons.listBullet
        case .clearDerivedData:
            return SystemIcons.hammer
        }
    }
    
    private func textForAction(_ action: BotAssistantView.ChatMessage.BotAction) -> String {
        switch action {
        case .scanDesktop:
            return ActionButtonLabels.scanDesktop
        case .scanDownloads:
            return ActionButtonLabels.scanDownloads
        case .scanDocuments:
            return ActionButtonLabels.scanDocuments
        case .cleanAll:
            return ActionButtonLabels.cleanAll
        case .showResults:
            return ActionButtonLabels.viewResults
        case .clearDerivedData:
            return ActionButtonLabels.clearDerivedData
        }
    }
}

