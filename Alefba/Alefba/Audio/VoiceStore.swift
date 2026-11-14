import AVFoundation
import Observation

/// Plays and records the voice for each letter and example word.
///
/// Where a sound comes from, in order:
/// 1. a recording made in the app (Documents/Voices/<key>.m4a),
/// 2. a file bundled in the project (Alefba/Voices/<key>.m4a, .mp3, .wav…),
/// 3. a Persian text-to-speech voice, if the iPad has one installed.
@Observable
final class VoiceStore: NSObject, AVAudioPlayerDelegate {
    private(set) var playingKey: String?
    private(set) var recordingKey: String?
    /// Bumped whenever recordings change, so views re-check what exists.
    private(set) var version = 0

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()

    private static let bundledExtensions = ["m4a", "mp3", "wav", "caf", "aac"]

    var voicesFolder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Voices", isDirectory: true)
    }

    func recordedURL(_ key: String) -> URL {
        voicesFolder.appendingPathComponent(key + ".m4a")
    }

    func hasRecording(_ key: String) -> Bool {
        _ = version
        return FileManager.default.fileExists(atPath: recordedURL(key).path)
    }

    func url(for key: String) -> URL? {
        if hasRecording(key) { return recordedURL(key) }
        for ext in Self.bundledExtensions {
            if let url = Bundle.main.url(forResource: key, withExtension: ext) { return url }
            if let url = Bundle.main.url(forResource: key, withExtension: ext, subdirectory: "Voices") { return url }
        }
        return nil
    }

    static var persianVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: "fa-IR")
            ?? AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("fa") }
    }

    func canPlay(_ key: String) -> Bool {
        url(for: key) != nil || Self.persianVoice != nil
    }

    var allRecordings: [URL] {
        _ = version
        let files = (try? FileManager.default.contentsOfDirectory(at: voicesFolder, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    // MARK: Playback

    func play(_ key: String, fallback text: String) {
        stopPlayback()
        if let url = url(for: key) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                newPlayer.delegate = self
                newPlayer.play()
                player = newPlayer
                playingKey = key
            } catch {
                playingKey = nil
            }
            return
        }
        guard let voice = Self.persianVoice else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        synthesizer.speak(utterance)
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        playingKey = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.playingKey = nil
        }
    }

    // MARK: Recording

    func requestMicrophone() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording(_ key: String) {
        stopPlayback()
        stopRecording()
        do {
            try FileManager.default.createDirectory(at: voicesFolder, withIntermediateDirectories: true)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let newRecorder = try AVAudioRecorder(url: recordedURL(key), settings: settings)
            newRecorder.record()
            recorder = newRecorder
            recordingKey = key
        } catch {
            recorder = nil
            recordingKey = nil
        }
    }

    func stopRecording() {
        guard recorder != nil else { return }
        recorder?.stop()
        recorder = nil
        recordingKey = nil
        version += 1
    }

    func deleteRecording(_ key: String) {
        try? FileManager.default.removeItem(at: recordedURL(key))
        version += 1
    }
}

extension Letter {
    /// File name for the letter's voice, e.g. "letter-02-be".
    var voiceKey: String {
        let index = (Alphabet.allLetters.firstIndex(of: self) ?? 0) + 1
        let ascii = name.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
        return String(format: "letter-%02d-", index) + ascii
    }

    /// File name for the example word's voice, e.g. "word-boz".
    var wordVoiceKey: String { "word-\(wordLatin)" }
}
