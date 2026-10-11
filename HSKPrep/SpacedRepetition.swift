import Foundation

/// How well the learner remembered a card.
enum ReviewGrade: Int, CaseIterable {
    case again = 0   // forgot
    case hard  = 3
    case good  = 4
    case easy  = 5

    /// When the card comes back (rough guide shown under the button).
    var hint: String {
        switch self {
        case .again: "< 1 min"
        case .hard:  "soon"
        case .good:  "later"
        case .easy:  "much later"
        }
    }

    var label: String {
        switch self {
        case .again: "Again"
        case .hard:  "Hard"
        case .good:  "Good"
        case .easy:  "Easy"
        }
    }
}

/// SM-2 spaced repetition (the algorithm behind Anki / SuperMemo 2).
enum SpacedRepetition {
    static func review(_ card: CardProgress, grade: ReviewGrade, now: Date = .now) {
        let q = Double(grade.rawValue)

        if grade == .again {
            card.repetitions = 0
            card.intervalDays = 0          // show again this session / today
        } else {
            card.repetitions += 1
            switch card.repetitions {
            case 1:  card.intervalDays = 1
            case 2:  card.intervalDays = 6
            default: card.intervalDays = Int((Double(card.intervalDays) * card.easeFactor).rounded())
            }
            if grade == .easy { card.intervalDays = Int(Double(card.intervalDays) * 1.3) + 1 }
        }

        // Update ease factor, never below 1.3
        let newEF = card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        card.easeFactor = max(1.3, newEF)

        card.lastReviewed = now
        card.dueDate = grade == .again
            ? now.addingTimeInterval(60)   // 1 minute
            : Calendar.current.date(byAdding: .day, value: card.intervalDays, to: now) ?? now
    }
}
