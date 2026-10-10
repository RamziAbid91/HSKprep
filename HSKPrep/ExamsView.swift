import SwiftUI
import SwiftData

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
                    LabeledContent("Listening 听力", value: "4 parts · 20 questions")
                    LabeledContent("Reading 阅读", value: "4 parts · 20 questions")
                    LabeledContent("Time limit", value: "\(ExamBuilder.timeLimit(level: examLevel) / 60) min")
                    Button("Start exam") { showInstructions = true }.bold()
                }
                Section {
                    Text("Same types of questions as the HSK papers — pictures, true/false ★, dialogues, passages, replies and fill-in-the-blank — but shorter, and every question is original practice material (not official HSK questions).")
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
            Label("Listening 听力: pictures, true/false ★, dialogues\(level >= 3 ? " and passages" : ""). Each recording can be played twice.", systemImage: "headphones")
            Label("Reading 阅读: pictures, replies, fill in the blank\(level >= 2 ? ", short texts" : "").", systemImage: "text.book.closed")
            Label("You have \(ExamBuilder.timeLimit(level: level) / 60) minutes. The exam submits automatically when time runs out.", systemImage: "timer")
            Label("No hints or answers during the exam. Transcripts and explanations appear after you submit.", systemImage: "eye.slash")
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
    @State private var answers: [UUID: Int] = [:]
    @State private var plays: [UUID: Int] = [:]
    @State private var secondsLeft = 0
    @State private var finished = false
    @State private var confirmSubmit = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timeLimit: Int { ExamBuilder.timeLimit(level: level) }

    private func score(_ section: ExamSection? = nil) -> (Int, Int) {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { Speaker.shared.stop(); onClose() }
                }
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
        .onAppear {
            if questions.isEmpty {
                questions = ExamBuilder.exam(level: level)
                secondsLeft = timeLimit
            }
        }
        .onReceive(timer) { _ in
            guard !finished, !questions.isEmpty else { return }
            if secondsLeft > 0 { secondsLeft -= 1 } else { finish() }
        }
    }

    private func questionView(_ q: ExamQuestion) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ProgressView(value: Double(index + 1), total: Double(questions.count))
                    Text("\(q.section.rawValue) · \(index + 1)/\(questions.count)")
                        .font(.caption).foregroundStyle(.secondary)
                    QuestionCard(
                        question: q,
                        selected: Binding(get: { answers[q.id] }, set: { answers[q.id] = $0 }),
                        maxPlays: q.audio == nil ? nil : 2,
                        plays: Binding(get: { plays[q.id] ?? 0 }, set: { plays[q.id] = $0 }))
                }
                .padding()
            }
            .id(q.id)
            HStack {
                Button("Back") { Speaker.shared.stop(); index -= 1 }.disabled(index == 0)
                Spacer()
                if index == questions.count - 1 {
                    Button("Submit") { confirmSubmit = true }.buttonStyle(.borderedProminent)
                } else {
                    Button("Next") { Speaker.shared.stop(); index += 1 }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    private var results: some View {
        let (c, t) = score()
        let (lc, lt) = score(.listening)
        let (rc, rt) = score(.reading)
        return List {
            Section {
                VStack(spacing: 6) {
                    Text("\(c) / \(t)").font(.system(size: 52, weight: .bold))
                    Text(c * 100 / max(t, 1) >= 60 ? "Pass ✅" : "Keep practicing 💪").font(.title3)
                    Text("Time used: \((timeLimit - secondsLeft) / 60) min").foregroundStyle(.secondary)
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
                    NavigationLink {
                        ScrollView {
                            QuestionCard(question: q, selected: .constant(answers[q.id]), revealed: true, plays: .constant(0))
                                .padding()
                        }
                        .navigationTitle("Question \(i + 1)")
                        .onDisappear { Speaker.shared.stop() }
                    } label: {
                        HStack {
                            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(ok ? .green : .red)
                            VStack(alignment: .leading) {
                                Text("Q\(i + 1) · \(q.part)").font(.subheadline)
                                Text(q.section.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Button("Done", action: onClose)
        }
    }

    private func finish() {
        guard !finished else { return }
        Speaker.shared.stop()
        finished = true
        let (c, t) = score()
        let (lc, lt) = score(.listening)
        let (rc, rt) = score(.reading)
        context.insert(TestResult(level: level, correct: c, total: t, secondsUsed: timeLimit - secondsLeft,
                                  listeningCorrect: lc, listeningTotal: lt, readingCorrect: rc, readingTotal: rt))
        // Feed exam mistakes into the review system.
        for q in questions {
            Tracker.record(context, skill: q.itemID.hasPrefix("g-") ? .grammar : q.section.skill,
                           itemID: q.itemID, correct: answers[q.id] == q.answer)
        }
        Tracker.addTime(context, seconds: timeLimit - secondsLeft)
        try? context.save()
    }
}
