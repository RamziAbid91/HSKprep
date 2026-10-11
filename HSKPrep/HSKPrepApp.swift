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
        .tint(Theme.accent)
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
    static let dailyGoal = "dailyGoalMinutes"   // Int 15 or 20
    static let newPerDay = "newWordsPerDay"     // Int
    static let examDate = "examDate"           // Double timeIntervalSince1970, 0 = none
}

/// Colours used across the app.
enum Theme {
    /// Chinese red.
    static let accent = Color(red: 0.84, green: 0.18, blue: 0.20)
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

    static let heroGradient = LinearGradient(colors: [accent, Color(red: 0.93, green: 0.40, blue: 0.22)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
}
