# Gemini Grapher — Design Spec

A macOS Swift app for iteratively tuning Gemini image generation prompts through conversational interaction with Claude (via vibeproxy).

## Problem

Crafting effective Gemini image prompts requires iterative refinement. Users give fragments of intent across multiple turns ("make it more cinematic", "add rain"), but Gemini needs a single, well-structured prompt. There is no tool that accumulates conversational fragments into a coherent, complete prompt while remembering style preferences.

## Solution

A native macOS app with a three-column layout: session list, chat interface, and live prompt preview. The user converses with Claude to refine prompts incrementally. Claude synthesizes fragments into a complete Gemini image prompt, which updates in real-time in the right panel. The user copies the final prompt and pastes it into Gemini.

## Architecture

```
User ↔ macOS App (SwiftUI) ↔ VibeProxy (localhost:8317) ↔ Claude
                                    ↓
                          Complete Prompt → Copy → Paste into Gemini
```

### Core Components

**LLMClient** — Async HTTP client calling vibeproxy's OpenAI-compatible API (`/v1/chat/completions`). Supports SSE streaming. Configurable base URL and model selection.

**PromptEngine** — Builds the system prompt sent to Claude on each request. Injects:
1. Base instruction (role as Gemini image prompt expert)
2. Global style preferences from memory
3. Per-session feedback from memory
4. Current prompt version (for Claude to modify incrementally)

**SessionManager** — SwiftData-backed project-based sessions. Each session has a name, conversation history, and prompt version history.

**MemoryStore** — Manages two types of memory stored as Markdown files on disk:
- Style Preferences (long-term): global rules like "prefer cinematic lighting"
- Session Feedback (short-term): per-session notes like "last version was too dark"

## UI Layout

Three-column `NavigationSplitView`:

**Left Column (220px) — Session List**
- List of project-based sessions with name, version count, last updated time
- "+" button to create new session
- Bottom section: Memory management (Style Preferences, Session Feedback, Import/Export)

**Center Column (flex) — Chat View**
- Bubble-style messages (user right-aligned, assistant left-aligned)
- Session name and current version in header
- Text input at bottom

**Right Column (300px) — Prompt Preview**
- Displays the current complete prompt in full
- Copy button (copies to NSPasteboard)
- Version selector (v1, v2, v3...) to browse and compare history
- Auto-updates whenever Claude produces a new prompt version

## Data Model

### SwiftData Models

```swift
@Model
class Session {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [Message]
}

@Model
class Message {
    var id: UUID
    var role: MessageRole  // .user | .assistant
    var content: String
    var promptSnapshot: String?  // full prompt if this turn produced one
    var version: Int?            // prompt version number
    var createdAt: Date
}
```

### Memory Storage

```
~/Library/Application Support/GeminiGrapher/memory/
├── preferences/
│   ├── style.md          # long-term style preferences
│   └── negative.md       # elements to avoid
└── feedback/
    ├── cyberpunk-characters.md   # per-session feedback
    └── product-photography.md
```

Markdown format:
```markdown
# Style Preferences

- cinematic lighting, always
- prefer cool blue/purple tones
- no cartoon style
- high detail, 8K resolution
```

**Export**: zip the entire `memory/` folder, or open in Finder for direct editing.
**Import**: drag in a `.zip` or select a folder to replace.

## LLM Interaction

### Request Structure

Each request to vibeproxy sends:
```
[system]    PromptEngine-assembled system prompt (instructions + memory + current prompt)
[user]      historical message 1
[assistant] historical message 2
...
[user]      latest user input
```

### Response Parsing

Claude uses a delimiter to separate conversational response from the generated prompt:

```
Conversational reply here...

---PROMPT---
Complete Gemini image generation prompt here...
```

Parsing rules:
- Content before `---PROMPT---` → display in chat
- Content after `---PROMPT---` → update right panel, increment version
- No `---PROMPT---` in response (e.g., a clarifying question) → chat only, right panel unchanged

### Streaming

Responses stream via SSE. The chat bubble and prompt preview update in real-time as tokens arrive. The delimiter is detected during streaming to split content to the correct panel.

## Error Handling

- **vibeproxy unreachable**: inline error in chat area with retry button
- **streaming interrupted**: preserve partial content, show "response interrupted, click to retry"
- **parse failure** (no valid `---PROMPT---`): treat entire response as chat, do not update prompt panel
- **no crash policy**: all network/parse errors are handled gracefully with user-visible messages

## Settings

Preferences window:
- VibeProxy URL (default: `http://localhost:8317`)
- Model selection (dropdown populated from `/v1/models`)
- Memory folder path
- Import/Export memory buttons

## Technical Stack

- **Platform**: macOS 14+ (Sonoma)
- **UI**: SwiftUI, NavigationSplitView
- **Data**: SwiftData (sessions, messages)
- **Markdown rendering**: swift-markdown-ui package
- **Networking**: URLSession with async/await, SSE streaming
- **Clipboard**: NSPasteboard

## Session Operations

- Create new session (with name)
- Rename session
- Delete session
- Switch between sessions (preserves state)
- Browse prompt version history within a session
- Resume conversation from an older prompt version
