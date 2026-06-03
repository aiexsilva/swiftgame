//
//  AudioManager.swift
//  Secrets of Time
//
//  Singleton que gere a música de fundo do jogo. A música inicia quando a app
//  abre e continua sem interrupção entre transições de nível. Só para durante
//  a pausa do jogo. Usa AVAudioPlayer para controlo de volume e loop persistente.
//

import AVFoundation

/// Gere a música de fundo de forma persistente ao longo de toda a sessão de jogo.
class AudioManager {

    static let shared = AudioManager()
    private var musicPlayer: AVAudioPlayer?

    private init() {}

    /// Inicia a música em loop. Se já estiver a tocar não faz nada.
    func startMusic(volume: Float = 0.25) {
        guard musicPlayer == nil,
              let url = Bundle.main.url(forResource: "Main_music", withExtension: "mp3") else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1   // loop infinito
        musicPlayer?.volume = volume
        musicPlayer?.play()
    }

    func pause()  { musicPlayer?.pause() }
    func resume() { musicPlayer?.play()  }
}
