# TrelloClient

A lightweight Swift package for interacting with the Trello REST API.

Built for macOS 13+, fully async/await, no third-party dependencies.

---

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pabelsaldivar/TrelloCreatorContentKit", from: "1.0.0"),
],
```

Then add `TrelloClient` as a dependency of your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "TrelloClient", package: "TrelloCreatorContentKit"),
    ]
),
```

---

## Requirements

- macOS 13+
- Swift 5.9+
- A Trello account with an API key and user token
  - Get your key and token at: https://trello.com/power-ups/admin

---

## Usage

```swift
import TrelloClient

let client = TrelloAPIClient(apiKey: "YOUR_KEY", apiToken: "YOUR_TOKEN")

// Verify credentials
let member = try await client.fetchCurrentMember()
print(member.fullName ?? member.username ?? "")

// Fetch boards
let boards = try await client.fetchBoards()

// Fetch cards from a list
let cards = try await client.fetchCards(listId: "YOUR_LIST_ID")

// Create a card
let payload = TrelloCardPayload(
    name: "My new card",
    desc: "Card description",
    idList: "TARGET_LIST_ID"
)
let cardId = try await client.createCard(payload)

// Move a card
try await client.moveCard(cardId: cardId, toListId: "ANOTHER_LIST_ID")

// Update a card title
try await client.updateCardTitle(cardId: cardId, newTitle: "Updated title")
```

---

## Error handling

All methods throw `TrelloAPIError`:

```swift
do {
    let cards = try await client.fetchCards(listId: listId)
} catch TrelloAPIError.httpError(let code, let body) {
    print("HTTP \(code): \(body)")
} catch TrelloAPIError.missingCredentials {
    print("Configure your API key and token first.")
} catch {
    print(error.localizedDescription)
}
```

---

## Available methods

| Method | Description |
|--------|-------------|
| `fetchCurrentMember()` | Verifies credentials, returns the authenticated member |
| `fetchBoards()` | Returns all boards accessible to the token |
| `fetchLists(boardId:)` | Returns all lists on a board |
| `fetchLabels(boardId:)` | Returns all labels on a board |
| `fetchCards(listId:)` | Returns all open cards in a list |
| `createCard(_:)` | Creates a new card, returns its ID |
| `updateCardTitle(cardId:newTitle:)` | Renames a card |
| `moveCard(cardId:toListId:)` | Moves a card to a different list |
| `updateCardDueDate(cardId:due:)` | Sets or clears the due date on a card |
| `addComment(cardId:text:)` | Posts a comment on a card |

---

## License

MIT
