import Foundation

struct LetterForm: Hashable {
    let label: String
    let text: String
}

struct Letter: Identifiable, Hashable {
    let char: String
    let name: String
    /// Sound written with Latin letters, shown in blue under the letter.
    let sound: String
    let dots: String
    /// Italian (or other familiar) pronunciation hint.
    let hint: String
    let word: String
    let wordLatin: String
    let meaning: String

    var id: String { char }

    static let lonerChars: Set<String> = ["ا", "د", "ذ", "ر", "ز", "ژ", "و"]

    /// True for the 7 letters that never join the letter after them.
    var isLoner: Bool { Self.lonerChars.contains(char) }

    /// Name of the optional illustration in Assets.xcassets, e.g. "illustration-boz".
    var illustrationName: String { "illustration-\(wordLatin)" }

    var forms: [LetterForm] {
        let t = "\u{0640}" // tatweel, the connecting line
        if isLoner {
            return [
                LetterForm(label: "alone", text: char),
                LetterForm(label: "start", text: char),
                LetterForm(label: "middle", text: t + char),
                LetterForm(label: "end", text: t + char)
            ]
        }
        return [
            LetterForm(label: "alone", text: char),
            LetterForm(label: "start", text: char + t),
            LetterForm(label: "middle", text: t + char + t),
            LetterForm(label: "end", text: t + char)
        ]
    }
}

struct LetterFamily: Identifiable, Hashable {
    let id: String
    let name: String
    let blurb: String
    let tint: Tint
    let letters: [Letter]
}

private func L(_ char: String, _ name: String, _ sound: String, _ dots: String, _ hint: String,
               _ word: String, _ latin: String, _ meaning: String) -> Letter {
    Letter(char: char, name: name, sound: sound, dots: dots, hint: hint,
           word: word, wordLatin: latin, meaning: meaning)
}

