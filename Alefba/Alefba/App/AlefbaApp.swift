import SwiftUI

@main
struct AlefbaApp: App {
    @State private var progress = ProgressStore()
    @State private var voices = VoiceStore()

    init() {
        FontRegistry.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .environment(voices)
                .preferredColorScheme(.light)
        }
    }
}

/// Every screen the app can push onto the navigation stack.
enum Route: Hashable {
    case family(String)   // family id
    case trace(String)    // letter character
    case traceInWord(String, String)  // letter character, favourite word id
    case loners
    case voices
    case word(String)       // favourite word id
    case traceWord(String)  // favourite word id
}

struct RootView: View {
    @State private var path = NavigationPath()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            stack
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
        }
    }

    private var stack: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .family(let id):
                        FamilyView(family: Alphabet.family(id: id), path: $path)
                    case .trace(let char):
                        TraceView(letter: Alphabet.letter(char), path: $path)
                    case .traceInWord(let char, let wordID):
                        TraceView(letter: Alphabet.letter(char), word: Words.word(id: wordID), path: $path)
                    case .loners:
                        LonersView(path: $path)
                    case .voices:
                        VoiceRecorderView(path: $path)
                    case .word(let id):
                        WordView(word: Words.word(id: id), path: $path)
                    case .traceWord(let id):
                        WordTraceView(word: Words.word(id: id), path: $path)
                    }
                }
        }
        .tint(Ink.ink)
    }
}
