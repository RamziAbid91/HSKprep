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
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
            PracticeView()
                .tabItem { Label("Practice", systemImage: "figure.run") }
            ExamsView()
                .tabItem { Label("Exams", systemImage: "checklist") }
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
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
