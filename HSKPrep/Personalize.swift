import SwiftUI
import UserNotifications

// MARK: - Learner profile options

enum LearningGoal: String, CaseIterable, Identifiable {
    case exam, travel, work, culture, school
    var id: String { rawValue }
    var title: String {
        switch self {
        case .exam: "Pass the HSK exam"
        case .travel: "Travel in China"
        case .work: "Work & business"
        case .culture: "Culture, films & friends"
        case .school: "School or university"
        }
    }
    var icon: String {
        switch self {
        case .exam: "checkmark.seal.fill"
        case .travel: "airplane"
        case .work: "briefcase.fill"
        case .culture: "theatermasks.fill"
        case .school: "graduationcap.fill"
        }
    }
    /// Shown on the Home screen under the greeting.
    var motto: String {
        switch self {
        case .exam: "Every review brings you closer to your HSK certificate."
        case .travel: "Listening practice today = easier conversations on your trip."
        case .work: "Clear Chinese builds trust with colleagues and clients."
        case .culture: "Each word unlocks more films, songs and friendships."
        case .school: "Small daily steps add up to great results."
        }
    }
}

enum FocusSkill: String, CaseIterable, Identifiable {
    case balanced, listening, reading, vocabulary, grammar
    var id: String { rawValue }
    var title: String {
        switch self {
        case .balanced: "A bit of everything"
        case .listening: "Listening 听力"
        case .reading: "Reading 阅读"
        case .vocabulary: "Vocabulary 词汇"
        case .grammar: "Grammar 语法"
        }
    }
    var icon: String {
        switch self {
        case .balanced: "circle.grid.2x2.fill"
        case .listening: "headphones"
        case .reading: "text.book.closed.fill"
        case .vocabulary: "character.book.closed.fill"
        case .grammar: "text.word.spacing"
        }
    }
}

enum Profile {
    static var name: String { UserDefaults.standard.string(forKey: Settings.name) ?? "" }
    static var goal: LearningGoal { LearningGoal(rawValue: UserDefaults.standard.string(forKey: Settings.goal) ?? "") ?? .exam }
    static var focus: FocusSkill { FocusSkill(rawValue: UserDefaults.standard.string(forKey: Settings.focus) ?? "") ?? .balanced }
}

// MARK: - Daily reminder

enum Reminder {
    static let id = "daily-study-reminder"

