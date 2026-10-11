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

/// Speaks Mandarin with an iOS voice the learner picks in Settings (offline).
/// The best quality comes from "Enhanced"/"Premium" voices, which the learner downloads in
/// iOS Settings → Accessibility → Spoken Content → Voices → Chinese.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    enum Speed { case slow, normal, fast
        var factor: Float { switch self { case .slow: 0.7; case .normal: 1.0; case .fast: 1.15 } }
    }

    // UserDefaults keys (also used with @AppStorage in VoiceSettingsView).
    static let mainVoiceKey = "voiceMain"
    static let maleVoiceKey = "voiceMale"
    static let femaleVoiceKey = "voiceFemale"
    static let rateKey = "voiceRate"          // 0.30 … 0.55, default 0.45

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
    }

    // MARK: Voices

    /// Mandarin voices on this device, best quality first. Includes Taiwan & Hong Kong Mandarin voices
    /// only if no mainland voice exists.
    static var chineseVoices: [AVSpeechSynthesisVoice] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let mainland = all.filter { $0.language == "zh-CN" }
        let pool = mainland.isEmpty ? all.filter { $0.language.hasPrefix("zh") } : mainland
        return pool.sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    static func qualityLabel(_ v: AVSpeechSynthesisVoice) -> String {
        switch v.quality {
        case .premium: "Premium"
        case .enhanced: "Enhanced"
        default: "Standard"
        }
    }

    private func voice(forKey key: String) -> AVSpeechSynthesisVoice? {
        guard let id = UserDefaults.standard.string(forKey: key), !id.isEmpty else { return nil }
        return AVSpeechSynthesisVoice(identifier: id)
    }

    /// The learner's chosen voice, or the best installed one.
    var mainVoice: AVSpeechSynthesisVoice? {
        voice(forKey: Self.mainVoiceKey) ?? Self.chineseVoices.first ?? AVSpeechSynthesisVoice(language: "zh-CN")
    }

    private var baseRate: Float {
        let r = UserDefaults.standard.float(forKey: Self.rateKey)
        return r == 0 ? 0.45 : r
    }

    private func utterance(_ text: String, voice: AVSpeechSynthesisVoice?, speed: Speed) -> AVSpeechUtterance {
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = min(AVSpeechUtteranceMaximumSpeechRate, baseRate * speed.factor)
        return u
    }

    // MARK: Speaking

    func speak(_ text: String, speed: Speed = .normal) {
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance(text, voice: mainVoice, speed: speed))
    }

    func speak(_ text: String, slow: Bool) { speak(text, speed: slow ? .slow : .normal) }

    /// Preview a specific voice (Settings).
    func preview(_ voice: AVSpeechSynthesisVoice, text: String = "你好，欢迎学习汉语。我们今天一起加油！") {
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance(text, voice: voice, speed: .normal))
    }

    /// Voices for the man and woman in dialogues: the learner's choice, else a voice of that gender,
    /// else any voice different from the other speaker. `pitch` is used when only one voice exists.
    private func dialogueVoices() -> (male: AVSpeechSynthesisVoice?, female: AVSpeechSynthesisVoice?, samePitch: Bool) {
        let voices = Self.chineseVoices
        let female = voice(forKey: Self.femaleVoiceKey)
            ?? voices.first { $0.gender == .female } ?? mainVoice
        let male = voice(forKey: Self.maleVoiceKey)
            ?? voices.first { $0.gender == .male }
            ?? voices.first { $0.identifier != female?.identifier }
            ?? mainVoice
        return (male, female, male?.identifier == female?.identifier)
    }

    /// Plays a dialogue or passage like the exam recording, then reads the question ("问：…").
    func play(_ lines: [DialogueLine], question: String? = nil, speed: Speed = .normal) {
        synth.stopSpeaking(at: .immediate)
        let v = dialogueVoices()
        for line in lines {
            let u: AVSpeechUtterance
            switch line.speaker {
            case "M":
                u = utterance(line.text, voice: v.male, speed: speed)
                if v.samePitch { u.pitchMultiplier = 0.75 }
            case "F":
                u = utterance(line.text, voice: v.female, speed: speed)
                if v.samePitch { u.pitchMultiplier = 1.2 }
            default:
                u = utterance(line.text, voice: mainVoice, speed: speed)
            }
            u.postUtteranceDelay = 0.6
            synth.speak(u)
        }
        if let question {
            let q = utterance("问：" + question, voice: mainVoice, speed: speed)
            q.preUtteranceDelay = 0.5
            synth.speak(q)
        }
    }

    func stop() { synth.stopSpeaking(at: .immediate) }
}

// MARK: - Voice settings

