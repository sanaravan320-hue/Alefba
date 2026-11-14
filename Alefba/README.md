# Alefba

iPad app (SwiftUI + PencilKit, iPadOS 17+, landscape) for learning the Farsi alphabet by tracing.

## Run it
1. Open `Alefba.xcodeproj` (Xcode 16 or newer).
2. Select the **Alefba** target → Signing & Capabilities → choose your Team.
3. Pick an iPad simulator or his iPad and press Run.
   In the Simulator, leave **Pencil only** off so the mouse can draw.

## What's where
- `Alefba/Model/Alphabet.swift` – all 32 letters: names, sounds, Italian hints, example words, the 17 families.
- `Alefba/Model/ProgressStore.swift` – stars, streak and today's goal (saved on the device).
- `Alefba/Tracing/LetterGuide.swift` – the shapes he traces. The bowl family (ب پ ت ث) has a hand-drawn guide with stroke order, checkpoints and a demo; every other letter uses its outline from Noto Naskh Arabic.
- `Alefba/Tracing/TraceScorer.swift` – compares his ink with the shape: "on the path" (ink inside the shape) and "covered" (how much of the shape he filled). Score = 45% + 55% of those; 3★ ≥ 80%, 2★ ≥ 60%, 1★ ≥ 35%.
- `Alefba/Views/` – Home, Family, Trace, Score and the 7 loners lesson.
- `Alefba/Fonts/` – Fraunces, Figtree, Noto Naskh Arabic (open font licence) and IRANSans (yours, personal use).

## Adding your drawings
Add an image to `Assets.xcassets` named `illustration-` + the word's Latin spelling, e.g. `illustration-boz` (goat), `illustration-panir` (cheese), `illustration-tup` (ball). It replaces the dashed placeholder automatically.

## Voices
Tap the mic button on the home screen to open the recording studio. Record each letter (name then sound, e.g. “be… b”) and each example word. Recordings are saved on that iPad and play from every speaker button.

To ship voices inside the app (so they are on his iPad without recording there): tap **Share recordings**, AirDrop them to your Mac and drop the .m4a files into an `Alefba/Voices` folder in this project. File names are `letter-02-be.m4a`, `word-boz.m4a` and so on; .mp3 and .wav work too.

If no recording exists, the app uses a Persian text-to-speech voice when the iPad has one installed.

## Next ideas
- Hand-drawn guides (stroke order + demo) for the other families: add them next to `BowlGuide`.
- Tracing whole words (e.g. دوست) in the loners lesson.
- App icon: drop a 1024×1024 PNG into `AppIcon`.
