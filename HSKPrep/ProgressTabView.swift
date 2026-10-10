import SwiftUI
import SwiftData
import Charts

/// Named ProgressTabView to avoid clashing with SwiftUI's ProgressView.
struct ProgressTabView: View {
    @Query private var progress: [CardProgress]
    @Query private var attempts: [Attempt]
    @Query private var days: [StudyDay]
    @Query private var tests: [TestResult]
    @AppStorage(Settings.level) private var level = 1

    var body: some View {
        NavigationStack {
            List {
                readinessSection
                vocabularySection
                accuracySection
                weakSpotsSection
                calendarSection
            }
            .navigationTitle("Progress")
        }
    }

    // MARK: Readiness

    private var readinessSection: some View {
        Section {
            ForEach(1...3, id: \.self) { lvl in
                let r = Stats.readiness(level: lvl, progress: progress, tests: tests)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("HSK \(lvl)").bold()
                        Spacer()
                        Text("\(Int(r * 100))%").monospacedDigit()
                    }
                    ProgressView(value: r).tint(r >= 0.7 ? .green : r >= 0.4 ? .orange : .red)
                }
            }
        } header: {
            Text("Exam readiness")
        } footer: {
            Text("A rough estimate from mastered vocabulary (60%) and your last 3 practice exams (40%).")
        }
    }

    // MARK: Vocabulary

    private var vocabularySection: some View {
        let ids = Set(VocabularyStore.words(level: level).map(\.id))
        let mine = progress.filter { ids.contains($0.wordID) }
        let mastered = mine.filter(\.isMastered).count
        let learning = mine.filter(\.isLearning).count
        let new = ids.count - mastered - learning
        return Section("Vocabulary · HSK \(level)") {
            Chart {
                BarMark(x: .value("Count", mastered), y: .value("", "Words")).foregroundStyle(by: .value("Status", "Mastered"))
                BarMark(x: .value("Count", learning), y: .value("", "Words")).foregroundStyle(by: .value("Status", "Learning"))
                BarMark(x: .value("Count", new), y: .value("", "Words")).foregroundStyle(by: .value("Status", "New"))
            }
            .chartForegroundStyleScale(["Mastered": Color.green, "Learning": Color.orange, "New": Color.gray.opacity(0.4)])
            .chartYAxis(.hidden)
            .frame(height: 70)
            HStack {
                Text("⭐ \(mastered) mastered")
                Spacer()
                Text("◐ \(learning) learning")
                Spacer()
                Text("○ \(new) new")
            }
            .font(.caption)
        }
    }

    // MARK: Accuracy

    private var accuracySection: some View {
        Section("Accuracy (last 30 days)") {
            ForEach(Skill.allCases) { skill in
                HStack {
                    Label(skill.title, systemImage: skill.icon)
                    Spacer()
                    if let a = Stats.accuracy(attempts, skill: skill) {
                        Text("\(Int(a * 100))%").monospacedDigit()
                            .foregroundStyle(a >= 0.8 ? .green : a >= 0.6 ? .orange : .red)
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Weak spots

    private var weakSpotsSection: some View {
        let mistakes = Stats.mistakeWords(attempts)
        return Section {
            if mistakes.isEmpty {
                Text("No repeated mistakes yet. Keep going!").foregroundStyle(.secondary)
            } else {
                ForEach(Array(mistakes.prefix(5))) { item in
                    HStack {
                        Text(item.word.hanzi).font(.title3)
                        Text(item.word.english).foregroundStyle(.secondary)
                        Spacer()
                        Text("missed \(item.misses)×").font(.caption).foregroundStyle(.red)
                    }
                }
                NavigationLink { QuizView(mode: .mistakes) } label: {
                    Label("Start a revision session (\(min(mistakes.count, 10)) words)", systemImage: "arrow.uturn.backward.circle")
                        .bold()
                }
            }
        } header: {
            Text("Words to work on")
        }
    }

    // MARK: Calendar & streak

    private var calendarSection: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let byDay = Dictionary(days.map { (cal.startOfDay(for: $0.day), $0) }, uniquingKeysWith: { a, _ in a })
        let last28 = (0..<28).reversed().map { cal.date(byAdding: .day, value: -$0, to: today)! }
        let last7 = Array(last28.suffix(7))

        return Section("Study calendar") {
            HStack {
                Label("\(Stats.streak(days)) day streak", systemImage: "flame.fill").foregroundStyle(.orange)
                Spacer()
                Text("\(days.filter(\.isActive).count) active days total").font(.caption).foregroundStyle(.secondary)
            }

            Chart(last7, id: \.self) { d in
                BarMark(x: .value("Day", d, unit: .day), y: .value("Minutes", byDay[d]?.minutes ?? 0))
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            .frame(height: 120)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(last28, id: \.self) { d in
                    let mins = byDay[d]?.minutes ?? 0
                    RoundedRectangle(cornerRadius: 4)
                        .fill(mins == 0 ? Color.gray.opacity(0.15) : Color.green.opacity(min(1, 0.3 + Double(mins) / 30)))
                        .frame(height: 22)
                        .overlay {
                            if d == today { RoundedRectangle(cornerRadius: 4).stroke(.primary, lineWidth: 1) }
                        }
                }
            }
            Text("Last 4 weeks — darker = more minutes").font(.caption2).foregroundStyle(.secondary)
        }
    }
}
