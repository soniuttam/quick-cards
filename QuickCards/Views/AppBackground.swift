import AppKit
import SwiftUI

struct AppBackground: View {
    var body: some View {
        VisualEffectBackground(material: .underWindowBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(liquidBorder, lineWidth: 1.15)
                    .padding(0.5)
            }
            .overlay(WindowChromeConfigurator().frame(width: 0, height: 0))
            .ignoresSafeArea()
    }

    private var liquidBorder: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.82),
                .white.opacity(0.18),
                .black.opacity(0.10),
                .white.opacity(0.64)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.state = .active
    }
}

struct WindowChromeConfigurator: NSViewRepresentable {
    var isResizable = false

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true

            if isResizable {
                window.styleMask.insert(.resizable)
                window.minSize = NSSize(width: 360, height: 460)
                window.maxSize = NSSize(width: 760, height: 920)
            }
        }
    }
}

struct SoftPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(reflectiveBorder, lineWidth: 1)
            }
    }

    private var reflectiveBorder: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.72),
                .white.opacity(0.08),
                .black.opacity(0.06),
                .white.opacity(0.52)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GlassIconButton: View {
    let systemName: String
    let help: String
    var keyEquivalent: KeyEquivalent?
    var modifiers: EventModifiers = []
    let action: () -> Void

    var body: some View {
        if let keyEquivalent {
            button
                .keyboardShortcut(keyEquivalent, modifiers: modifiers)
        } else {
            button
        }
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

struct StopwatchHeaderControls: View {
    let stopwatch: StopwatchStore

    var body: some View {
        HStack(spacing: 4) {
            if stopwatch.isRunning {
                Text(stopwatch.formattedElapsed)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            GlassIconButton(
                systemName: stopwatch.isRunning ? "pause.fill" : "timer",
                help: stopwatch.isRunning ? "Pause timer" : "Start timer"
            ) {
                stopwatch.startPause()
            }

            if stopwatch.elapsedTime > 0 {
                GlassIconButton(systemName: "arrow.counterclockwise", help: "Reset timer") {
                    stopwatch.reset()
                }
            }
        }
    }
}

struct RichNoteEditor: View {
    @Binding var text: AttributedString
    let placeholder: String

    @State private var selection = AttributedTextSelection()

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                GlassIconButton(systemName: "bold", help: "Bold (Command-B)", keyEquivalent: "b", modifiers: .command) {
                    toggleIntent(.stronglyEmphasized)
                }

                GlassIconButton(systemName: "italic", help: "Italic (Command-I)", keyEquivalent: "i", modifiers: .command) {
                    toggleIntent(.emphasized)
                }

                GlassIconButton(systemName: "textformat", help: "Normal (Command-Option-0)", keyEquivalent: "0", modifiers: [.command, .option]) {
                    clearPresentationIntent()
                }

                GlassIconButton(systemName: "doc.on.clipboard", help: "Paste") {
                    pasteFromClipboard()
                }

                GlassIconButton(systemName: "doc.on.doc", help: "Copy") {
                    copyToClipboard()
                }

                Spacer()
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text, selection: $selection)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.black)
                    .tint(.black)
                    .scrollContentBackground(.hidden)
                    .padding(8)

                if text.plainText.isEmpty, !placeholder.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.black.opacity(0.54))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func toggleIntent(_ intent: InlinePresentationIntent) {
        switch selection.indices(in: text) {
        case .ranges(let ranges) where !ranges.isEmpty:
            text.transformAttributes(in: &selection) { attributes in
                toggle(intent, in: &attributes)
            }
        default:
            var attributes = AttributeContainer()
            toggle(intent, in: &attributes)
            text.setAttributes(attributes)
        }
    }

    private func clearPresentationIntent() {
        switch selection.indices(in: text) {
        case .ranges(let ranges) where !ranges.isEmpty:
            text.transformAttributes(in: &selection) { attributes in
                attributes.inlinePresentationIntent = nil
            }
        default:
            var attributes = AttributeContainer()
            attributes.inlinePresentationIntent = nil
            text.setAttributes(attributes)
        }
    }

    private func toggle(_ intent: InlinePresentationIntent, in attributes: inout AttributeContainer) {
        var intents = attributes.inlinePresentationIntent ?? []
        if intents.contains(intent) {
            intents.remove(intent)
        } else {
            intents.insert(intent)
        }

        attributes.inlinePresentationIntent = intents.isEmpty ? nil : intents
    }

    private func pasteFromClipboard() {
        guard let value = NSPasteboard.general.string(forType: .string), !value.isEmpty else { return }
        text.replaceSelection(&selection, with: AttributedString(value))
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text.plainText, forType: .string)
    }
}

struct StopwatchPanel: View {
    let stopwatch: StopwatchStore
    var compact = false

    var body: some View {
        SoftPanel {
            HStack(spacing: compact ? 8 : 12) {
                Image(systemName: stopwatch.isRunning ? "timer" : "stopwatch")
                    .font(.system(size: compact ? 13 : 16, weight: .semibold))

                Text(stopwatch.formattedElapsed)
                    .font(.system(size: compact ? 14 : 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Spacer(minLength: 4)

                GlassIconButton(
                    systemName: stopwatch.isRunning ? "pause.fill" : "play.fill",
                    help: stopwatch.isRunning ? "Pause" : "Start"
                ) {
                    stopwatch.startPause()
                }

                GlassIconButton(systemName: "arrow.counterclockwise", help: "Reset") {
                    stopwatch.reset()
                }
            }
            .padding(compact ? 10 : 12)
        }
    }
}

struct NoteLinesPreview: View {
    let note: NoteCard
    let store: NoteStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.titleText)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .strikethrough(note.isDone)
                .foregroundStyle(note.isDone ? .secondary : .primary)

            ForEach(note.detailLineItems) { line in
                if line.isBlank {
                    Text(" ")
                        .font(.system(size: 14, design: .rounded))
                        .frame(height: 4)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Button {
                            store.toggleLineDone(noteID: note.id, lineIndex: line.index)
                        } label: {
                            Image(systemName: note.checkedLineIndexes.contains(line.index) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .help("Mark line done")

                        Text(line.text)
                            .font(.system(size: 14, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                            .strikethrough(note.checkedLineIndexes.contains(line.index))
                            .foregroundStyle(note.checkedLineIndexes.contains(line.index) ? .secondary : .primary)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}
