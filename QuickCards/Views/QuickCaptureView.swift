import SwiftUI
import WidgetKit

struct QuickCaptureView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme

    let store: NoteStore
    let stopwatch: StopwatchStore
    @State private var draft = AttributedString()

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
        .frame(
            minWidth: minPopupWidth,
            idealWidth: 410,
            maxWidth: maxPopupWidth,
            minHeight: minPopupHeight,
            idealHeight: 560,
            maxHeight: maxPopupHeight
        )
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
        .foregroundStyle(primaryButtonForeground)
        .background(primaryButtonWash, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .glassEffect(.regular.tint(primaryButtonTint).interactive(), in: .rect(cornerRadius: 10))
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

    private var primaryButtonTint: Color {
        primaryButtonColor.opacity(colorScheme == .dark ? 0.48 : 0.44)
    }

    private var primaryButtonWash: Color {
        primaryButtonColor.opacity(colorScheme == .dark ? 0.82 : 0.86)
    }

    private var primaryButtonForeground: Color {
        .white
    }

    private var primaryButtonColor: Color {
        colorScheme == .dark ? Color(red: 0.0, green: 0.64, blue: 1.0) : Color(red: 1.0, green: 0.22, blue: 0.36)
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
