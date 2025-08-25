import SwiftUI
import Foundation

struct BotAssistantView: View {
    @StateObject private var fileScanner = FileScanner()
    @StateObject private var fileOperations = FileOperations()
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
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Chat Area
            chatArea
            
            // Input Area
            inputArea
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            addWelcomeMessage()
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
                oldFiles: [],
                largeFiles: [],
                suggestedActions: []
            ))
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Image(systemName: SystemIcons.sparkles)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(AppConstants.appName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(AppConstants.appDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if fileOperations.canUndo {
                Button("\(UIText.undo) (\(fileOperations.undoCount))") {
                    Task {
                        await fileOperations.undoLastAction()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UIText.pepeAssistantHeader)
    }
    
    // MARK: - Chat Area
    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message) { action in
                            handleBotAction(action)
                        }
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
            .onChange(of: messages.count) { _, _ in
                withAnimation {
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
                Text("\(UIText.scanning) \(fileScanner.currentScanLocation)...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: fileScanner.scanProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 4)
        }
        .padding()
        .background(Color(.darkGray))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(UIText.scanningProgress): \(Int(fileScanner.scanProgress * 100))% \(UIText.complete)")
    }
    
    // MARK: - Processing Progress View
    private var processingProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text(fileOperations.currentOperation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: fileOperations.processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 4)
        }
        .padding()
        .background(Color(.darkGray))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(UIText.processingProgress): \(Int(fileOperations.processingProgress * 100))% \(UIText.complete)")
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField(UIText.messageInputPlaceholder, text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    sendMessage()
                }
                .accessibilityLabel(UIText.messageInputField)
            
            Button(action: sendMessage) {
                Image(systemName: SystemIcons.arrowUpCircleFill)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(UIText.sendMessage)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
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
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(18)
            .cornerRadius(4)
    }
    
    private var botBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.text)
                .padding()
                .background(Color(.darkGray).opacity(0.4))
                .foregroundColor(.primary)
                .cornerRadius(18)
                .cornerRadius(4)
            
            if let action = message.action {
                actionButton(for: action)
            }
        }
    }
    
    private func actionButton(for action: BotAssistantView.ChatMessage.BotAction) -> some View {
        Button(action: { onAction(action) }) {
            HStack {
                Image(systemName: iconForAction(action))
                Text(textForAction(action))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(textForAction(action))
    }
    
    private func iconForAction(_ action: BotAssistantView.ChatMessage.BotAction) -> String {
        switch action {
        case .scanDesktop, .scanDownloads, .scanDocuments:
            return SystemIcons.magnifyingglass
        case .cleanAll:
            return SystemIcons.checkmarkCircle
        case .showResults:
            return SystemIcons.listBullet
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
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner)
//    }
}

//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
////    var corners: UIRectCorner = .allCorners
//    var corners =
//
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        return Path(path.cgPath)
//    }
//} 
