import SwiftUI
import SwiftData

// MARK: - Exam question model

enum ExamSection: String, CaseIterable {
    case listening = "Listening 听力"
    case reading = "Reading 阅读"
    var skill: Skill { self == .listening ? .listening : .reading }
}

struct ExamQuestion: Identifiable {
    let id = UUID()
    let section: ExamSection
    let prompt: String
    let audio: String?        // played, not shown (listening)
    let display: String?      // shown big (reading)
    let options: [String]
    let answer: String
    let itemID: String        // word or grammar id, for mistake tracking
    let explanation: String   // shown only after submission
}

/// Builds an original practice exam (not official HSK questions).
enum ExamGenerator {
    static let listeningCount = 10
    static let readingCount = 10
    static let timeLimit = 15 * 60

    static func make(level: Int) -> [ExamQuestion] {
        let pool = VocabularyStore.words(level: level)
        guard pool.count >= 4 else { return [] }
        let picks = pool.shuffled()
        var out: [ExamQuestion] = []

        // Listening: 5 word recognition + 5 sentence comprehension
        for (i, w) in picks.prefix(listeningCount).enumerated() {
            let others = pool.filter { $0.id != w.id }.shuffled()
            if i < 5 || w.example == nil {
                out.append(ExamQuestion(
                    section: .listening, prompt: "You will hear a word. Choose the word you hear.",
                    audio: w.hanzi, display: nil,
                    options: ([w.hanzi] + others.prefix(3).map(\.hanzi)).shuffled(), answer: w.hanzi,
                    itemID: w.id, explanation: "\(w.hanzi) (\(w.pinyin)) — \(w.english)"))
            } else {
                let meaning = w.exampleEnglish ?? w.english
                out.append(ExamQuestion(
                    section: .listening, prompt: "You will hear a sentence. Choose what it means.",
                    audio: w.example, display: nil,
                    options: ([meaning] + others.compactMap(\.exampleEnglish).prefix(3)).shuffled(), answer: meaning,
                    itemID: w.id,
                    explanation: "Transcript: \(w.example ?? "")\n\(w.examplePinyin ?? "")\n\(meaning)"))
            }
        }

        // Reading: meaning + pinyin + grammar fill-in-the-blank
        let readingWords = Array(picks.dropFirst(listeningCount).prefix(6))
        for (i, w) in readingWords.enumerated() {
            let others = pool.filter { $0.id != w.id }.shuffled()
            if i % 2 == 0 {
                out.append(ExamQuestion(
                    section: .reading, prompt: "Choose the correct meaning.", audio: nil, display: w.hanzi,
                    options: ([w.english] + others.prefix(3).map(\.english)).shuffled(), answer: w.english,
                    itemID: w.id, explanation: "\(w.hanzi) (\(w.pinyin)) means “\(w.english)”."))
            } else {
                out.append(ExamQuestion(
                    section: .reading, prompt: "Choose the correct pinyin.", audio: nil, display: w.hanzi,
                    options: ([w.pinyin] + others.prefix(3).map(\.pinyin)).shuffled(), answer: w.pinyin,
                    itemID: w.id, explanation: "\(w.hanzi) is read \(w.pinyin) — \(w.english)."))
            }
        }
        let grammar = GrammarStore.all.filter { $0.level <= level }
            .flatMap { p in p.blanks.map { (p, $0) } }.shuffled()
        for (p, f) in grammar.prefix(readingCount - out.filter { $0.section == .reading }.count) {
            out.append(ExamQuestion(
                section: .reading, prompt: "Choose the word that fills the blank.", audio: nil, display: f.sentence,
                options: f.options, answer: f.answer, itemID: p.id,
                explanation: "\(f.sentence.replacingOccurrences(of: "＿＿", with: f.answer)) — \(f.english)\nGrammar: \(p.title). \(p.explanation)"))
        }
        return out
    }
}

// MARK: - Exams tab

