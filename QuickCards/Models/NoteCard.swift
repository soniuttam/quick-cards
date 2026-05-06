import Foundation

struct NoteCard: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var body: AttributedString
    var isDone: Bool
    var checkedLineIndexes: Set<Int>
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        body: AttributedString,
        isDone: Bool = false,
        checkedLineIndexes: Set<Int> = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.body = body
        self.isDone = isDone
        self.checkedLineIndexes = checkedLineIndexes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(
        id: UUID = UUID(),
        body: String,
        isDone: Bool = false,
        checkedLineIndexes: Set<Int> = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.init(
            id: id,
            body: AttributedString(body),
            isDone: isDone,
            checkedLineIndexes: checkedLineIndexes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    var plainBody: String {
        String(body.characters)
    }

    var lineItems: [NoteLineItem] {
        body.lineItems
    }

    var titleLine: NoteLineItem? {
        lineItems.first { !$0.isBlank }
    }

    var titleText: String {
        titleLine?.plainText.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
    }

    var detailLineItems: [NoteLineItem] {
        guard let titleLine else { return [] }
        return lineItems.filter { $0.index > titleLine.index }
    }

    var completableLineIndexes: Set<Int> {
        Set(lineItems.filter { !$0.isBlank }.map(\.index))
    }

    var normalizedLineState: NoteCard {
        var copy = self
        let validIndexes = completableLineIndexes
        copy.checkedLineIndexes = checkedLineIndexes.intersection(validIndexes)

        if copy.isDone, copy.checkedLineIndexes.isEmpty, !validIndexes.isEmpty {
            copy.checkedLineIndexes = validIndexes
        }

        copy.isDone = !validIndexes.isEmpty && validIndexes.isSubset(of: copy.checkedLineIndexes)
        return copy
    }
}

struct NoteLineItem: Identifiable, Equatable, Sendable {
    let index: Int
    let text: AttributedString

    var id: Int { index }

    var plainText: String {
        String(text.characters)
    }

    var isBlank: Bool {
        plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension AttributedString {
    var plainText: String {
        String(characters)
    }

    var lineItems: [NoteLineItem] {
        var items: [NoteLineItem] = []
        var lineStart = startIndex
        var lineIndex = 0
        var currentIndex = startIndex

        while currentIndex < endIndex {
            if characters[currentIndex] == "\n" {
                items.append(
                    NoteLineItem(
                        index: lineIndex,
                        text: AttributedString(self[lineStart..<currentIndex])
                    )
                )
                lineIndex += 1
                lineStart = characters.index(after: currentIndex)
            }

            currentIndex = characters.index(after: currentIndex)
        }

        items.append(
            NoteLineItem(
                index: lineIndex,
                text: AttributedString(self[lineStart..<endIndex])
            )
        )

        return items
    }
}
