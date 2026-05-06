import AppKit
import SwiftUI

struct NotesWindowView: View {
    @Environment(\.openWindow) private var openWindow

    let store: NoteStore
    let stopwatch: StopwatchStore

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 14)
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 14) {
                header
                content
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 720, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Cards")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("\(store.activeNotes.count) open  \(store.completedNotes.count) done")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            GlassIconButton(systemName: "note.text.badge.plus", help: "Quick Note") {
                openWindow(id: AppConstants.quickCaptureWindowID)
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("n", modifiers: [.command])

            StopwatchHeaderControls(stopwatch: stopwatch)

            GlassIconButton(systemName: "arrow.up.left.and.arrow.down.right", help: "Full Screen") {
                NSApp.keyWindow?.toggleFullScreen(nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .control])
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.notes.isEmpty {
            SoftPanel {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("No cards yet")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(store.notes) { note in
                        EditableNoteCard(note: note, store: store)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct EditableNoteCard: View {
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button {
                        store.toggleDone(noteID: note.id)
                    } label: {
                        Image(systemName: note.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .buttonStyle(.borderless)
                    .help(note.isDone ? "Mark open" : "Mark done")

                    Spacer()

                    GlassIconButton(systemName: isEditing ? "checkmark" : "pencil", help: isEditing ? "Done editing" : "Edit") {
                        isEditing.toggle()
                    }

                    GlassIconButton(systemName: "doc.on.doc", help: "Copy") {
                        copyNote()
                    }

                    Button(role: .destructive) {
                        store.delete(noteID: note.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }

                if isEditing {
                    RichNoteEditor(text: $draft, placeholder: "")
                        .frame(minHeight: 180)
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .onChange(of: note.body) { _, newValue in
                            if draft != newValue {
                                draft = newValue
                            }
                        }
                    }
            }
            .padding(14)
        }
    }

    private func copyNote() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.plainBody, forType: .string)
    }
}
