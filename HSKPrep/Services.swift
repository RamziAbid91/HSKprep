import Foundation
import AVFoundation
import SwiftData
import SwiftUI

// MARK: - Content

enum VocabularyStore {
    static let all: [Word] = {
        guard let url = Bundle.main.url(forResource: "Vocabulary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([Word].self, from: data) else {
            assertionFailure("Vocabulary.json missing or malformed")
            return []
        }
        return words
    }()

    private static let byID: [String: Word] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func words(level: Int) -> [Word] { all.filter { $0.level == level } }
    static func word(id: String) -> Word? { byID[id] }
}

// MARK: - Audio

/// Speaks Mandarin with the built-in iOS voice (offline). Replace with recorded
/// native-speaker audio files later for better quality.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    enum Speed { case slow, normal, fast
        var rate: Float { switch self { case .slow: 0.3; case .normal: 0.45; case .fast: 0.52 } }
    }

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
    }

    func speak(_ text: String, speed: Speed = .normal) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        u.rate = speed.rate
        synth.speak(u)
    }

    func speak(_ text: String, slow: Bool) { speak(text, speed: slow ? .slow : .normal) }

    // Two different voices for 男 / 女 when the device has them; otherwise pitch tells them apart.
    private lazy var chineseVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "zh-CN" }
    private lazy var maleVoice = chineseVoices.first { $0.gender == .male }
    private lazy var femaleVoice = chineseVoices.first { $0.gender == .female }

    /// Plays a dialogue or passage like the exam recording, then reads the question ("问：…").
    func play(_ lines: [DialogueLine], question: String? = nil, speed: Speed = .normal) {
        synth.stopSpeaking(at: .immediate)
        for line in lines {
            let u = AVSpeechUtterance(string: line.text)
            u.rate = speed.rate
            u.postUtteranceDelay = 0.6
            switch line.speaker {
            case "M":
                u.voice = maleVoice ?? AVSpeechSynthesisVoice(language: "zh-CN")
                if maleVoice == nil { u.pitchMultiplier = 0.75 }
            case "F":
                u.voice = femaleVoice ?? AVSpeechSynthesisVoice(language: "zh-CN")
                if femaleVoice == nil { u.pitchMultiplier = 1.2 }
            default:
                u.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            }
            synth.speak(u)
        }
        if let question {
            let q = AVSpeechUtterance(string: "问：" + question)
            q.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            q.rate = speed.rate
            q.preUtteranceDelay = 0.5
            synth.speak(q)
        }
    }

    func stop() { synth.stopSpeaking(at: .immediate) }
}

/// Small replay + slow-replay buttons used everywhere.
struct AudioButtons: View {
    let text: String
    var speed: Speaker.Speed = .normal
    var body: some View {
        HStack(spacing: 20) {
            Button { Speaker.shared.speak(text, speed: speed) } label: { Image(systemName: "speaker.wave.2.fill") }
            Button { Speaker.shared.speak(text, speed: .slow) } label: { Image(systemName: "tortoise.fill") }
        }
        .buttonStyle(.borderless)
        .font(.title3)
    }
}

// MARK: - Tracking

/// Writes study activity. Call from views (main thread) with the view's modelContext.
enum Tracker {
    static func today(_ ctx: ModelContext) -> StudyDay {
        let day = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<StudyDay>(predicate: #Predicate { $0.day == day })
        if let existing = try? ctx.fetch(descriptor).first { return existing }
        let new = StudyDay(day: day)
        ctx.insert(new)
        return new
    }

    static func record(_ ctx: ModelContext, skill: Skill, itemID: String, correct: Bool) {
        ctx.insert(Attempt(skill: skill, itemID: itemID, correct: correct))
        if skill != .vocabulary { today(ctx).exercisesDone += 1 }
        try? ctx.save()
    }

    static func addTime(_ ctx: ModelContext, seconds: Int) {
        guard seconds > 0 else { return }
        today(ctx).seconds += min(seconds, 60 * 60)   // cap one session at 1h (app left open)
        try? ctx.save()
    }
}

/// Adds time spent on a screen to today's study minutes.
struct StudyTimer: ViewModifier {
    @Environment(\.modelContext) private var ctx
    @State private var start: Date?
    func body(content: Content) -> some View {
        content
            .onAppear { start = .now }
            .onDisappear {
                if let s = start { Tracker.addTime(ctx, seconds: Int(Date().timeIntervalSince(s))) }
                start = nil
            }
    }
}
extension View { func studyTimer() -> some View { modifier(StudyTimer()) } }

// MARK: - Stats

enum Stats {
    /// Consecutive active days ending today (or yesterday, if today hasn't started yet).
    static func streak(_ days: [StudyDay]) -> Int {
        let cal = Calendar.current
        let active = Set(days.filter(\.isActive).map { cal.startOfDay(for: $0.day) })
        var cursor = cal.startOfDay(for: .now)
        if !active.contains(cursor) { cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
        var count = 0
        while active.contains(cursor) {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    static func accuracy(_ attempts: [Attempt], skill: Skill, days: Int = 30) -> Double? {
        let since = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        let relevant = attempts.filter { $0.skill == skill && $0.date >= since }
        guard !relevant.isEmpty else { return nil }
        return Double(relevant.filter(\.correct).count) / Double(relevant.count)
    }

    struct MistakeItem: Identifiable {
        let word: Word
        let misses: Int
        var id: String { word.id }
    }

    /// Words whose most recent answer was wrong, most-missed first.
    static func mistakeWords(_ attempts: [Attempt]) -> [MistakeItem] {
        var latest: [String: Attempt] = [:]
        var misses: [String: Int] = [:]
        for a in attempts where VocabularyStore.word(id: a.itemID) != nil {
            if !a.correct { misses[a.itemID, default: 0] += 1 }
            if let cur = latest[a.itemID], cur.date >= a.date { continue }
            latest[a.itemID] = a
        }
        return latest.values
            .filter { !$0.correct }
            .compactMap { a in VocabularyStore.word(id: a.itemID).map { MistakeItem(word: $0, misses: misses[a.itemID] ?? 1) } }
            .sorted { $0.misses > $1.misses }
    }

    /// Rough readiness estimate (0–1): 60% vocabulary mastery, 40% recent mock exam average.
    static func readiness(level: Int, progress: [CardProgress], tests: [TestResult]) -> Double {
        let ids = Set(VocabularyStore.words(level: level).map(\.id))
        guard !ids.isEmpty else { return 0 }
        let mastered = progress.filter { ids.contains($0.wordID) && $0.isMastered }.count
        let vocab = Double(mastered) / Double(ids.count)
        let recent = tests.filter { $0.level == level }.sorted { $0.date > $1.date }.prefix(3)
        guard !recent.isEmpty else { return vocab * 0.6 }
        let exam = Double(recent.map(\.percent).reduce(0, +)) / Double(recent.count) / 100
        return vocab * 0.6 + exam * 0.4
    }
}

// MARK: - Pinyin

enum Pinyin {
    /// Lenient comparison for typing practice: ignores tones, spaces, apostrophes, case; accepts v for ü.
    static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "v", with: "u")
            .folding(options: .diacriticInsensitive, locale: .init(identifier: "en"))
            .filter { $0.isLetter }
    }
    static func matches(_ typed: String, _ answer: String) -> Bool {
        let t = normalize(typed)
        return !t.isEmpty && t == normalize(answer)
    }
}
