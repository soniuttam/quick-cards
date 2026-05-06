import SwiftUI
import WidgetKit

struct QuickCaptureView: View {
    @Environment(\.openWindow) private var openWindow

    let store: NoteStore
    let stopwatch: StopwatchStore
    @State private var draft = AttributedString()
    @AppStorage("quickPopupWidth") private var popupWidth = 410.0
    @AppStorage("quickPopupHeight") private var popupHeight = 560.0
    @State private var resizeStartWidth = 410.0
    @State private var resizeStartHeight = 560.0
    @State private var isResizing = false

    private let minPopupWidth = 360.0
    private let minPopupHeight = 460.0
    private let maxPopupWidth = 760.0
    private let maxPopupHeight = 920.0

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 12) {
                header
                editor
                addButton
                recentNotes
            }
            .padding(16)
        }
        .overlay(WindowChromeConfigurator(isResizable: true).frame(width: 0, height: 0))
        .overlay(alignment: .bottomTrailing) {
            resizeHandle
                .padding(8)
        }
        .frame(width: clampedPopupWidth, height: clampedPopupHeight)
        .onAppear {
            popupWidth = clampedPopupWidth
            popupHeight = clampedPopupHeight
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Label("Quick Cards", systemImage: "checklist")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            Spacer()

            StopwatchHeaderControls(stopwatch: stopwatch)

            GlassIconButton(systemName: "arrow.up.left.and.arrow.down.right", help: "Expand") {
                openWindow(id: AppConstants.notesWindowID)
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("o", modifiers: [.command])
        }
    }

    private var editor: some View {
        SoftPanel {
            RichNoteEditor(text: $draft, placeholder: "")
                .padding(10)
        }
        .frame(height: 188)
    }

    private var addButton: some View {
        Button {
            guard store.addNote(body: draft) != nil else { return }
            draft = AttributedString()
            reloadControlsIfAvailable()
        } label: {
            Label("Add Card", systemImage: "plus")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
        .disabled(draft.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(draft.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        .keyboardShortcut(.return, modifiers: [.command])
    }

    private var recentNotes: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cards")
                    .font(.headline)
                Spacer()
                Text("\(store.notes.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if store.notes.isEmpty {
                SoftPanel {
                    Text("No cards yet")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 96)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.notes) { note in
                            CompactNoteRow(note: note, store: store)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func reloadControlsIfAvailable() {
        if #available(macOS 26.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
    }

    private var resizeHandle: some View {
        PopupResizeHandle()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isResizing {
                            resizeStartWidth = clampedPopupWidth
                            resizeStartHeight = clampedPopupHeight
                            isResizing = true
                        }

                        popupWidth = clamp(
                            resizeStartWidth + Double(value.translation.width),
                            min: minPopupWidth,
                            max: maxPopupWidth
                        )
                        popupHeight = clamp(
                            resizeStartHeight + Double(value.translation.height),
                            min: minPopupHeight,
                            max: maxPopupHeight
                        )
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
    }

    private var clampedPopupWidth: Double {
        clamp(popupWidth, min: minPopupWidth, max: maxPopupWidth)
    }

    private var clampedPopupHeight: Double {
        clamp(popupHeight, min: minPopupHeight, max: maxPopupHeight)
    }

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}

private struct PopupResizeHandle: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(.secondary.opacity(0.56))
                    .frame(width: CGFloat(9 + index * 6), height: 1.4)
                    .rotationEffect(.degrees(-45))
                    .offset(x: CGFloat(index * -3), y: CGFloat(index * -3))
            }
        }
        .frame(width: 30, height: 30)
        .contentShape(Rectangle())
        .help("Resize")
    }
}

private struct CompactNoteRow: View {
    let note: NoteCard
    let store: NoteStore
    @State private var draft: AttributedString
    @State private var isEditing = false

    init(note: NoteCard, store: NoteStore) {
        self.note = note
        self.store = store
        _draft = State(initialValue: note.body)
    }

    var body: some View {
        SoftPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        store.toggleDone(noteID: note.id)
                    } label: {
                        Image(systemName: note.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .buttonStyle(.borderless)
                    .help(note.isDone ? "Mark open" : "Mark done")

                    Spacer(minLength: 0)

                    GlassIconButton(systemName: isEditing ? "checkmark" : "pencil", help: isEditing ? "Done editing" : "Edit") {
                        isEditing.toggle()
                    }

                    Button(role: .destructive) {
                        store.delete(noteID: note.id)
                        reloadControlsIfAvailable()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }

                if isEditing {
                    RichNoteEditor(text: $draft, placeholder: "")
                        .frame(minHeight: 150)
                        .onChange(of: draft) { _, newValue in
                            store.update(noteID: note.id, body: newValue)
                        }
                        .onChange(of: note.body) { _, newValue in
                            if draft != newValue {
                                draft = newValue
                            }
                        }
                } else {
                    NoteLinesPreview(note: note, store: store)
                        .opacity(note.isDone ? 0.68 : 1)
                        .onChange(of: note.body) { _, newValue in
                            if draft != newValue {
                                draft = newValue
                            }
                        }
                }
            }
            .padding(12)
        }
    }

    private func reloadControlsIfAvailable() {
        if #available(macOS 26.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
    }
}
