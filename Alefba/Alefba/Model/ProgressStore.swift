import Foundation
import Observation

/// Stars per letter, practice days and today's count, saved in UserDefaults.
@Observable
final class ProgressStore {
    static let dailyGoal = 3
    private static let storageKey = "alefba.progress.v1"

    private(set) var bestStars: [String: Int] = [:]
    private(set) var wordStars: [String: Int] = [:]
    private(set) var practiceDays: Set<String> = []
    private var todayKey: String = ""
    private var todayLetters: Set<String> = []

    private struct Saved: Codable {
        var bestStars: [String: Int]
        var practiceDays: [String]
        var todayKey: String
        var todayLetters: [String]
        var wordStars: [String: Int]?
    }

    init() {
        load()
    }

    // MARK: Reading

    func stars(for letter: Letter) -> Int { bestStars[letter.char] ?? 0 }

    func isTraced(_ letter: Letter) -> Bool { stars(for: letter) > 0 }

    func tracedCount(in family: LetterFamily) -> Int {
        family.letters.filter { isTraced($0) }.count
    }

    func stars(in family: LetterFamily) -> Int {
        family.letters.reduce(0) { $0 + stars(for: $1) }
    }

    var totalStars: Int { bestStars.values.reduce(0, +) + wordStars.values.reduce(0, +) }

    // MARK: Favourite words

    func stars(for word: FavoriteWord) -> Int { wordStars[word.id] ?? 0 }

    func lettersLearned(in word: FavoriteWord) -> Int {
        word.letters.filter { isTraced($0) }.count
    }

    func isReady(_ word: FavoriteWord) -> Bool {
        lettersLearned(in: word) == word.letters.count
    }

    func record(_ word: FavoriteWord, stars: Int) {
        guard stars > 0 else { return }
        wordStars[word.id] = max(wordStars[word.id] ?? 0, stars)
        markPractice(id: "word:" + word.id)
    }

    var todayCount: Int {
        todayKey == Self.dayKey(Date()) ? todayLetters.count : 0
    }

    var allTraced: Bool { Alphabet.allLetters.allSatisfy { isTraced($0) } }

    /// First letter (in teaching order) he hasn't traced yet.
    var nextLetter: Letter {
        Alphabet.allLetters.first { !isTraced($0) } ?? Alphabet.allLetters[0]
    }

    var currentFamily: LetterFamily { Alphabet.family(of: nextLetter) }

    func practiced(on date: Date) -> Bool {
        practiceDays.contains(Self.dayKey(date))
    }

    /// Consecutive practice days ending today (or yesterday, if today isn't done yet).
    var streak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if !practiced(on: day), let yesterday = cal.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var count = 0
        while practiced(on: day) {
            count += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// Monday to Sunday of the current week.
    var currentWeek: [Date] {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    // MARK: Writing

    func record(_ letter: Letter, stars: Int) {
        guard stars > 0 else { return }
        bestStars[letter.char] = max(bestStars[letter.char] ?? 0, stars)
        markPractice(id: letter.char)
    }

    private func markPractice(id: String) {
        let today = Self.dayKey(Date())
        if todayKey != today {
            todayKey = today
            todayLetters = []
        }
        todayLetters.insert(id)
        practiceDays.insert(today)
        save()
    }

    func resetAll() {
        bestStars = [:]
        wordStars = [:]
        practiceDays = []
        todayKey = ""
        todayLetters = []
        save()
    }

    // MARK: Storage

    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        bestStars = saved.bestStars
        practiceDays = Set(saved.practiceDays)
        todayKey = saved.todayKey
        todayLetters = Set(saved.todayLetters)
        wordStars = saved.wordStars ?? [:]
    }

    private func save() {
        let saved = Saved(bestStars: bestStars,
                          practiceDays: Array(practiceDays),
                          todayKey: todayKey,
                          todayLetters: Array(todayLetters),
                          wordStars: wordStars)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
