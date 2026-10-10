import SwiftUI
import SwiftData

/// Spaced-repetition flashcards: due reviews first, then today's new words.
struct FlashcardsView: View {
    @Environment(\.modelContext) private var context
    @Query private var progress: [CardProgress]
    @AppStorage(Settings.level) private var level = 1
    @AppStorage(Settings.newPerDay) private var newPerDay = 10

    @State private var queue: [Word] = []
    @State private var showAnswer = false
    @State private var reviewedThisSession = 0
    @State private var built = false

    var body: some View {
        VStack(spacing: 20) {
            if let word = queue.first {
                Text("\(queue.count) left in this session")
                    .font(.footnote).foregroundStyle(.secondary)
                card(for: word)
                Spacer()
                if showAnswer {
                    gradeButtons(for: word)
                } else {
                    Button("Show answer") { withAnimation { showAnswer = true } }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            } else {
                Spacer()
                ContentUnavailableView("All done for now 🎉",
                    systemImage: "checkmark.seal",
                    description: Text("You reviewed \(reviewedThisSession) cards. New reviews will appear when they're due."))
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Flashcards · HSK \(level)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if !built { buildQueue(); built = true } }
        .studyTimer()
    }

    // MARK: - Pieces

    private func card(for word: Word) -> some View {
        VStack(spacing: 14) {
            Text(word.hanzi).font(.system(size: 72, weight: .medium))
            AudioButtons(text: word.hanzi)

            if showAnswer {
                Divider()
                if let pic = word.emoji { Text(pic).font(.system(size: 56)) }
                Text(word.pinyin).font(.title).foregroundStyle(.tint)
                Text(word.english).font(.title3)
                if let ex = word.example {
                    VStack(spacing: 4) {
                        HStack {
                            Text(ex).font(.title3)
                            AudioButtons(text: ex).font(.body)
                        }
                        if let p = word.examplePinyin { Text(p).font(.subheadline).foregroundStyle(.secondary) }
                        if let e = word.exampleEnglish { Text(e).font(.subheadline) }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 24))
        .onAppear { Speaker.shared.speak(word.hanzi) }
        .id(word.id)
    }

    private func gradeButtons(for word: Word) -> some View {
        HStack {
            ForEach(ReviewGrade.allCases, id: \.self) { g in
                Button(g.label) { submit(word, g) }
                    .buttonStyle(.bordered)
                    .tint(g == .again ? .red : g == .easy ? .green : .accentColor)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
    }

    // MARK: - Logic

    private func progressFor(_ word: Word) -> CardProgress {
        if let p = progress.first(where: { $0.wordID == word.id }) { return p }
        let p = CardProgress(wordID: word.id)
        context.insert(p)
        return p
    }

    private func buildQueue() {
        let now = Date()
        let byID = Dictionary(progress.map { ($0.wordID, $0) }, uniquingKeysWith: { a, _ in a })
        let words = VocabularyStore.words(level: level)
        let due = words.filter { w in
            guard let p = byID[w.id], p.repetitions > 0 else { return false }
            return p.dueDate <= now
        }
        let learnedToday = Tracker.today(context).newWords
        let fresh = words.filter { (byID[$0.id]?.repetitions ?? 0) == 0 }
        queue = due.shuffled() + Array(fresh.prefix(max(0, newPerDay - learnedToday)))
        showAnswer = false
    }

    private func submit(_ word: Word, _ grade: ReviewGrade) {
        let p = progressFor(word)
        let wasNew = p.repetitions == 0
        SpacedRepetition.review(p, grade: grade)

        let day = Tracker.today(context)
        day.cardsReviewed += 1
        if wasNew && grade != .again { day.newWords += 1 }
        Tracker.record(context, skill: .vocabulary, itemID: word.id, correct: grade != .again)
        reviewedThisSession += 1

        queue.removeFirst()
        if grade == .again { queue.append(word) }   // comes back later this session
        showAnswer = false
    }
}