struct ExamsView: View {
    @Query(sort: \TestResult.date, order: .reverse) private var history: [TestResult]
    @AppStorage(Settings.level) private var level = 1
    @State private var examLevel = 1
    @State private var showInstructions = false
    @State private var running = false
    @State private var startRequested = false

    var body: some View {
        NavigationStack {
            List {
                Section("Practice exam") {
                    Picker("Level", selection: $examLevel) {
                        ForEach(1...3, id: \.self) { Text("HSK \($0)").tag($0) }
                    }
                    LabeledContent("Listening", value: "\(ExamGenerator.listeningCount) questions")
                    LabeledContent("Reading", value: "\(ExamGenerator.readingCount) questions")
                    LabeledContent("Time limit", value: "\(ExamGenerator.timeLimit / 60) min")
                    Button("Start exam") { showInstructions = true }.bold()
                }
                Section {
                    Text("Original practice questions in exam style. Not official HSK material.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("History") {
                    if history.isEmpty { Text("No attempts yet").foregroundStyle(.secondary) }
                    ForEach(history) { r in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("HSK \(r.level)").bold()
                                Spacer()
                                Text("\(r.correct)/\(r.total) · \(r.percent)%")
                                    .foregroundStyle(r.percent >= 60 ? .green : .red)
                            }
                            HStack {
                                Text(r.date, style: .date)
                                Spacer()
                                Text("🎧 \(r.listeningCorrect)/\(r.listeningTotal)   📖 \(r.readingCorrect)/\(r.readingTotal)")
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Exams")
            .onAppear { examLevel = level }
            // Start the exam only after the instructions sheet has fully closed.
            .sheet(isPresented: $showInstructions, onDismiss: {
                if startRequested { startRequested = false; running = true }
            }) {
                ExamInstructionsView(level: examLevel) {
                    startRequested = true
                    showInstructions = false
                }
                .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $running) {
                ExamSessionView(level: examLevel) { running = false }
            }
        }
    }
}

struct ExamInstructionsView: View {
    let level: Int
    let onStart: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HSK \(level) practice exam").font(.title2.bold())
            Label("Part 1: Listening — each recording can be played twice.", systemImage: "headphones")
            Label("Part 2: Reading — words, pinyin and grammar.", systemImage: "text.book.closed")
            Label("You have \(ExamGenerator.timeLimit / 60) minutes. The exam submits automatically when time runs out.", systemImage: "timer")
            Label("No hints or answers during the exam. Explanations appear after you submit.", systemImage: "eye.slash")
            Spacer()
            Button(action: onStart) { Text("Begin").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .padding(24)
    }
}

// MARK: - Exam session (exam mode: no feedback until submission)

struct ExamSessionView: View {
    let level: Int
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var questions: [ExamQuestion] = []
    @State private var index = 0
    @State private var answers: [UUID: String] = [:]
    @State private var plays: [UUID: Int] = [:]
    @State private var secondsLeft = ExamGenerator.timeLimit
    @State private var finished = false
    @State private var confirmSubmit = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private func correct(in section: ExamSection? = nil) -> (Int, Int) {
        let qs = questions.filter { section == nil || $0.section == section }
        return (qs.filter { answers[$0.id] == $0.answer }.count, qs.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if finished { results }
                else if questions.indices.contains(index) { questionView(questions[index]) }
                else { ProgressView() }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", action: onClose) }
                if !finished {
                    ToolbarItem(placement: .principal) {
                        Label(String(format: "%d:%02d", secondsLeft / 60, secondsLeft % 60), systemImage: "timer")
                            .monospacedDigit().bold()
                            .foregroundStyle(secondsLeft < 60 ? .red : .primary)
                    }
                }
            }
            .confirmationDialog("Submit the exam?", isPresented: $confirmSubmit) {
                Button("Submit", action: finish)
            } message: {
                Text("You answered \(answers.count) of \(questions.count) questions.")
            }
        }
        .onAppear { if questions.isEmpty { questions = ExamGenerator.make(level: level) } }
        .onReceive(timer) { _ in
            guard !finished, !questions.isEmpty else { return }
            if secondsLeft > 0 { secondsLeft -= 1 } else { finish() }
        }
    }

    private func questionView(_ q: ExamQuestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ProgressView(value: Double(index + 1), total: Double(questions.count))
            Text("\(q.section.rawValue) · \(index + 1)/\(questions.count)")
                .font(.caption).foregroundStyle(.secondary)
            Text(q.prompt).font(.headline)

            if let audio = q.audio {
                let left = 2 - (plays[q.id] ?? 0)
                Button {
                    plays[q.id, default: 0] += 1
                    Speaker.shared.speak(audio)
                } label: {
                    Label(left > 0 ? "Play recording (\(left) left)" : "No plays left", systemImage: "speaker.wave.3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).controlSize(.large)
                .disabled(left <= 0)
            }
            if let display = q.display {
                Text(display).font(.system(size: 40, weight: .medium)).frame(maxWidth: .infinity)
            }

            ForEach(Array(q.options.enumerated()), id: \.offset) { i, option in
                Button { answers[q.id] = option } label: {
                    HStack(alignment: .top) {
                        Text(["A", "B", "C", "D"][min(i, 3)]).bold()
                        Text(option).font(q.section == .listening && q.audio == option ? .title2 : .body)
                        Spacer()
                    }
                    .padding()
                    .background(answers[q.id] == option ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Spacer()
            HStack {
                Button("Back") { index -= 1 }.disabled(index == 0)
                Spacer()
                if index == questions.count - 1 {
                    Button("Submit") { confirmSubmit = true }.buttonStyle(.borderedProminent)
                } else {
                    Button("Next") { index += 1 }.buttonStyle(.borderedProminent)
                }
            }
        }
        .id(q.id)
    }

    private var results: some View {
        let (c, t) = correct()
        let (lc, lt) = correct(in: .listening)
        let (rc, rt) = correct(in: .reading)
        return List {
            Section {
                VStack(spacing: 6) {
                    Text("\(c) / \(t)").font(.system(size: 52, weight: .bold))
                    Text(c * 100 / max(t, 1) >= 60 ? "Pass ✅" : "Keep practicing 💪").font(.title3)
                    Text("Time used: \((ExamGenerator.timeLimit - secondsLeft) / 60) min")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            Section("Section breakdown") {
                LabeledContent("🎧 Listening", value: "\(lc)/\(lt)")
                LabeledContent("📖 Reading", value: "\(rc)/\(rt)")
            }
            Section("Answers & explanations") {
                ForEach(Array(questions.enumerated()), id: \.element.id) { i, q in
                    let ok = answers[q.id] == q.answer
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Q\(i + 1) · \(q.section.rawValue)", systemImage: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(ok ? .green : .red).font(.subheadline.bold())
                        if !ok { Text("Your answer: \(answers[q.id] ?? "—")").font(.caption).foregroundStyle(.red) }
                        Text("Correct: \(q.answer)").font(.caption)
                        Text(q.explanation).font(.caption).foregroundStyle(.secondary)
                        if let audio = q.audio { AudioButtons(text: audio).font(.body) }
                    }
                }
            }
            Button("Done", action: onClose)
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        let (c, t) = correct()
        let (lc, lt) = correct(in: .listening)
        let (rc, rt) = correct(in: .reading)
        context.insert(TestResult(level: level, correct: c, total: t,
                                  secondsUsed: ExamGenerator.timeLimit - secondsLeft,
                                  listeningCorrect: lc, listeningTotal: lt, readingCorrect: rc, readingTotal: rt))
        // Feed exam mistakes into the review system.
        for q in questions {
            Tracker.record(context, skill: q.itemID.hasPrefix("g-") ? .grammar : q.section.skill,
                           itemID: q.itemID, correct: answers[q.id] == q.answer)
        }
        Tracker.addTime(context, seconds: ExamGenerator.timeLimit - secondsLeft)
        try? context.save()
    }
}
