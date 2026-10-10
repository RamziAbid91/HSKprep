# HSK Prep — notes for Claude Code

iOS 17+ SwiftUI + SwiftData app helping beginners prepare for HSK levels 1–3.
No third-party dependencies (Apple frameworks only: SwiftUI, SwiftData, AVFoundation, Charts).

## Navigation (5 tabs)
- **Home** (`HomeView.swift`) — daily goal ring, today's plan (new words / reviews / listening), continue button, streak, level progress, exam countdown. Person icon → `SettingsView` (same file).
- **Learn** (`LearnView.swift`) — level overview, vocabulary list + word detail, grammar lessons → `GrammarPracticeView` (sentence builder + fill-in-the-blank).
- **Practice** (`PracticeView.swift`) — flashcards, multiple choice, typing, listening, mistake review. `QuizView(mode:)` is the shared learning-mode quiz (immediate feedback + explanations).
- **Exams** (`ExamsView.swift`) — instructions → timed exam (listening + reading sections, 2 plays per recording, no feedback until submit) → section breakdown + explanations + history.
- **Progress** (`ProgressTabView.swift`) — readiness per level, mastered/learning/new, accuracy per skill, most-missed words → revision session, study calendar.

## Data
- `Models.swift` — `Word` (bundled), SwiftData: `CardProgress` (SM-2 state), `Attempt` (every answer), `StudyDay` (daily totals), `TestResult`.
- `Services.swift` — `VocabularyStore`, `Speaker` (zh-CN TTS), `Tracker` (records attempts/time), `Stats` (streak, accuracy, mistakes, readiness), `Pinyin` (lenient matching).
- `SpacedRepetition.swift` — SM-2.
- `Grammar.swift` — grammar points with examples, common mistakes and exercises (original content).
- `Vocabulary.json` — 40 words per level with example sentences. Fields: id, hanzi, pinyin, english, level, example, examplePinyin, exampleEnglish.

## Conventions
- Edit `project.yml` (XcodeGen), not the .xcodeproj.
- Word IDs (`<level>-<nnn>`) and grammar IDs (`g-…`) must stay stable — progress is keyed on them.
- Record every answer with `Tracker.record(...)` so accuracy and mistake review keep working.
- Syllabus is labelled HSK 2.0 in `Syllabus` (Models.swift). Never label generated questions as official.

## Roadmap
- Phase 2 remainder: full HSK 1–3 word lists, more grammar points, dialogue-based listening with images.
- Phase 3: native-speaker audio files, tone drills + record & compare, stroke order, adaptive plan, accounts/sync (e.g. Supabase), reminders.
