// DeskBuddy/Voice/VoiceInput.swift
import Speech
import AVFoundation
import Combine

class VoiceInput: ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    func startListening(locale: Locale = .current) throws {
        recognizer = SFSpeechRecognizer(locale: locale)
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        try audioEngine.start()
        isListening = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                DispatchQueue.main.async { self?.transcript = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true { self?.stopListening() }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        isListening = false
    }
}
