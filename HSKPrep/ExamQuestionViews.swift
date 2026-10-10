import SwiftUI
import SwiftData

// MARK: - One exam-style question (used by the exam and by exam-style practice)

struct QuestionCard: View {
    let question: ExamQuestion
    @Binding var selected: Int?
    var revealed = false            // practice: show right/wrong + explanation
    var maxPlays: Int? = nil        // exam: 2 plays per recording; practice: unlimited
    @Binding var plays: Int

    private static let letters = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(question.part).font(.caption.bold()).foregroundStyle(.tint)
                Text(question.instruction).font(.subheadline).foregroundStyle(.secondary)
            }

            if let audio = question.audio { audioControls(audio) }

            if let picture = question.picture {
                Text(picture)
                    .font(.system(size: 90))
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
            }

            if let text = question.text {
                Text(text)
                    .font(text.count > 40 ? .title3 : .title2)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
            }

            if let star = question.statement {
                Text("★ \(star)").font(.title3.weight(.semibold))
            }

            if question.usesPictures { pictureOptions } else { textOptions }

            if revealed { ExplanationView(question: question, picked: selected) }
        }
    }

    // MARK: Audio

    private func audioControls(_ audio: [DialogueLine]) -> some View {
        let left = maxPlays.map { max(0, $0 - plays) }
        return HStack {
            Button {
                plays += 1
                Speaker.shared.play(audio, question: question.audioQuestion)
            } label: {
                Label(left.map { $0 > 0 ? "Play recording (\($0) left)" : "No plays left" } ?? "Play recording",
                      systemImage: "speaker.wave.3.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(left == 0)

            if maxPlays == nil {
                Button { Speaker.shared.play(audio, question: question.audioQuestion, speed: .slow) } label: {
                    Image(systemName: "tortoise.fill").padding(.horizontal, 4)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
    }

    // MARK: Options

    private func color(for i: Int) -> Color {
        if revealed {
            if i == question.answer { return .green }
            if i == selected { return .red }
            return .secondary
        }
        return i == selected ? .accentColor : .secondary
    }

    private var pictureOptions: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: question.options.count == 3 ? 3 : 2),
                  spacing: 12) {
            ForEach(question.options.indices, id: \.self) { i in
                Button { if !revealed { selected = i } } label: {
                    VStack(spacing: 4) {
                        Text(question.options[i].picture ?? "").font(.system(size: 56))
                        Text(Self.letters[i]).font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .background(color(for: i).opacity(i == selected || (revealed && i == question.answer) ? 0.22 : 0.08),
                                in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(color(for: i), lineWidth: i == selected ? 2 : 0))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var textOptions: some View {
        VStack(spacing: 10) {
            ForEach(question.options.indices, id: \.self) { i in
                Button { if !revealed { selected = i } } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(Self.letters[i]).bold()
                        Text(question.options[i].text).font(.title3)
                        Spacer()
                    }
                    .padding()
                    .background(color(for: i).opacity(i == selected || (revealed && i == question.answer) ? 0.2 : 0.08),
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Explanation: transcript with pinyin, translation, note

struct ExplanationView: View {
    let question: ExamQuestion
    let picked: Int?

    private var correct: Bool { picked == question.answer }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(correct ? "Correct!" : "Not quite — the answer is \(answerText)",
                  systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(correct ? .green : .red)

            if !question.transcript.isEmpty {
                HStack {
                    Text(question.audio == nil ? "Text" : "Transcript").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Button { Speaker.shared.play(question.transcript) } label: { Image(systemName: "speaker.wave.2.fill") }
                        .buttonStyle(.borderless)
                }
                ForEach(Array(question.transcript.enumerated()), id: \.offset) { _, line in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line.label + line.text).font(.body)
                        Text(line.pinyin).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !question.english.isEmpty {
                Text(question.english).font(.subheadline)
            }
            if !question.note.isEmpty {
                Text(question.note).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var answerText: String {
        let o = question.options[question.answer]
        let letter = ["A", "B", "C", "D", "E", "F"][question.answer]
        return o.picture != nil ? "\(letter) \(o.picture!)" : "\(letter) \(o.text)"
    }
}

// MARK: - Exam-style practice (learning mode: feedback after each question)

struct ExamPracticeView: View {
    let section: ExamSection

    @Environment(\.modelContext) private var context
    @AppStorage(Settings.level) private var level = 1
    @State private var questions: [ExamQuestion] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var revealed = false
    @State private var plays = 0
    @State private var score = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if questions.isEmpty {
                    ProgressView()
                } else if index < questions.count {
                    ProgressView(value: Double(index), total: Double(questions.count))
                    QuestionCard(question: questions[index], selected: $selected, revealed: revealed, plays: $plays)
                        .id(questions[index].id)
                    Button(revealed ? (index == questions.count - 1 ? "See results" : "Next") : "Check") {
                        revealed ? next() : check()
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(selected == nil)
                } else {
                    results
                }
            }
            .padding()
        }
        .navigationTitle(section == .listening ? "Listening · HSK \(level)" : "Reading · HSK \(level)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty { start() } }
        .onDisappear { Speaker.shared.stop() }
        .studyTimer()
    }

    private var results: some View {
        VStack(spacing: 14) {
            Text("\(score) / \(questions.count)").font(.system(size: 56, weight: .bold))
            Text(score == questions.count ? "Perfect! 🎉" : "Words you missed go into your mistake review.")
                .foregroundStyle(.secondary)
            Button("New set of questions", action: start).buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func start() {
        questions = ExamBuilder.practice(section: section, level: level)
        index = 0; score = 0
        reset()
    }

    private func reset() { selected = nil; revealed = false; plays = 0 }

    private func check() {
        guard let s = selected else { return }
        let q = questions[index]
        revealed = true
        if s == q.answer { score += 1 }
        Tracker.record(context, skill: q.itemID.hasPrefix("g-") ? .grammar : section.skill, itemID: q.itemID, correct: s == q.answer)
    }

    private func next() {
        Speaker.shared.stop()
        index += 1
        reset()
        if index >= questions.count, section == .listening {
            Tracker.today(context).listeningSessions += 1
            try? context.save()
        }
    }
}
