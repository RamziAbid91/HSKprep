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
                    heroCard
                    continueButton
                    planCard
                    wordOfTheDay
                    tipCard
                    HStack(spacing: 12) {
                        statTile("\(learnedCount)", "words started", "character.book.closed.fill", Theme.jade)
                        statTile("\(weekMinutes)", "min this week", "clock.fill", .blue)
                    }
                    levelCard
                    if examDate > 0 { examCountdown }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button { showSettings = true } label: { Image(systemName: "person.crop.circle") }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    // MARK: Cards

    /// Greeting, level and today's goal ring on a red gradient.
    private var heroCard: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting).font(.system(size: 34, weight: .heavy))
                Text("HSK \(level) · \(Date.now.formatted(.dateTime.weekday(.wide).day().month()))")
                    .font(.subheadline).opacity(0.9)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("\(Stats.streak(days)) day streak")
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.white.opacity(0.2), in: Capsule())
            }
            Spacer()
            ZStack {
                Circle().stroke(.white.opacity(0.25), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(1, Double(minutesToday) / Double(max(goalMinutes, 1))))
                    .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: minutesToday)
                VStack(spacing: 0) {
                    Text("\(minutesToday)").font(.title.bold())
                    Text("/\(goalMinutes) min").font(.caption2)
                }
            }
            .frame(width: 92, height: 92)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 6)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "早上好!"
        case 12..<18: "下午好!"
        default: "晚上好!"
        }
    }

    /// A different word each day, with its photo.
    @ViewBuilder private var wordOfTheDay: some View {
        let pictured = levelWords.filter { $0.emoji != nil }
        if !pictured.isEmpty {
            let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
            let word = pictured[day % pictured.count]
            NavigationLink { WordDetailView(word: word) } label: {
                HStack(spacing: 14) {
                    PictureView(picture: word.emoji ?? "", size: 84, corner: 14)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORD OF THE DAY").font(.caption2.bold()).foregroundStyle(Theme.accent)
                        Text(word.hanzi).font(.title.bold())
                        Text("\(word.pinyin) · \(word.english)").font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer()
                    AudioButtons(text: word.hanzi).font(.body)
                }
                .card()
            }
            .buttonStyle(.plain)
        }
    }

    private var tipCard: some View {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let tip = StudyTips.all[day % StudyTips.all.count]
        return NavigationLink { StudyTipsView() } label: {
            VStack(alignment: .leading, spacing: 6) {
                Label("Tip of the day", systemImage: "lightbulb.fill").font(.caption.bold()).foregroundStyle(Theme.gold)
                Text(tip.title).font(.headline)
                Text(tip.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
            }
            .card()
        }
        .buttonStyle(.plain)
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
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(.white)
                .shadow(color: Theme.accent.opacity(0.25), radius: 8, y: 4)
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
                .tint(Theme.levelColor(level))
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
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
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
                Section("Audio") {
                    NavigationLink { VoiceSettingsView() } label: {
                        Label("Voice & speed", systemImage: "speaker.wave.2.fill")
                    }
                }
                Section("Photos") {
                    NavigationLink("Photo credits & offline download") { PhotoCreditsView() }
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
