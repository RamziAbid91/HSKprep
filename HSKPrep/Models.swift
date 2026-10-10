import Foundation
import SwiftData

/// Which syllabus the bundled content follows. Shown in Settings so learners know.
enum Syllabus {
    static let name = "HSK 2.0 (levels 1–6)"
    static let note = "Starter word list for HSK 1–3. Verify against the official vocabulary lists before release. Practice questions are original, not official exam material."
}

/// A vocabulary entry loaded from Vocabulary.json (read-only content).
struct Word: Codable, Identifiable, Hashable {
    let id: String        // e.g. "1-001" — keep stable, progress is keyed on it
    let hanzi: String
    let pinyin: String
    let english: String
    let level: Int
    let example: String?
    let examplePinyin: String?
    let exampleEnglish: String?
}

/// Skill areas tracked for accuracy and weak-area analysis.
enum Skill: String, CaseIterable, Identifiable {
    case vocabulary, listening, reading, grammar, typing
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .vocabulary: "character.book.closed"
        case .listening:  "headphones"
        case .reading:    "text.book.closed"
        case .grammar:    "text.word.spacing"
        case .typing:     "keyboard"
        }
    }
}

/// Spaced-repetition state for one word.
@Model
final class CardProgress {
    @Attribute(.unique) var wordID: String
    var easeFactor: Double = 2.5
    var intervalDays: Int = 0
    var repetitions: Int = 0
    var dueDate: Date = Date.distantPast
    var lastReviewed: Date?

    /// "Mastered" = remembered with an interval of a week or more.
    var isMastered: Bool { intervalDays >= 7 }
    var isLearning: Bool { repetitions > 0 && !isMastered }

    init(wordID: String) { self.wordID = wordID }
}

/// Every answer the learner gives (flashcard, quiz, grammar, exam).
/// Used for accuracy per skill and to turn mistakes into revision sessions.
@Model
final class Attempt {
    var date: Date
    var skillRaw: String
    var itemID: String      // word id ("1-001") or grammar id ("g-shi")
    var correct: Bool

    var skill: Skill { Skill(rawValue: skillRaw) ?? .vocabulary }

    init(skill: Skill, itemID: String, correct: Bool, date: Date = .now) {
        self.skillRaw = skill.rawValue
        self.itemID = itemID
        self.correct = correct
        self.date = date
    }
}

/// What the learner did on one calendar day — powers the daily plan, streak and calendar.
@Model
final class StudyDay {
    @Attribute(.unique) var day: Date
    var seconds: Int = 0
    var cardsReviewed: Int = 0
    var newWords: Int = 0
    var listeningSessions: Int = 0
    var exercisesDone: Int = 0

    var minutes: Int { seconds / 60 }
    var isActive: Bool { seconds >= 60 || cardsReviewed > 0 || exercisesDone > 0 }

    init(day: Date) { self.day = day }
}

/// One completed mock exam.
@Model
final class TestResult {
    var date: Date
    var level: Int
    var correct: Int
    var total: Int
    var secondsUsed: Int
    var listeningCorrect: Int = 0
    var listeningTotal: Int = 0
    var readingCorrect: Int = 0
    var readingTotal: Int = 0

    var percent: Int { total == 0 ? 0 : Int((Double(correct) / Double(total) * 100).rounded()) }

    init(date: Date = .now, level: Int, correct: Int, total: Int, secondsUsed: Int,
         listeningCorrect: Int = 0, listeningTotal: Int = 0, readingCorrect: Int = 0, readingTotal: Int = 0) {
        self.date = date
        self.level = level
        self.correct = correct
        self.total = total
        self.secondsUsed = secondsUsed
        self.listeningCorrect = listeningCorrect
        self.listeningTotal = listeningTotal
        self.readingCorrect = readingCorrect
        self.readingTotal = readingTotal
    }
}
