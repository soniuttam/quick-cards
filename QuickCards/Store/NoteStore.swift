import Foundation
import Observation

@MainActor
@Observable
final class NoteStore {
    private(set) var notes: [NoteCard] = []
    private(set) var loadErrorMessage: String?

    @ObservationIgnored private let storageURL: URL
    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let encoder: JSONEncoder
    @ObservationIgnored private let decoder: JSONDecoder

    init(
        storageURL: URL? = nil,
        fileManager: FileManager = .default,
        loadsImmediately: Bool = true
    ) {
        self.fileManager = fileManager
        self.storageURL = storageURL ?? Self.defaultStorageURL(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        if loadsImmediately {
            load()
        }
    }

    var activeNotes: [NoteCard] {
        notes.filter { !$0.isDone }
    }

    var completedNotes: [NoteCard] {
        notes.filter(\.isDone)
    }

    @discardableResult
    func addNote(body: String) -> NoteCard? {
        let cleanedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedBody.isEmpty else { return nil }

        return addNote(body: AttributedString(cleanedBody))
    }

    @discardableResult
    func addNote(body: AttributedString) -> NoteCard? {
        let cleanedBody = body.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedBody.isEmpty else { return nil }

        let now = Date()
        let note = NoteCard(body: body, createdAt: now, updatedAt: now).normalizedLineState
        notes.insert(note, at: 0)
        save()
        return note
    }

    func update(noteID: NoteCard.ID, body: String) {
        update(noteID: noteID, body: AttributedString(body))
    }

    func update(noteID: NoteCard.ID, body: AttributedString) {
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard notes[index].body != body else { return }

        notes[index].body = body
        notes[index].updatedAt = Date()
        notes[index] = notes[index].normalizedLineState
        save()
    }

    func toggleDone(noteID: NoteCard.ID) {
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }

        let lineIndexes = notes[index].completableLineIndexes
        if notes[index].isDone {
            notes[index].checkedLineIndexes.removeAll()
            notes[index].isDone = false
        } else {
            notes[index].checkedLineIndexes = lineIndexes
            notes[index].isDone = !lineIndexes.isEmpty
        }
        notes[index].updatedAt = Date()
        save()
    }

    func toggleLineDone(noteID: NoteCard.ID, lineIndex: Int) {
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard notes[index].completableLineIndexes.contains(lineIndex) else { return }

        if notes[index].checkedLineIndexes.contains(lineIndex) {
            notes[index].checkedLineIndexes.remove(lineIndex)
        } else {
            notes[index].checkedLineIndexes.insert(lineIndex)
        }

        notes[index].updatedAt = Date()
        notes[index] = notes[index].normalizedLineState
        save()
    }

    func delete(noteID: NoteCard.ID) {
        notes.removeAll { $0.id == noteID }
        save()
    }

    func load() {
        loadErrorMessage = nil

        guard fileManager.fileExists(atPath: storageURL.path) else {
            notes = []
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            notes = try decoder.decode([NoteCard].self, from: data)
                .map(\.normalizedLineState)
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            notes = []
            loadErrorMessage = "Notes were reset because the local store could not be read."
        }
    }

    func save() {
        do {
            try fileManager.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let data = try encoder.encode(notes)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            loadErrorMessage = "Notes could not be saved."
        }
    }

    private static func defaultStorageURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return baseURL
            .appendingPathComponent("Quick Cards", isDirectory: true)
            .appendingPathComponent("notes.json")
    }
}

@MainActor
@Observable
final class StopwatchStore {
    private var accumulatedTime: TimeInterval = 0
    private var startedAt: Date?
    private var tickDate = Date()

    @ObservationIgnored private var timer: Timer?

    var isRunning: Bool {
        startedAt != nil
    }

    var elapsedTime: TimeInterval {
        accumulatedTime + (startedAt.map { tickDate.timeIntervalSince($0) } ?? 0)
    }

    var formattedElapsed: String {
        Self.format(elapsedTime)
    }

    func startPause() {
        isRunning ? pause() : start()
    }

    func start() {
        guard startedAt == nil else { return }
        startedAt = Date()
        tickDate = Date()
        scheduleTimer()
    }

    func pause() {
        guard let startedAt else { return }
        accumulatedTime += Date().timeIntervalSince(startedAt)
        self.startedAt = nil
        tickDate = Date()
        invalidateTimer()
    }

    func reset() {
        accumulatedTime = 0
        startedAt = nil
        tickDate = Date()
        invalidateTimer()
    }

    private func scheduleTimer() {
        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickDate = Date()
            }
        }
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.down)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
