import Foundation

enum WordCategory: String, CaseIterable, Identifiable {
    case people, everyday, flirty, cheeky
    var id: String { rawValue }

    var title: String {
        switch self {
        case .people: return "People"
        case .everyday: return "Everyday"
        case .flirty: return "Flirty"
        case .cheeky: return "Cheeky"
        }
    }
}

struct FavoriteWord: Identifiable, Hashable {
    let text: String
    let latin: String
    let meaning: String
    let category: WordCategory

    /// e.g. "pier-luigi", used for routes, progress and voice files.
    var id: String {
        let slug = latin.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
        return slug.split(separator: "-").joined(separator: "-")
    }

    var voiceKey: String { "fav-\(id)" }
    var illustrationName: String { "illustration-fav-\(id)" }

    /// The letters, joins and gaps of the word, in reading order (right to left).
    var pieces: [WordPiece] { WordPiece.pieces(of: text) }

    /// Each alphabet letter used in the word, once.
    var letters: [Letter] {
        var seen = Set<String>()
        var result: [Letter] = []
        for piece in pieces {
            if case .letter(_, let letter) = piece, !seen.contains(letter.char) {
                seen.insert(letter.char)
                result.append(letter)
            }
        }
        return result
    }
}

enum WordPiece: Hashable {
    /// What is shown (e.g. "آ") and the alphabet letter it belongs to (ا).
    case letter(String, Letter)
    case join
    case gap
    case space

    static func pieces(of text: String) -> [WordPiece] {
        var result: [WordPiece] = []
        var previous: Letter?
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // spaces and the Persian comma split words
            if scalar == " " || scalar == "\u{060C}" || scalar == "," {
                if previous != nil { result.append(.space) }
                previous = nil
                continue
            }
            // short-vowel marks, zero-width joiners, punctuation: not letters
            if (0x064B...0x065F).contains(value) || value == 0x0670 || value == 0x200C || value == 0x200D { continue }
            let shown = String(scalar)
            guard let letter = Words.alphabetLetter(for: shown) else { continue }
            if let prev = previous {
                result.append(prev.isLoner ? .gap : .join)
            }
            result.append(.letter(shown, letter))
            previous = letter
        }
        if case .space = result.last { result.removeLast() }
        return result
    }
}

enum Words {
    /// Whose words these are; shown as the section title on the home screen.
    static let ownerName = "Carlo"

    /// Turn this off to hide the Cheeky tab (e.g. before an App Store release).
    static let showCheeky = true

    static var categories: [WordCategory] {
        WordCategory.allCases.filter { $0 != .cheeky || showCheeky }
    }

    static func words(in category: WordCategory) -> [FavoriteWord] {
        all.filter { $0.category == category }
    }

    static func word(id: String) -> FavoriteWord {
        all.first { $0.id == id } ?? all[0]
    }

    /// Maps a written character to its alphabet letter (آ → ا, Arabic ي/ك → ی/ک).
    static func alphabetLetter(for char: String) -> Letter? {
        let normalized: String
        switch char {
        case "آ", "أ", "إ": normalized = "ا"
        case "ي", "ى": normalized = "ی"
        case "ك": normalized = "ک"
        case "ة": normalized = "ه"
        default: normalized = char
        }
        return Alphabet.allLetters.first { $0.char == normalized }
    }

    private static func w(_ text: String, _ latin: String, _ meaning: String, _ category: WordCategory) -> FavoriteWord {
        FavoriteWord(text: text, latin: latin, meaning: meaning, category: category)
    }

