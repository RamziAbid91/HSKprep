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
    @State private var feedbackTick = 0

    var body: some View {
        VStack(spacing: 16) {
            if let word = queue.first {
                ProgressView(value: Double(reviewedThisSession), total: Double(reviewedThisSession + queue.count))
                    .tint(Theme.levelColor(level))
                Text("\(queue.count) left · tap the card to flip")
                    .font(.footnote).foregroundStyle(.secondary)
                card(for: word)
                if showAnswer {
                    gradeButtons(for: word)
                } else {
                    Button { flip() } label: {
                        Text("Show answer").font(.headline).frame(maxWidth: .infinity)
                    }
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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flashcards · HSK \(level)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if !built { buildQueue(); built = true } }
        .sensoryFeedback(.impact(weight: .light), trigger: showAnswer)
        .sensoryFeedback(.selection, trigger: feedbackTick)
        .studyTimer()
    }

    // MARK: - Pieces

    private func flip() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { showAnswer.toggle() }
    }

    /// A card that flips in 3D: characters on the front, everything else on the back.
    private func card(for word: Word) -> some View {
        ZStack {
            front(word)
                .opacity(showAnswer ? 0 : 1)
                .rotation3DEffect(.degrees(showAnswer ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            back(word)
                .opacity(showAnswer ? 1 : 0)
                .rotation3DEffect(.degrees(showAnswer ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { flip() }
        .onAppear { Speaker.shared.speak(word.hanzi) }
        .id(word.id)
    }

    private func cardBackground<V: View>(_ content: V) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.levelColor(level).opacity(0.35), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private func front(_ word: Word) -> some View {
        cardBackground(
            VStack(spacing: 18) {
                Text("HSK \(word.level)").font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Theme.levelColor(word.level).opacity(0.15), in: Capsule())
                    .foregroundStyle(Theme.levelColor(word.level))
                Spacer()
                Text(word.hanzi).font(.system(size: 88, weight: .medium))
                AudioButtons(text: word.hanzi)
                Spacer()
                Text("Do you know it? Say it out loud, then flip.").font(.footnote).foregroundStyle(.secondary)
            }
        )
    }

    private func back(_ word: Word) -> some View {
        cardBackground(
            ScrollView {
                VStack(spacing: 12) {
                    if let pic = word.emoji { PictureView(picture: pic, size: 160, corner: 20) }
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(word.hanzi).font(.system(size: 44, weight: .medium))
                        AudioButtons(text: word.hanzi)
                    }
                    Text(word.pinyin).font(.title).foregroundStyle(Theme.accent)
                    Text(word.english).font(.title3).multilineTextAlignment(.center)
                    if let hint = Radicals.hint(for: word) {
                        Label(hint, systemImage: "lightbulb")
                            .font(.footnote)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
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
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        )
    }

    private func gradeButtons(for word: Word) -> some View {
        HStack {
            ForEach(ReviewGrade.allCases, id: \.self) { g in
                Button { submit(word, g) } label: {
                    VStack(spacing: 2) {
                        Text(g.label).font(.subheadline.bold())
                        Text(g.hint).font(.caption2).opacity(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
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
        feedbackTick += 1
    }
}
