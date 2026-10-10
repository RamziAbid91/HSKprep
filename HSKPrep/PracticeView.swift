import SwiftUI
import SwiftData

// MARK: - Practice hub

struct PracticeView: View {
    @Query private var progress: [CardProgress]
    @Query private var attempts: [Attempt]
    @AppStorage(Settings.level) private var level = 1

    private var dueCount: Int {
        let ids = Set(VocabularyStore.words(level: level).map(\.id))
        return progress.filter { ids.contains($0.wordID) && $0.repetitions > 0 && $0.dueDate <= .now }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Vocabulary · HSK \(level)") {
                    NavigationLink { FlashcardsView() } label: {
                        row("Flashcards", "Spaced repetition review", "rectangle.on.rectangle", badge: dueCount)
                    }
                    NavigationLink { QuizView(mode: .meaning) } label: {
                        row("Multiple choice", "Pick the right meaning", "list.bullet.circle")
                    }
                    NavigationLink { QuizView(mode: .typing) } label: {
                        row("Typing practice", "Type the pinyin (tones optional)", "keyboard")
                    }
                }
                Section("Listening 听力") {
                    NavigationLink { QuizView(mode: .listening) } label: {
                        row("Listening exercise", "Words, true/false, and sentences", "headphones")
                    }
                }
                Section("Fix your weak spots") {
                    NavigationLink { QuizView(mode: .mistakes) } label: {
                        row("Mistake review", "A session built from your errors", "arrow.uturn.backward.circle",
                            badge: Stats.mistakeWords(attempts).count)
                    }
                }
                Section {
                    Label("Pronunciation & tone drills are coming in a later version.", systemImage: "waveform")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Practice")
        }
    }

    private func row(_ title: String, _ subtitle: String, _ icon: String, badge: Int = 0) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 28).foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if badge > 0 {
                Text("\(badge)").font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(.tint.opacity(0.2), in: Capsule())
            }
        }
    }
}

// MARK: - Quiz model

enum QuizMode {
    case meaning, typing, listening, mistakes
    var title: String {
        switch self {
        case .meaning: "Multiple choice"
        case .typing: "Typing practice"
        case .listening: "Listening"
        case .mistakes: "Mistake review"
        }
    }
}

enum ItemKind {
    case chooseMeaning, typePinyin, listenWord, listenTrueFalse, listenSentence

    var skill: Skill {
        switch self {
        case .chooseMeaning: .vocabulary
        case .typePinyin: .typing
        case .listenWord, .listenTrueFalse, .listenSentence: .listening
        }
    }
    var isListening: Bool { skill == .listening }
}

struct QuizItem: Identifiable {
    let id = UUID()
    let kind: ItemKind
    let word: Word
    let options: [String]
    let answer: String
    var statement: String? = nil   // for true/false

    /// What the learner hears.
    var audio: String? {
        switch kind {
        case .listenWord, .listenTrueFalse: word.hanzi
        case .listenSentence: word.example
        default: nil
        }
    }

    var prompt: String {
        switch kind {
        case .chooseMeaning: "What does this word mean?"
        case .typePinyin: "Type the pinyin."
        case .listenWord: "Listen and choose the word you hear."
        case .listenTrueFalse: "Listen. True or false: the word means “\(statement ?? "")”."
        case .listenSentence: "Listen to the sentence. What does it mean?"
        }
    }
}

enum QuizBuilder {
    static func make(kinds: [ItemKind], words: [Word], distractors: [Word]) -> [QuizItem] {
        words.enumerated().compactMap { i, word in
            item(kind: kinds[i % kinds.count], word: word, distractors: distractors)
        }
    }

    static func item(kind: ItemKind, word: Word, distractors: [Word]) -> QuizItem? {
        let others = distractors.filter { $0.id != word.id }.shuffled()
        switch kind {
        case .chooseMeaning:
            return QuizItem(kind: kind, word: word, options: ([word.english] + others.prefix(3).map(\.english)).shuffled(), answer: word.english)
        case .typePinyin:
            return QuizItem(kind: kind, word: word, options: [], answer: word.pinyin)
        case .listenWord:
            return QuizItem(kind: kind, word: word, options: ([word.hanzi] + others.prefix(3).map(\.hanzi)).shuffled(), answer: word.hanzi)
        case .listenTrueFalse:
            let isTrue = Bool.random()
            let statement = isTrue ? word.english : (others.first?.english ?? word.english)
            return QuizItem(kind: kind, word: word, options: ["True", "False"],
                            answer: statement == word.english ? "True" : "False", statement: statement)
        case .listenSentence:
            guard let meaning = word.exampleEnglish, word.example != nil else { return nil }
            let wrong = others.compactMap(\.exampleEnglish).prefix(3)
            return QuizItem(kind: kind, word: word, options: ([meaning] + wrong).shuffled(), answer: meaning)
        }
    }
}

// MARK: - Quiz screen (learning mode: immediate feedback + explanations)

struct QuizView: View {
    let mode: QuizMode

    @Environment(\.modelContext) private var context
    @Query private var progress: [CardProgress]
    @Query private var attempts: [Attempt]
    @AppStorage(Settings.level) private var level = 1

    @State private var items: [QuizItem] = []
    @State private var index = 0
    @State private var selected: String?
    @State private var typed = ""
    @State private var checked = false
    @State private var correctCount = 0
    @State private var built = false
    @State private var speed: Speaker.Speed = .normal

    private var finished: Bool { built && index >= items.count }

