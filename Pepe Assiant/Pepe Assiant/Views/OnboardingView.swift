import SwiftUI
import AppKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var selectedStep: Step? = .welcome

    enum Step: String, CaseIterable, Identifiable {
        case welcome = "Welcome"
        case scan = "Scan a folder"
        case review = "Review results"
        case clean = "Clean up"
        case extras = "Extras"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .welcome: return "sparkles"
            case .scan: return "folder"
            case .review: return "list.bullet.rectangle"
            case .clean: return "checkmark.seal"
            case .extras: return "wand.and.stars"
            }
        }
    }

    var body: some View {
        NavigationView {
            List(Step.allCases, selection: $selectedStep) { step in
                Label(step.rawValue, systemImage: step.icon)
                    .tag(step as Step?)
            }
            .listStyle(.sidebar)
            // Keep the sidebar from expanding and stealing space from the tutorial content.
            .frame(minWidth: 220, idealWidth: 240, maxWidth: 260, maxHeight: .infinity)
            .layoutPriority(0)

            detail(for: currentStep)
                // Make the tutorial panel fill the remaining space (avoid a large "empty" region).
                .frame(minWidth: 520, idealWidth: 660, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .layoutPriority(1)
                .background(AppTheme.surface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 820, idealWidth: 920, maxWidth: .infinity,
               minHeight: 560, idealHeight: 620, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip") { complete() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(currentStep == Step.allCases.last ? "Get Started" : "Next") {
                    goNextOrComplete()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
            }
        }
    }

    private func detail(for step: Step) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(step)
                Divider()

                switch step {
                case .welcome:
                    welcomeBody
                case .scan:
                    scanBody
                case .review:
                    reviewBody
                case .clean:
                    cleanBody
                case .extras:
                    extrasBody
                }

                Spacer(minLength: 24)

                HStack {
                    Button("Back") { goBack() }
                        .disabled(step == .welcome)

                    Spacer()

                    Button(step == Step.allCases.last ? "Get Started" : "Next") {
                        goNextOrComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func header(_ step: Step) -> some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.appName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(step.rawValue)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var welcomeBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome to \(AppConstants.appName)")
                .font(.title)
                .fontWeight(.bold)

            Text("NeatOS helps you scan common folders, spot clutter (duplicates, old files, large files), and safely clean up with a review step and undo.")
                .foregroundColor(.secondary)

            tutorialCard(
                title: "What you can do",
                items: [
                    "Scan Desktop / Downloads / Documents",
                    "Review large files, duplicates, and old files",
                    "Preview suggested actions before applying them",
                    "Undo recent operations if you change your mind"
                ]
            )
        }
    }

    private var scanBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            tutorialCard(
                title: "Start a scan",
                items: [
                    "Use the Quick Actions chips at the bottom (Desktop, Downloads, Documents).",
                    "Or type a request like “clean my desktop” or “scan downloads”.",
                    "macOS will ask for permission the first time you scan a folder—choose the folder when prompted."
                ]
            )

            tutorialCard(
                title: "Tip",
                items: [
                    "Press ⌘⏎ to send your message."
                ]
            )
        }
    }

    private var reviewBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            tutorialCard(
                title: "View results",
                items: [
                    "After a scan, choose “View Results” to open the results sheet.",
                    "Use categories at the top to filter file types.",
                    "Sort the file list to find the biggest items first.",
                    "Use the “Large files detected” banner to quickly review heavy files."
                ]
            )
        }
    }

    private var cleanBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            tutorialCard(
                title: "Clean up safely",
                items: [
                    "NeatOS suggests actions but won’t run anything without your confirmation.",
                    "Review suggested actions, deselect anything you don’t want, then execute.",
                    "Use Undo in the header to revert recent operations."
                ]
            )
        }
    }

    private var extrasBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            tutorialCard(
                title: "Extras",
                items: [
                    "Clear Xcode Derived Data to free space (you’ll be prompted to select the DerivedData folder).",
                    "You can reopen this tutorial anytime from the NeatOS menu."
                ]
            )
        }
    }

    private func tutorialCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { idx in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.primaryDark)
                            .accessibilityHidden(true)
                        Text(items[idx])
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.borderLight, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var currentStep: Step {
        selectedStep ?? .welcome
    }

    private func goBack() {
        let current = currentStep
        guard let idx = Step.allCases.firstIndex(of: current), idx > 0 else { return }
        selectedStep = Step.allCases[idx - 1]
    }

    private func goNextOrComplete() {
        let current = currentStep
        guard let idx = Step.allCases.firstIndex(of: current) else { return }
        if idx + 1 < Step.allCases.count {
            selectedStep = Step.allCases[idx + 1]
        } else {
            complete()
        }
    }

    private func complete() {
        onComplete()
        isPresented = false
    }
}