    static let all: [FavoriteWord] = [
        // People
        w("کارلو", "Carlo", "your name", .people),
        w("داوِنی", "D'Aveni", "your surname", .people),
        w("ثنا", "Sana", "Sana", .people),
        w("عباس", "Abbas", "friend", .people),
        w("نیما", "Nima", "friend", .people),
        w("نوید", "Navid", "friend", .people),
        w("شنتیا", "Shantia", "friend", .people),
        w("الِساندرو", "Alessandro", "friend", .people),
        w("پیر لوییجی", "Pier Luigi", "friend", .people),
        w("داداش", "dadash", "bro", .people),

        // Everyday
        w("سلام", "salam", "hi", .everyday),
        w("خدافظ", "khodafez", "bye", .everyday),
        w("آره", "are", "yeah", .everyday),
        w("نه", "na", "no", .everyday),
        w("من", "man", "me / I", .everyday),
        w("چی؟", "chi?", "what?", .everyday),
        w("چیه؟", "chie?", "what is it?", .everyday),
        w("کی؟", "ki?", "who?", .everyday),
        w("برو", "boro", "go!", .everyday),
        w("بریم", "berim", "let's go", .everyday),
        w("بدو", "bodo", "run!", .everyday),
        w("آینه", "ayne", "mirror", .everyday),
        w("آروم باش", "arum bash", "calm down", .everyday),
        w("دم، باز دم!", "dam, bazdam!", "breathe in, breathe out!", .everyday),
        w("بسته!", "baste!", "enough!", .everyday),
        w("خفه شو!", "khafe sho!", "shut up!", .everyday),
        w("بهم دست نزن!", "behem dast nazan!", "don't touch me!", .everyday),
        w("روانی", "ravani", "psycho, crazy", .everyday),
        w("چه خبر؟", "che khabar?", "what's up?", .everyday),
        w("چطوری؟", "chetori?", "how are you?", .everyday),
        w("مرسی", "mersi", "thanks", .everyday),
        w("ولم کن", "velam kon", "leave me alone", .everyday),
        w("حوصله ندارم", "hosele nadaram", "I'm not in the mood", .everyday),
        w("برو گمشو", "boro gomsho", "get lost", .everyday),
        w("برو بابا!", "boro baba!", "oh, come on! / get outta here!", .everyday),
        w("جیش دارم", "jish daram", "I need to pee", .everyday),
        w("گشنمه", "goshname", "I'm hungry", .everyday),
        w("خستمه", "khastame", "I'm tired", .everyday),

        // Flirty
        w("زیبا رو", "ziba ru", "beautiful-faced", .flirty),
        w("خوشگل", "khoshgel", "pretty, good-looking", .flirty),
        w("خوشگله!", "khoshgele!", "hey, gorgeous!", .flirty),
        w("جوجو", "juju", "chickie (cute nickname)", .flirty),
        w("عشقم", "eshgham", "my love", .flirty),
        w("عزیزم", "azizam", "my dear", .flirty),
        w("نفسم", "nafasam", "my darling (lit. \"my breath\")", .flirty),
        w("عزیز دلم", "azize delam", "sweetheart", .flirty),
        w("خوشتیپ", "khoshtip", "stylish, good-looking", .flirty),
        w("دیوونه", "divune", "crazy one (affectionate)", .flirty),
        w("دوستت دارم", "dustet daram", "I love you", .flirty),
        w("دلم برات تنگ شده", "delam barat tang shode", "I miss you", .flirty),
        w("خیلی خوشگلی", "kheyli khoshgeli", "you're so pretty", .flirty),
        w("قربونت برم", "ghorbunet beram", "aww, I adore you", .flirty),
        w("دورت بگردم", "doret begardam", "aww, I'd do anything for you", .flirty),
        w("بوس", "bus", "kiss", .flirty),
        w("بوس بده", "bus bede", "give me a kiss", .flirty),
        w("بغلم کن", "baghalam kon", "hug me", .flirty),
        w("جووون!", "jooon!", "mmm, yes! (ooh, lovely!)", .flirty),

        // Cheeky
        w("میمون", "meymun", "monkey (cheeky insult)", .cheeky),
        w("کس", "kos", "pussy (vulgar)", .cheeky),
        w("کیر", "kir", "dick (vulgar)", .cheeky),
        w("کیری", "kiri", "crappy, rubbish (vulgar)", .cheeky),
        w("کسکش", "koskesh", "bastard (vulgar insult)", .cheeky),
        w("جاکش", "jakesh", "pimp (vulgar insult)", .cheeky),
        w("کسخل", "koskhol", "idiot, nutcase", .cheeky),
        w("کس مغز", "kos maghz", "airhead, idiot", .cheeky),
        w("گوه", "goh", "shit", .cheeky),
        w("گوه نخور", "goh nakhor", "shut up (lit. \"don't eat shit\")", .cheeky),
        w("کسشر", "kossher", "bullshit", .cheeky),
        w("ریدم", "ridam", "I'm screwed (lit. \"I shat\")", .cheeky),
        w("کون", "kun", "ass", .cheeky),
        w("خر", "khar", "donkey, idiot", .cheeky),
        w("گاو", "gav", "cow, moron", .cheeky),
        w("احمق", "ahmagh", "idiot", .cheeky),
        w("بیشعور", "bishur", "jerk", .cheeky),
        w("عوضی", "avazi", "jerk, creep", .cheeky),
        w("کثافت", "kesafat", "scumbag (lit. \"filth\")", .cheeky),
        w("لاشی", "lashi", "lowlife", .cheeky),
        w("خفه خون بگیر", "khafe khun begir", "shut your trap", .cheeky)
    ]
}
