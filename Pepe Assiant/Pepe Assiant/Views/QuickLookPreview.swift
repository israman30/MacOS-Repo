import SwiftUI
import QuickLookUI
import UniformTypeIdentifiers
import PDFKit

struct QuickLookPreview: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> QLPreviewView {
        guard let view = QLPreviewView(frame: .zero, style: .normal) else {
            // Return a default (empty) QLPreviewView if failed to create
            return QLPreviewView()
        }
        view.autostarts = true
        view.previewItem = PreviewItem(url: url)
        return view
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        // Always attempt to preview. If sandbox denies access, Quick Look will show its own "no preview" UI.
        nsView.previewItem = PreviewItem(url: url)
    }
}

private final class PreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?
    
    init(url: URL) {
        self.previewItemURL = url
        self.previewItemTitle = url.lastPathComponent
        super.init()
    }
}

/// Wrapper that is safe in Xcode Previews and still shows rich previews at runtime.
struct FilePreviewPane: View {
    let url: URL
    private let XCODE_RUNNING_FOR_PREVIEWS = "XCODE_RUNNING_FOR_PREVIEWS"
    
    var body: some View {
        if isRunningForPreviews {
            LightweightFilePreview(url: url)
        } else {
            QuickLookPreview(url: url)
        }
    }
    
    private var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment[XCODE_RUNNING_FOR_PREVIEWS] == "1"
    }
}

/// Lightweight renderer used for Xcode Previews (avoids QuickLookUI crashes in the preview process).
private struct LightweightFilePreview: View {
    let url: URL
    
    var body: some View {
        Group {
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.surface)
            } else if isPDF(url) {
                PDFPreview(url: url)
            } else if let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.surface)
            } else {
                fallback
            }
        }
    }
    
    private func isPDF(_ url: URL) -> Bool {
        if url.pathExtension.lowercased() == "pdf" {
            return true
        }
        if let type = UTType(filenameExtension: url.pathExtension), type.conforms(to: .pdf) {
            return true
        }
        return false
    }
    
    private var fallback: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text(url.lastPathComponent.isEmpty ? "No selection" : url.lastPathComponent)
                .font(.headline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(UIText.run_the_app_for_full_quick_look_preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surface)
    }
}

private struct PDFPreview: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let v = PDFView(frame: .zero)
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displaysPageBreaks = true
        v.document = PDFDocument(url: url)
        return v
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}