enum Alphabet {
    static let families: [LetterFamily] = [
        LetterFamily(id: "stick", name: "The stick",
                     blurb: "One tall stroke, top to bottom. The easiest letter to start with.",
                     tint: .turquoise, letters: [
            L("ا", "alef", "a", "No dots", "A long, round “a”, a bit deeper than in casa.", "اسب", "asb", "horse")
        ]),
        LetterFamily(id: "bowl", name: "The bowl",
                     blurb: "One shape, four letters. Only the dots change.",
                     tint: .saffron, letters: [
            L("ب", "be", "b", "1 dot below", "Like the b in bello.", "بز", "boz", "goat"),
            L("پ", "pe", "p", "3 dots below", "Like the p in pane.", "پنیر", "panir", "cheese"),
            L("ت", "te", "t", "2 dots above", "Like the t in tavolo.", "توپ", "tup", "ball"),
            L("ث", "se", "s", "3 dots above", "Like the s in sole. Same sound as س.", "مثلث", "mosallas", "triangle")
        ]),
        LetterFamily(id: "wave", name: "The wave",
                     blurb: "One wavy body. The dots move inside, on top, or disappear.",
                     tint: .coral, letters: [
            L("ج", "jim", "j", "1 dot inside", "Like the g in gelato.", "جوجه", "juje", "chick"),
            L("چ", "che", "ch", "3 dots inside", "Like the c in ciao.", "چای", "chay", "tea"),
            L("ح", "he", "h", "No dots", "A breathy h, like a sigh. In Italian the h is silent!", "حلزون", "halazun", "snail"),
            L("خ", "khe", "kh", "1 dot above", "No Italian match: like the ch in German Bach.", "خرس", "khers", "bear")
        ]),
        LetterFamily(id: "elbow", name: "The elbow",
                     blurb: "A bent elbow. One dot on top turns d into z.",
                     tint: .lapis, letters: [
            L("د", "dāl", "d", "No dots", "Like the d in dado.", "درخت", "derakht", "tree"),
            L("ذ", "zāl", "z", "1 dot above", "Like the z in English zoo, not pizza.", "ذرت", "zorrat", "corn")
        ]),
        LetterFamily(id: "slide", name: "The slide",
                     blurb: "A little slide that dips below the line.",
                     tint: .pistachio, letters: [
            L("ر", "re", "r", "No dots", "Rolled, like the r in Roma.", "روباه", "rubah", "fox"),
            L("ز", "ze", "z", "1 dot above", "Same as zāl: the z in English zoo.", "زنبور", "zanbur", "bee"),
            L("ژ", "zhe", "zh", "3 dots above", "Like the j in French jour.", "ژله", "zhele", "jelly")
        ]),
        LetterFamily(id: "teeth", name: "The teeth",
                     blurb: "Three small teeth and a tail. Three dots on top make it sh.",
                     tint: .rose, letters: [
            L("س", "sin", "s", "No dots", "Like the s in sole.", "سیب", "sib", "apple"),
            L("ش", "shin", "sh", "3 dots above", "Like the sc in scena.", "شیر", "shir", "lion")
        ]),
        LetterFamily(id: "loop", name: "The loop",
                     blurb: "A flat loop and a tail. One dot changes s to z.",
                     tint: .lilac, letters: [
            L("ص", "sād", "s", "No dots", "Same sound as س.", "صابون", "sabun", "soap"),
            L("ض", "zād", "z", "1 dot above", "Same sound as ز.", "حوض", "howz", "pond")
        ]),
        LetterFamily(id: "flag", name: "The flag",
                     blurb: "A loop with a tall pole, like a flag.",
                     tint: .turquoise, letters: [
            L("ط", "tā", "t", "No dots", "Same sound as ت.", "طوطی", "tuti", "parrot"),
            L("ظ", "zā", "z", "1 dot above", "Same sound as ز.", "ظرف", "zarf", "dish")
        ]),
        LetterFamily(id: "mouth", name: "The mouth",
                     blurb: "An open mouth on top and a tail below.",
                     tint: .saffron, letters: [
            L("ع", "eyn", "ʼ", "No dots", "A tiny catch in the throat, like the break in “uh-oh”.", "عسل", "asal", "honey"),
            L("غ", "gheyn", "gh", "1 dot above", "A gargled sound, like a French r in Paris.", "غاز", "ghaz", "goose")
        ]),
        LetterFamily(id: "bud", name: "The bud",
                     blurb: "A round bud on a bowl. Count the dots.",
                     tint: .coral, letters: [
            L("ف", "fe", "f", "1 dot above", "Like the f in fiore.", "فیل", "fil", "elephant"),
            L("ق", "qāf", "gh", "2 dots above", "Same sound as غ.", "قایق", "ghayegh", "boat")
        ]),
        LetterFamily(id: "roof", name: "The roof",
                     blurb: "A tall slanted roof. A second roof line turns k into g.",
                     tint: .lapis, letters: [
            L("ک", "kāf", "k", "No dots", "Like the c in casa.", "کتاب", "ketab", "book"),
            L("گ", "gāf", "g", "An extra roof line", "Like the g in gatto.", "گربه", "gorbe", "cat")
        ]),
        LetterFamily(id: "hook", name: "The hook",
                     blurb: "A tall stroke that curves into a hook.",
                     tint: .pistachio, letters: [
            L("ل", "lām", "l", "No dots", "Like the l in luna.", "لیمو", "limu", "lemon")
        ]),
        LetterFamily(id: "bead", name: "The bead",
                     blurb: "A small round bead with a tail.",
                     tint: .rose, letters: [
            L("م", "mim", "m", "No dots", "Like the m in mare.", "ماه", "mah", "moon")
        ]),
        LetterFamily(id: "cup", name: "The cup",
                     blurb: "A deep cup holding one dot.",
                     tint: .lilac, letters: [
            L("ن", "nun", "n", "1 dot above", "Like the n in naso.", "نان", "nan", "bread")
        ]),
        LetterFamily(id: "curl", name: "The curl",
                     blurb: "A small curl with a tail. It makes three sounds.",
                     tint: .turquoise, letters: [
            L("و", "vāv", "v·u·o", "No dots", "v as in vino, or u / o.", "وال", "val", "whale")
        ]),
        LetterFamily(id: "knot", name: "The knot",
                     blurb: "A round knot. Breathe out when you say it.",
                     tint: .saffron, letters: [
            L("ه", "he", "h", "No dots", "Same breathy h as ح.", "هویج", "havij", "carrot")
        ]),
        LetterFamily(id: "swan", name: "The swan",
                     blurb: "A swan’s neck curving under the line.",
                     tint: .coral, letters: [
            L("ی", "ye", "y·i", "No dots (2 below inside a word)", "Like the i in vino, or the i in ieri.", "یخ", "yakh", "ice")
        ])
    ]

    static let allLetters: [Letter] = families.flatMap { $0.letters }

    static let loners: [Letter] = ["ا", "د", "ذ", "ر", "ز", "ژ", "و"].map { letter($0) }

    static func family(id: String) -> LetterFamily {
        families.first { $0.id == id } ?? families[0]
    }

    static func family(of letter: Letter) -> LetterFamily {
        families.first { $0.letters.contains(letter) } ?? families[0]
    }

    static func letter(_ char: String) -> Letter {
        allLetters.first { $0.char == char } ?? allLetters[0]
    }

    static func next(after letter: Letter) -> Letter? {
        guard let i = allLetters.firstIndex(of: letter), i + 1 < allLetters.count else { return nil }
        return allLetters[i + 1]
    }
}