struct VoiceSettingsView: View {
    @AppStorage(Speaker.mainVoiceKey) private var mainID = ""
    @AppStorage(Speaker.maleVoiceKey) private var maleID = ""
    @AppStorage(Speaker.femaleVoiceKey) private var femaleID = ""
    @AppStorage(Speaker.rateKey) private var rate: Double = 0.45
    @State private var voices = Speaker.chineseVoices

    private var hasGoodVoice: Bool { voices.contains { $0.quality != .default } }

    var body: some View {
        List {
            if !hasGoodVoice {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Get a more natural voice", systemImage: "sparkles").font(.headline)
                        Text("iPhone has free, high-quality Chinese voices you can download:")
                        Text("Settings → Accessibility → Spoken Content → Voices → Chinese (China mainland) → tap a voice marked Enhanced or Premium (e.g. Tingting, Lilian, Yue). Then come back here and pick it.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                ForEach(voices, id: \.identifier) { v in
                    voiceRow(v, selectedID: $mainID, isDefault: mainID.isEmpty && v.identifier == voices.first?.identifier)
                }
            } header: {
                Text("App voice")
            } footer: {
                Text("Used for words, sentences and flashcards. Tap the play button to hear each voice.")
            }

            Section {
                Picker("Man (男)", selection: $maleID) {
                    Text("Automatic").tag("")
                    ForEach(voices, id: \.identifier) { Text(label($0)).tag($0.identifier) }
                }
                Picker("Woman (女)", selection: $femaleID) {
                    Text("Automatic").tag("")
                    ForEach(voices, id: \.identifier) { Text(label($0)).tag($0.identifier) }
                }
                Button("Play a sample dialogue") {
                    Speaker.shared.play([
                        DialogueLine(speaker: "M", text: "你好，你叫什么名字？", pinyin: ""),
                        DialogueLine(speaker: "F", text: "我叫王丽，很高兴认识你。", pinyin: ""),
                    ])
                }
            } header: {
                Text("Dialogue voices (listening & exams)")
            } footer: {
                Text("If only one voice is installed, the app changes its pitch for the man and the woman. Download a second voice for real two-person dialogues.")
            }

            Section("Speed") {
                HStack {
                    Image(systemName: "tortoise")
                    Slider(value: $rate, in: 0.30...0.55, step: 0.05)
                    Image(systemName: "hare")
                }
                Button("Test speed") { Speaker.shared.speak("我每天早上七点起床，然后去学校学习汉语。") }
            }

            Section {
                Button("Refresh voice list") { voices = Speaker.chineseVoices }
            } footer: {
                Text("Downloaded a new voice? Tap refresh.")
            }
        }
        .navigationTitle("Voice")
        .onDisappear { Speaker.shared.stop() }
    }

    private func label(_ v: AVSpeechSynthesisVoice) -> String {
        "\(v.name) · \(Speaker.qualityLabel(v))"
    }

    private func voiceRow(_ v: AVSpeechSynthesisVoice, selectedID: Binding<String>, isDefault: Bool) -> some View {
        HStack {
            Button { selectedID.wrappedValue = v.identifier } label: {
                HStack {
                    Image(systemName: selectedID.wrappedValue == v.identifier || isDefault ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading) {
                        Text(v.name)
                        Text("\(Speaker.qualityLabel(v)) · \(v.gender == .male ? "male" : v.gender == .female ? "female" : "voice") · \(v.language)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button { Speaker.shared.preview(v) } label: { Image(systemName: "play.circle.fill").font(.title2) }
                .buttonStyle(.borderless)
        }
    }
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

    private static let toneSets: [[Character]] = [
        ["ā", "á", "ǎ", "à"], ["ē", "é", "ě", "è"], ["ī", "í", "ǐ", "ì"],
        ["ō", "ó", "ǒ", "ò"], ["ū", "ú", "ǔ", "ù"], ["ǖ", "ǘ", "ǚ", "ǜ"],
    ]

    /// Wrong-tone versions of a pinyin word, e.g. "māma" → "mámà", "mǎma"… (for the tone trainer).
    static func toneVariants(_ pinyin: String, count: Int) -> [String] {
        let chars = Array(pinyin)
        let marked = chars.indices.filter { i in toneSets.contains { $0.contains(chars[i]) } }
        guard !marked.isEmpty else { return [] }
        var out: [String] = []
        var tries = 0
        while out.count < count && tries < 60 {
            tries += 1
            var c = chars
            for i in marked where marked.count == 1 || Bool.random() {
                guard let set = toneSets.first(where: { $0.contains(c[i]) }),
                      let current = set.firstIndex(of: c[i]) else { continue }
                var t = Int.random(in: 0..<4)
                if t == current { t = (t + 1) % 4 }
                c[i] = set[t]
            }
            let v = String(c)
            if v != pinyin && !out.contains(v) { out.append(v) }
        }
        return out
    }
}