    static func schedule(secondsAfterMidnight: Double) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.removePendingNotificationRequests(withIdentifiers: [id])
            let content = UNMutableNotificationContent()
            let name = Profile.name
            content.title = name.isEmpty ? "该学习了！Time to study" : "\(name)，该学习了！"
            content.body = "A few minutes of HSK practice keeps your streak alive 🔥"
            content.sound = .default
            var comps = DateComponents()
            comps.hour = Int(secondsAfterMidnight) / 3600
            comps.minute = (Int(secondsAfterMidnight) % 3600) / 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

/// Binds a Date picker to "seconds after midnight".
private func timeBinding(_ seconds: Binding<Double>) -> Binding<Date> {
    Binding(
        get: { Calendar.current.startOfDay(for: .now).addingTimeInterval(seconds.wrappedValue) },
        set: { seconds.wrappedValue = $0.timeIntervalSince(Calendar.current.startOfDay(for: $0)) })
}

// MARK: - Onboarding (first launch)

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Settings.onboarded) private var onboarded = false
    @AppStorage(Settings.name) private var name = ""
    @AppStorage(Settings.level) private var level = 1
    @AppStorage(Settings.goal) private var goal = LearningGoal.exam.rawValue
    @AppStorage(Settings.focus) private var focus = FocusSkill.balanced.rawValue
    @AppStorage(Settings.dailyGoal) private var minutes = 15
    @AppStorage(Settings.reminderOn) private var reminderOn = false
    @AppStorage(Settings.reminderTime) private var reminderTime: Double = 19 * 3600

    @State private var page = 0
    private let pages = 5

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                levelPage.tag(1)
                goalPage.tag(2)
                focusPage.tag(3)
                habitPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: page)

            Button {
                if page < pages - 1 { page += 1 } else { finish() }
            } label: {
                Text(page < pages - 1 ? "Continue" : "Start learning 开始！")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled()
    }

    private func finish() {
        if reminderOn { Reminder.schedule(secondsAfterMidnight: reminderTime) }
        onboarded = true
        dismiss()
    }

    private func pageLayout<Content: View>(_ title: String, _ subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title).font(.largeTitle.bold())
                Text(subtitle).foregroundStyle(.secondary)
                content()
            }
            .padding(24)
            .padding(.bottom, 40)
        }
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer()
            Image("Logo").resizable().frame(width: 150, height: 150)
                .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 10)
            Text("欢迎！Welcome").font(.largeTitle.bold())
            Text("Let's set up your HSK study plan. It takes 30 seconds.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            TextField("Your first name (optional)", text: $name)
                .textInputAutocapitalization(.words)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var levelPage: some View {
        pageLayout("Your level", "Which HSK level are you preparing for? You can change it any time.") {
            ForEach(1...3, id: \.self) { lvl in
                choiceRow(selected: level == lvl, icon: "\(lvl).circle.fill",
                          title: "HSK \(lvl)",
                          subtitle: ["Complete beginner — first 150 words", "Everyday basics — 300 words", "Connected Chinese — 600 words"][lvl - 1],
                          color: Theme.levelColor(lvl)) { level = lvl }
            }
        }
    }

    private var goalPage: some View {
        pageLayout("Your goal", "Why are you learning Chinese?") {
            ForEach(LearningGoal.allCases) { g in
                choiceRow(selected: goal == g.rawValue, icon: g.icon, title: g.title, subtitle: nil) { goal = g.rawValue }
            }
        }
    }

    private var focusPage: some View {
        pageLayout("Your focus", "What do you want to improve most? Your daily plan will include extra practice for it.") {
            ForEach(FocusSkill.allCases) { f in
                choiceRow(selected: focus == f.rawValue, icon: f.icon, title: f.title, subtitle: nil) { focus = f.rawValue }
            }
        }
    }

    private var habitPage: some View {
        pageLayout("Your routine", "A little every day beats a lot once a week.") {
            Picker("Daily goal", selection: $minutes) {
                ForEach([10, 15, 20, 30], id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.segmented)
            Toggle("Daily reminder", isOn: $reminderOn).font(.headline)
            if reminderOn {
                DatePicker("Remind me at", selection: timeBinding($reminderTime), displayedComponents: .hourAndMinute)
            }
        }
    }

    private func choiceRow(selected: Bool, icon: String, title: String, subtitle: String?,
                           color: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(selected ? color : .secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(selected ? color : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Personalize (Settings)

struct PersonalizeView: View {
    @AppStorage(Settings.name) private var name = ""
    @AppStorage(Settings.goal) private var goal = LearningGoal.exam.rawValue
    @AppStorage(Settings.focus) private var focus = FocusSkill.balanced.rawValue
    @AppStorage(Settings.showPinyin) private var showPinyin = true
    @AppStorage(Settings.hanziScale) private var hanziScale = 1.0
    @AppStorage(Settings.pictureScale) private var pictureScale = 1.0
    @AppStorage(Settings.autoplay) private var autoplay = true
    @AppStorage(Settings.accent) private var accent = AccentChoice.red.rawValue
    @AppStorage(Settings.appearance) private var appearance = "system"
    @AppStorage(Settings.scenesInPractice) private var scenesInPractice = true
    @AppStorage(Settings.scenesInExam) private var scenesInExam = false
    @AppStorage(Settings.reminderOn) private var reminderOn = false
    @AppStorage(Settings.reminderTime) private var reminderTime: Double = 19 * 3600

    var body: some View {
        Form {
            Section("About you") {
                TextField("First name", text: $name)
                Picker("Goal", selection: $goal) {
                    ForEach(LearningGoal.allCases) { Label($0.title, systemImage: $0.icon).tag($0.rawValue) }
                }
                Picker("Focus", selection: $focus) {
                    ForEach(FocusSkill.allCases) { Label($0.title, systemImage: $0.icon).tag($0.rawValue) }
                }
            }

            Section {
                Toggle("Show pinyin", isOn: $showPinyin)
                Picker("Chinese character size", selection: $hanziScale) {
                    Text("Small").tag(0.85); Text("Normal").tag(1.0); Text("Large").tag(1.25)
                }
                Picker("Picture size", selection: $pictureScale) {
                    Text("Small").tag(0.8); Text("Normal").tag(1.0); Text("Large").tag(1.3)
                }
                Toggle("Play audio automatically", isOn: $autoplay)
            } header: {
                Text("Learning display")
            } footer: {
                Text("Turn pinyin off to train reading characters on their own. Tap any photo to see it full screen; long-press an answer picture to enlarge it.")
            }

            Section {
                Toggle("Video scenes in practice", isOn: $scenesInPractice)
                Toggle("Video scenes in exams", isOn: $scenesInExam)
            } header: {
                Text("Listening")
            } footer: {
                Text("While a dialogue or passage plays, an animated scene shows photos of what's being said, line by line. Real exams have no pictures for these questions, so it's off in exams by default.")
            }

            Section("Look") {
                Picker("Colour", selection: $accent) {
                    ForEach(AccentChoice.allCases) { c in
                        Label { Text(c.name) } icon: { Image(systemName: "circle.fill").foregroundStyle(c.color) }
                            .tag(c.rawValue)
                    }
                }
                Picker("Appearance", selection: $appearance) {
                    Text("Automatic").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark")
                }
            }

            Section("Daily reminder") {
                Toggle("Remind me to study", isOn: $reminderOn)
                if reminderOn {
                    DatePicker("Time", selection: timeBinding($reminderTime), displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Personalize")
        .onChange(of: reminderOn) { _, on in on ? Reminder.schedule(secondsAfterMidnight: reminderTime) : Reminder.cancel() }
        .onChange(of: reminderTime) { _, t in if reminderOn { Reminder.schedule(secondsAfterMidnight: t) } }
    }
}


// MARK: - Display helpers that follow the learner's settings

/// Pinyin that hides itself when "Show pinyin" is off — tap to reveal it.
struct PinyinText: View {
    let text: String
    var font: Font = .body
    var color: Color = .secondary
    @AppStorage(Settings.showPinyin) private var showPinyin = true
    @State private var revealed = false

    init(_ text: String, font: Font = .body, color: Color = .secondary) {
        self.text = text; self.font = font; self.color = color
    }

    var body: some View {
        if showPinyin || revealed {
            Text(text).font(font).foregroundStyle(color)
        } else {
            Button { withAnimation { revealed = true } } label: {
                Label("pinyin", systemImage: "eye").font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}

/// Big Chinese characters scaled by the "Chinese character size" setting.
struct HanziFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .medium
    @AppStorage(Settings.hanziScale) private var scale = 1.0
    func body(content: Content) -> some View {
        content.font(.system(size: size * scale, weight: weight))
    }
}

extension View {
    func hanziFont(_ size: CGFloat, weight: Font.Weight = .medium) -> some View {
        modifier(HanziFont(size: size, weight: weight))
    }
}

extension Speaker {
    /// Speaks only if "Play audio automatically" is on.
    func autoSpeak(_ text: String, speed: Speed = .normal, tag: String? = nil) {
        guard Settings.bool(Settings.autoplay, default: true) else { return }
        speak(text, speed: speed, tag: tag)
    }
}
