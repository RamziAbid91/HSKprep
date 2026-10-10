import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var progress: [CardProgress]
    @Query private var days: [StudyDay]
    @AppStorage(Settings.level) private var level = 1
    @AppStorage(Settings.dailyGoal) private var goalMinutes = 15
    @AppStorage(Settings.newPerDay) private var newPerDay = 10
    @AppStorage(Settings.examDate) private var examDate: Double = 0
    @State private var showSettings = false

    // MARK: Derived numbers

    private var levelWords: [Word] { VocabularyStore.words(level: level) }
    private var progressByID: [String: CardProgress] {
        Dictionary(progress.map { ($0.wordID, $0) }, uniquingKeysWith: { a, _ in a })
    }
    private var today: StudyDay? {
        let d = Calendar.current.startOfDay(for: .now)
        return days.first { $0.day == d }
    }
    private var dueCount: Int {
        levelWords.filter { w in
            guard let p = progressByID[w.id], p.repetitions > 0 else { return false }
            return p.dueDate <= .now
        }.count
    }
    private var freshRemaining: Int { levelWords.filter { (progressByID[$0.id]?.repetitions ?? 0) == 0 }.count }
    private var newTarget: Int { min(newPerDay, freshRemaining + (today?.newWords ?? 0)) }
    private var learnedCount: Int { levelWords.filter { (progressByID[$0.id]?.repetitions ?? 0) > 0 }.count }
    private var minutesToday: Int { today?.minutes ?? 0 }
    private var weekMinutes: Int {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return days.filter { $0.day >= start }.map(\.minutes).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    goalCard
                    planCard
                    continueButton
                    HStack(spacing: 12) {
                        statTile("\(Stats.streak(days))", "day streak", "flame.fill", .orange)
                        statTile("\(weekMinutes)", "min this week", "clock.fill", .blue)
                    }
                    levelCard
                    if examDate > 0 { examCountdown }
                }
                .padding()
            }
            .navigationTitle("你好! 👋")
            .toolbar {
                Button { showSettings = true } label: { Image(systemName: "person.crop.circle") }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    // MARK: Cards

    private var goalCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(1, Double(minutesToday) / Double(max(goalMinutes, 1))))
                    .stroke(.tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(minutesToday)").font(.title2.bold())
            }
            .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily goal").font(.headline)
                Text("\(minutesToday) of \(goalMinutes) minutes")
                    .foregroundStyle(.secondary)
                if minutesToday >= goalMinutes { Text("Goal reached 🎉").font(.subheadline.bold()) }
            }
            Spacer()
        }
        .card()
    }

    private var planCard: some View {
        let newDone = today?.newWords ?? 0
        let reviewed = today?.cardsReviewed ?? 0
        let listeningDone = (today?.listeningSessions ?? 0) > 0
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's plan").font(.headline)
            Text("Learn \(newTarget) words, review \(dueCount) words, complete one listening exercise.")
                .font(.subheadline).foregroundStyle(.secondary)

            NavigationLink { FlashcardsView() } label: {
                planRow("Learn new words", "\(min(newDone, newTarget))/\(newTarget)", done: newDone >= newTarget && newTarget > 0)
            }
            NavigationLink { FlashcardsView() } label: {
                planRow("Review due words", dueCount == 0 ? "\(reviewed) done" : "\(dueCount) due", done: dueCount == 0 && reviewed > 0)
            }
            NavigationLink { ExamPracticeView(section: .listening) } label: {
                planRow("Listening exercise", listeningDone ? "done" : "10 questions", done: listeningDone)
            }
        }
        .buttonStyle(.plain)
        .card()
    }

    private func planRow(_ title: String, _ detail: String, done: Bool) -> some View {
        HStack {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? .green : .secondary)
            Text(title)
            Spacer()
            Text(detail).foregroundStyle(.secondary).font(.subheadline)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder private var continueButton: some View {
        let needsCards = dueCount > 0 || (today?.newWords ?? 0) < newTarget
        NavigationLink {
            if needsCards { FlashcardsView() } else { ExamPracticeView(section: .listening) }
        } label: {
            Label("Continue learning", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.tint, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
        }
    }

    private func statTile(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HSK \(level)").font(.headline)
                Spacer()
                Text("\(learnedCount)/\(levelWords.count) words started").font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(learnedCount), total: Double(max(levelWords.count, 1)))
        }
        .card()
    }

    private var examCountdown: some View {
        let date = Date(timeIntervalSince1970: examDate)
        let daysLeft = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                                       to: Calendar.current.startOfDay(for: date)).day ?? 0
        return HStack {
            Image(systemName: "calendar.badge.clock").foregroundStyle(.purple)
            Text(daysLeft >= 0 ? "\(daysLeft) days until your exam" : "Exam date has passed")
            Spacer()
            Text(date, style: .date).foregroundStyle(.secondary).font(.subheadline)
        }
        .card()
    }
}

extension View {
    func card() -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.level) private var level = 1
    @AppStorage(Settings.dailyGoal) private var goalMinutes = 15
    @AppStorage(Settings.newPerDay) private var newPerDay = 10
    @AppStorage(Settings.examDate) private var examDate: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Study plan") {
                    Picker("Target level", selection: $level) {
                        ForEach(1...3, id: \.self) { Text("HSK \($0)").tag($0) }
                    }
                    Picker("Daily goal", selection: $goalMinutes) {
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                    }
                    Stepper("New words per day: \(newPerDay)", value: $newPerDay, in: 5...30, step: 5)
                }
                Section("Exam date") {
                    Toggle("I have an exam date", isOn: Binding(
                        get: { examDate > 0 },
                        set: { examDate = $0 ? Date().addingTimeInterval(60 * 60 * 24 * 60).timeIntervalSince1970 : 0 }))
                    if examDate > 0 {
                        DatePicker("Exam day", selection: Binding(
                            get: { Date(timeIntervalSince1970: examDate) },
                            set: { examDate = $0.timeIntervalSince1970 }), in: Date()..., displayedComponents: .date)
                    }
                }
                Section("Syllabus") {
                    LabeledContent("Version", value: Syllabus.name)
                    Text(Syllabus.note).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile & settings")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
