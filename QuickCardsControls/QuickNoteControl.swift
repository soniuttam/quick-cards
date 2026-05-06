import AppIntents
import SwiftUI
import WidgetKit

struct QuickNoteControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.uttam.quickcards.quick-note") {
            ControlWidgetButton(action: OpenURLIntent(AppConstants.quickCaptureURL)) {
                Label("Quick Note", systemImage: "note.text.badge.plus")
            }
        }
        .displayName("Quick Note")
        .description("Open Quick Cards.")
    }
}
