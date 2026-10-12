import SwiftUI
import AVKit

// MARK: - Which photos go with each line

/// Turns the lines of a dialogue/passage into "scene frames": for every line, the photos of
/// the picture-words said in it (e.g. 超市 → supermarket, 面包 → bread).
enum SceneBuilder {
    /// Every vocabulary word, for splitting a sentence into words.
    private static let vocab: [String: Word] = Dictionary(VocabularyStore.all.map { ($0.hanzi, $0) },
                                                          uniquingKeysWith: { a, _ in a })
    private static let maxLength = VocabularyStore.all.map(\.hanzi.count).max() ?? 4

    /// Greedy longest-match: "我们去超市买面包" → 我们 / 去 / 超市 / 买 / 面包.
    static func words(in text: String) -> [Word] {
        let chars = Array(text)
        var i = 0
        var out: [Word] = []
        while i < chars.count {
            var matched = false
            for len in stride(from: min(maxLength, chars.count - i), through: 1, by: -1) {
                if let w = vocab[String(chars[i..<i + len])] {
                    out.append(w); i += len; matched = true; break
                }
            }
            if !matched { i += 1 }
        }
        return out
    }

    /// Pictures (with a real photo) for one line, in the order they're said.
    static func pictures(for text: String) -> [String] {
        var seen = Set<String>()
        return words(in: text).compactMap(\.emoji).filter { PhotoStore.shared.hasPhoto($0) && seen.insert($0).inserted }
    }

    /// One frame per line; a line with no picture-word keeps the previous frame.
    static func frames(for lines: [DialogueLine]) -> [[String]] {
        var last: [String] = []
        var first: [String]? = nil
        let raw = lines.map { line -> [String] in
            let p = pictures(for: line.text)
            if !p.isEmpty { last = p; if first == nil { first = p } }
            return last
        }
        // Lines before the first picture show the first picture.
        return raw.map { $0.isEmpty ? (first ?? []) : $0 }
    }

    static func videoURL(for itemID: String) -> URL? {
        Bundle.main.url(forResource: itemID, withExtension: "mp4", subdirectory: "Videos")
    }

    static func hasScene(lines: [DialogueLine], itemID: String) -> Bool {
        videoURL(for: itemID) != nil || frames(for: lines).contains { !$0.isEmpty }
    }
}

// MARK: - Scene view

/// A short "video" that follows the recording: each line shows photos of what's being said,
/// slowly zooming (Ken Burns effect), with a 男 / 女 badge for who is speaking.
/// If a real clip exists (HSKPrep/Videos/<item id>.mp4) it is shown instead, muted.
struct ListeningSceneView: View {
    let lines: [DialogueLine]
    let itemID: String
    let tag: String

    @ObservedObject private var speaker = Speaker.shared
    @AppStorage(Settings.pictureScale) private var pictureScale = 1.0

    private var frames: [[String]] { SceneBuilder.frames(for: lines) }
    private var isMine: Bool { speaker.activeTag == tag }
    private var finished: Bool { speaker.finishedTag == tag && !isMine }

    /// Line being spoken (the spoken question at the end keeps the last line's frame).
    private var lineIndex: Int? {
        if isMine { return min(max(speaker.currentPart - 1, 0), lines.count - 1) }
        if finished { return lines.count - 1 }
        return nil
    }

    var body: some View {
        ZStack {
            if let url = SceneBuilder.videoURL(for: itemID) {
                SceneVideo(url: url, playing: isMine && speaker.isPlaying)
            } else if let i = lineIndex, frames.indices.contains(i), !frames[i].isEmpty {
                SceneFrame(pictures: frames[i]).id("\(tag)-\(i)")
                    .transition(.opacity)
            } else {
                placeholder
            }

            if let i = lineIndex, lines.indices.contains(i) {
                speakerBadge(lines[i].speaker)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
            }
            if isMine && speaker.isPlaying {
                Label("Scene", systemImage: "film").font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210 * pictureScale)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: 0.5), value: lineIndex)
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "film.stack").font(.largeTitle)
            Text("The scene plays with the recording").font(.caption)
        }
        .foregroundStyle(.white.opacity(0.7))
    }

    @ViewBuilder private func speakerBadge(_ who: String) -> some View {
        if who == "M" || who == "F" {
            HStack(spacing: 4) {
                Image(systemName: who == "M" ? "figure.stand" : "figure.stand.dress")
                Text(who == "M" ? "男 man" : "女 woman")
            }
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(who == "M" ? Color.blue.opacity(0.85) : Color.pink.opacity(0.85), in: Capsule())
            .foregroundStyle(.white)
        }
    }
}

/// One line's photos: cycles through them every 2.5 s with a slow zoom.
private struct SceneFrame: View {
    let pictures: [String]
    @State private var zoomed = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 2.5)) { context in
            let index = Int(context.date.timeIntervalSinceReferenceDate / 2.5) % max(pictures.count, 1)
            PictureView(picture: pictures[index], layout: .banner(400), corner: 0)
                .scaleEffect(zoomed ? 1.15 : 1.0, anchor: index % 2 == 0 ? .topLeading : .bottomTrailing)
                .id(index)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.6), value: index)
        }
        .onAppear { withAnimation(.easeInOut(duration: 7)) { zoomed = true } }
        .clipped()
    }
}

/// A bundled clip, muted and looping, playing while the recording plays.
private struct SceneVideo: View {
    let url: URL
    let playing: Bool
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        VideoPlayer(player: player)
            .disabled(true)
            .onAppear {
                let item = AVPlayerItem(url: url)
                let p = AVQueuePlayer()
                p.isMuted = true
                looper = AVPlayerLooper(player: p, templateItem: item)
                player = p
                if playing { p.play() }
            }
            .onChange(of: playing) { _, on in on ? player?.play() : player?.pause() }
            .onDisappear { player?.pause() }
    }
}