    var body: some View {
        Group {
            if built && items.isEmpty {
                ContentUnavailableView(mode == .mistakes ? "No mistakes to review 🎉" : "Not enough words yet",
                                       systemImage: "checkmark.seal",
                                       description: Text(mode == .mistakes ? "Words you get wrong will show up here." : "Learn a few flashcards first."))
            } else if finished {
                results
            } else if items.indices.contains(index) {
                question(items[index])
            } else {
                ProgressView()
            }
        }
        .padding()
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if !built { build(); built = true } }
        .studyTimer()
    }

    // MARK: Build

    private func build() {
        let levelWords = VocabularyStore.words(level: level)
        let started = Set(progress.filter { $0.repetitions > 0 }.map(\.wordID))
        let studied = levelWords.filter { started.contains($0.id) }
        let pool = studied.count >= 6 ? studied : levelWords

        switch mode {
        case .meaning:
            items = QuizBuilder.make(kinds: [.chooseMeaning], words: Array(pool.shuffled().prefix(10)), distractors: levelWords)
        case .typing:
            items = QuizBuilder.make(kinds: [.typePinyin], words: Array(pool.shuffled().prefix(8)), distractors: levelWords)
        case .listening:
            // Gradually harder: single words → true/false → whole sentences.
            let picks = Array(pool.shuffled().prefix(6))
            let kinds: [ItemKind] = [.listenWord, .listenWord, .listenTrueFalse, .listenTrueFalse, .listenSentence, .listenSentence]
            items = zip(kinds, picks).compactMap { QuizBuilder.item(kind: $0, word: $1, distractors: levelWords) }
            // Faster audio once the learner is consistently accurate.
            let acc = Stats.accuracy(attempts, skill: .listening, days: 14) ?? 0
            speed = acc >= 0.85 ? .fast : .normal
        case .mistakes:
            let words = Stats.mistakeWords(attempts).prefix(10).map(\.word)
            items = QuizBuilder.make(kinds: [.chooseMeaning, .listenWord, .typePinyin], words: Array(words),
                                     distractors: VocabularyStore.all)
        }
    }

    // MARK: Question

    private func question(_ q: QuizItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProgressView(value: Double(index), total: Double(items.count))
                Text(q.prompt).font(.title3.bold())

                if let audio = q.audio {
                    HStack {
                        Button { Speaker.shared.speak(audio, speed: speed) } label: {
                            Label("Play", systemImage: "speaker.wave.3.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button { Speaker.shared.speak(audio, speed: .slow) } label: {
                            Image(systemName: "tortoise.fill").padding(.horizontal, 6)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.large)
                    .onAppear { Speaker.shared.speak(audio, speed: speed) }
                } else {
                    Text(q.word.hanzi).font(.system(size: 60, weight: .medium)).frame(maxWidth: .infinity)
                }

                if q.kind == .typePinyin {
                    TextField("e.g. ni hao", text: $typed)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .disabled(checked)
                        .onSubmit { if !typed.isEmpty { check(q) } }
                } else {
                    ForEach(q.options, id: \.self) { option in
                        optionButton(option, q: q)
                    }
                }

                if checked { feedback(q) }

                Button(checked ? (index == items.count - 1 ? "See results" : "Next") : "Check") {
                    if checked { next() } else { check(q) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!checked && selected == nil && typed.isEmpty)
            }
        }
        .id(q.id)
    }

    private func optionButton(_ option: String, q: QuizItem) -> some View {
        let isAnswer = option == q.answer
        let isPicked = option == selected
        let color: Color = !checked ? (isPicked ? .accentColor : .secondary)
            : isAnswer ? .green : isPicked ? .red : .secondary
        return Button { if !checked { selected = option } } label: {
            Text(option)
                .font(q.kind == .listenWord ? .title2 : .body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(color.opacity(isPicked || (checked && isAnswer) ? 0.2 : 0.08),
                            in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    /// Explanation shown after every answer — including the transcript for listening.
    private func feedback(_ q: QuizItem) -> some View {
        let right = isCorrect(q)
        return VStack(alignment: .leading, spacing: 8) {
            Label(right ? "Correct!" : "Not quite", systemImage: right ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline).foregroundStyle(right ? .green : .red)
            if q.kind == .typePinyin && !right {
                Text("You typed: \(typed)").font(.subheadline)
            }
            if q.kind == .listenSentence, let ex = q.word.example {
                Text("Transcript").font(.caption).foregroundStyle(.secondary)
                Text(ex).font(.title3)
                if let p = q.word.examplePinyin { Text(p).foregroundStyle(.secondary) }
                if let e = q.word.exampleEnglish { Text(e) }
                Text("Key word: \(q.word.hanzi) (\(q.word.pinyin)) — \(q.word.english)").font(.subheadline)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(q.word.hanzi).font(.title2)
                    Text(q.word.pinyin).foregroundStyle(.tint)
                    Spacer()
                    AudioButtons(text: q.word.hanzi)
                }
                Text(q.word.english)
                if let ex = q.word.example {
                    Text("\(ex)  \(q.word.exampleEnglish ?? "")").font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    // MARK: Logic

    private func isCorrect(_ q: QuizItem) -> Bool {
        q.kind == .typePinyin ? Pinyin.matches(typed, q.answer) : selected == q.answer
    }

    private func check(_ q: QuizItem) {
        checked = true
        let ok = isCorrect(q)
        if ok { correctCount += 1 }
        Tracker.record(context, skill: q.kind.skill, itemID: q.word.id, correct: ok)
    }

    private func next() {
        index += 1
        selected = nil
        typed = ""
        checked = false
        if index >= items.count, mode == .listening {
            Tracker.today(context).listeningSessions += 1
            try? context.save()
        }
    }

    private var results: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("\(correctCount) / \(items.count)").font(.system(size: 56, weight: .bold))
            Text(correctCount == items.count ? "Perfect! 🎉" : "Mistakes go into your review list.")
                .foregroundStyle(.secondary)
            Button("Practice again") {
                index = 0; correctCount = 0; build()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}
