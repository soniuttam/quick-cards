import SwiftUI

@main
struct QuickCardsApp: App {
    @State private var store = NoteStore()
    @State private var stopwatch = StopwatchStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        Window("Quick Cards", id: AppConstants.notesWindowID) {
            NotesWindowView(store: store, stopwatch: stopwatch)
        }
        .defaultSize(width: 900, height: 640)

        WindowGroup("Quick Note", id: AppConstants.quickCaptureWindowID) {
            QuickCaptureView(store: store, stopwatch: stopwatch)
        }
        .handlesExternalEvents(matching: [AppConstants.quickCaptureWindowID])
        .defaultSize(width: 410, height: 600)

        MenuBarExtra {
            QuickCaptureView(store: store, stopwatch: stopwatch)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: stopwatch.isRunning ? "timer" : "checklist")
                if stopwatch.isRunning {
                    Text(stopwatch.formattedElapsed)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)

        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Quick Note") {
                    openWindow(id: AppConstants.quickCaptureWindowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu("Cards") {
                Button("Show Cards") {
                    openWindow(id: AppConstants.notesWindowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("0", modifiers: [.command])
            }
        }
    }
}
