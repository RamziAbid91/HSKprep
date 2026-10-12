import SwiftUI
import SwiftData

@main
struct HSKPrepApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [CardProgress.self, Attempt.self, StudyDay.self, TestResult.self])
    }
}

/// Five main tabs. Profile & settings live behind the person icon on Home.
struct RootView: View {
    @AppStorage(Settings.level) private var level = 1
    @AppStorage(Settings.accent) private var accent = AccentChoice.red.rawValue
    @AppStorage(Settings.appearance) private var appearance = "system"
    @AppStorage(Settings.onboarded) private var onboarded = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
            PracticeView()
                .tabItem { Label("Practice", systemImage: "figure.run") }
            ExamsView()
                .tabItem { Label("Exams", systemImage: "checklist") }
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(AccentChoice(rawValue: accent)?.color ?? Theme.accent)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .fullScreenCover(isPresented: Binding(get: { !onboarded }, set: { if !$0 { onboarded = true } })) {
            OnboardingView()
        }
        // Fetch this level's photos in the background so they're ready (and work offline later).
        .task(id: level) {
            let pictures = VocabularyStore.words(level: level).compactMap(\.emoji)
            await PhotoStore.shared.prefetch(pictures)
        }
    }
}

/// Shared user settings (stored in UserDefaults via @AppStorage).
enum Settings {
    static let level = "level"                 // Int 1–3
    static let dailyGoal = "dailyGoalMinutes"   // Int 10/15/20/30
    static let newPerDay = "newWordsPerDay"     // Int
    static let examDate = "examDate"           // Double timeIntervalSince1970, 0 = none
    // Personalization
    static let onboarded = "onboarded"         // Bool
    static let name = "learnerName"            // String
    static let goal = "learningGoal"           // LearningGoal raw value
    static let focus = "focusSkill"            // FocusSkill raw value
    static let showPinyin = "showPinyin"       // Bool, default true
    static let hanziScale = "hanziScale"       // Double 0.85 / 1 / 1.25
    static let pictureScale = "pictureScale"   // Double 0.8 / 1 / 1.3
    static let autoplay = "autoplayAudio"      // Bool, default true
    static let accent = "accentColor"          // AccentChoice raw value
    static let appearance = "appearance"       // "system" | "light" | "dark"
    static let scenesInPractice = "scenesInPractice" // Bool, default true
    static let scenesInExam = "scenesInExam"         // Bool, default false
    static let reminderOn = "reminderOn"       // Bool
    static let reminderTime = "reminderTime"   // Double seconds after midnight

    static func bool(_ key: String, default value: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? value
    }
    static func double(_ key: String, default value: Double) -> Double {
        let v = UserDefaults.standard.double(forKey: key)
        return v == 0 ? value : v
    }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case red, jade, blue, purple, ink
    var id: String { rawValue }
    var name: String {
        switch self {
        case .red: "Chinese red"
        case .jade: "Jade"
        case .blue: "Porcelain blue"
        case .purple: "Plum"
        case .ink: "Ink"
        }
    }
    var color: Color {
        switch self {
        case .red: Color(red: 0.84, green: 0.18, blue: 0.20)
        case .jade: Color(red: 0.10, green: 0.56, blue: 0.46)
        case .blue: Color(red: 0.16, green: 0.38, blue: 0.78)
        case .purple: Color(red: 0.52, green: 0.24, blue: 0.62)
        case .ink: Color(red: 0.20, green: 0.22, blue: 0.27)
        }
    }
    /// Second colour of the gradient on the Home card.
    var partner: Color {
        switch self {
        case .red: Color(red: 0.93, green: 0.40, blue: 0.22)
        case .jade: Color(red: 0.28, green: 0.72, blue: 0.52)
        case .blue: Color(red: 0.30, green: 0.58, blue: 0.92)
        case .purple: Color(red: 0.80, green: 0.36, blue: 0.56)
        case .ink: Color(red: 0.42, green: 0.44, blue: 0.50)
        }
    }
}

/// Colours used across the app.
enum Theme {
    private static var choice: AccentChoice {
        AccentChoice(rawValue: UserDefaults.standard.string(forKey: Settings.accent) ?? "") ?? .red
    }
    /// The learner's accent colour (Chinese red by default).
    static var accent: Color { choice.color }
    static let gold = Color(red: 0.95, green: 0.68, blue: 0.18)
    static let jade = Color(red: 0.12, green: 0.62, blue: 0.50)

    static func levelColor(_ level: Int) -> Color {
        switch level {
        case 1: jade
        case 2: Color(red: 0.20, green: 0.45, blue: 0.85)
        default: Color(red: 0.55, green: 0.30, blue: 0.80)
        }
    }

    static func levelGradient(_ level: Int) -> LinearGradient {
        LinearGradient(colors: [levelColor(level), levelColor(level).opacity(0.7)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var heroGradient: LinearGradient {
        LinearGradient(colors: [choice.color, choice.partner], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
