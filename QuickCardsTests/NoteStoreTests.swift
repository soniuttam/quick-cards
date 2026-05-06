import XCTest
@testable import QuickCards

@MainActor
final class NoteStoreTests: XCTestCase {
    func testAddNoteRejectsBlankText() {
        let store = makeStore()

        XCTAssertNil(store.addNote(body: "   \n  "))
        XCTAssertTrue(store.notes.isEmpty)
    }

    func testAddNotePersistsTrimmedText() {
        let store = makeStore()

        let note = store.addNote(body: "  Book flight tickets  ")

        XCTAssertEqual(note?.plainBody, "Book flight tickets")
        XCTAssertEqual(store.notes.map(\.plainBody), ["Book flight tickets"])
    }

    func testUpdateNotePersistsEditedBody() {
        let store = makeStore()
        let note = store.addNote(body: "Draft")!

        store.update(noteID: note.id, body: "Edited")

        XCTAssertEqual(store.notes.first?.plainBody, "Edited")
    }

    func testFirstLineIsCardTitle() {
        let store = makeStore()
        store.addNote(body: "Trip plan\nBook flights\nPack bag")

        XCTAssertEqual(store.notes.first?.titleText, "Trip plan")
        XCTAssertEqual(store.notes.first?.detailLineItems.map(\.plainText), ["Book flights", "Pack bag"])
    }

    func testToggleDone() {
        let store = makeStore()
        let note = store.addNote(body: "Send invoice")!

        store.toggleDone(noteID: note.id)

        XCTAssertEqual(store.notes.first?.isDone, true)
        XCTAssertEqual(store.notes.first?.checkedLineIndexes, Set([0]))
        XCTAssertEqual(store.completedNotes.count, 1)
    }

    func testToggleLineDoneMarksSingleLine() {
        let store = makeStore()
        let note = store.addNote(body: "Book flights\nPack bag")!

        store.toggleLineDone(noteID: note.id, lineIndex: 1)

        XCTAssertEqual(store.notes.first?.checkedLineIndexes, Set([1]))
        XCTAssertEqual(store.notes.first?.isDone, false)
    }

    func testToggleAllLinesDoneMarksCardDone() {
        let store = makeStore()
        let note = store.addNote(body: "Book flights\nPack bag")!

        store.toggleLineDone(noteID: note.id, lineIndex: 0)
        store.toggleLineDone(noteID: note.id, lineIndex: 1)

        XCTAssertEqual(store.notes.first?.checkedLineIndexes, Set([0, 1]))
        XCTAssertEqual(store.notes.first?.isDone, true)
    }

    func testDeleteNote() {
        let store = makeStore()
        let note = store.addNote(body: "Delete me")!

        store.delete(noteID: note.id)

        XCTAssertTrue(store.notes.isEmpty)
    }

    func testLoadsSavedNotes() {
        let storageURL = temporaryStorageURL()
        let store = NoteStore(storageURL: storageURL, loadsImmediately: false)
        store.addNote(body: "Remember this")

        let reloadedStore = NoteStore(storageURL: storageURL)

        XCTAssertEqual(reloadedStore.notes.map(\.plainBody), ["Remember this"])
    }

    func testCorruptedStoreRecoversEmpty() throws {
        let storageURL = temporaryStorageURL()
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: storageURL)

        let store = NoteStore(storageURL: storageURL)

        XCTAssertTrue(store.notes.isEmpty)
        XCTAssertNotNil(store.loadErrorMessage)
    }

    private func makeStore() -> NoteStore {
        NoteStore(storageURL: temporaryStorageURL(), loadsImmediately: false)
    }

    private func temporaryStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("notes.json")
    }
}
