import Foundation
import Combine
import CryptoKit

struct MiningSession: Identifiable {
    let id = UUID()
    let date: Date
    let hashRate: Double
    let duration: TimeInterval
    let hashes: UInt64
}

@MainActor
final class MiningEngine: ObservableObject {
    @Published private(set) var isMining = false
    @Published private(set) var hashRate = 0.0
    @Published private(set) var totalHashes: UInt64 = 0
    @Published private(set) var sessionHashes: UInt64 = 0
    @Published private(set) var nonce: UInt64 = 0
    @Published private(set) var lastHash = "—"
    @Published private(set) var sessions: [MiningSession] = []
    @Published var intensity = 0.5
    @Published var ecoMode = true

    private var worker: Task<Void, Never>?
    private var sessionStart = Date()
    private var lastUpdate = Date()
    private var hashesAtUpdate: UInt64 = 0

    // Démonstration locale uniquement : aucun vrai BTC n'est miné ou crédité.
    func start() {
        guard !isMining else { return }
        isMining = true
        sessionHashes = 0
        sessionStart = Date()
        lastUpdate = Date()
        hashesAtUpdate = 0

        worker = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                let batch = 250
                for _ in 0..<batch {
                    if Task.isCancelled { return }
                    let n = UInt64.random(in: 0...UInt64.max)
                    let digest = SHA256.hash(data: Data(String(n).utf8))
                    let hex = digest.map { String(format: "%02x", $0) }.joined()
                    await self?.recordHash(hex)
                }
                let pause = await self?.ecoMode == true ? 0.15 : 0.04
                try? await Task.sleep(for: .seconds(pause))
            }
        }
    }

    private func recordHash(_ hash: String) {
        guard isMining else { return }
        nonce &+= 1
        totalHashes &+= 1
        sessionHashes &+= 1
        lastHash = hash
        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdate)
        if elapsed >= 1 {
            let count = sessionHashes - hashesAtUpdate
            hashRate = Double(count) / elapsed
            hashesAtUpdate = sessionHashes
            lastUpdate = now
        }
    }

    func stop() {
        guard isMining else { return }
        worker?.cancel()
        worker = nil
        isMining = false
        let duration = Date().timeIntervalSince(sessionStart)
        if duration > 0.5 {
            sessions.insert(MiningSession(date: Date(), hashRate: Double(sessionHashes) / duration,
                                          duration: duration, hashes: sessionHashes), at: 0)
            if sessions.count > 30 { sessions.removeLast() }
        }
        hashRate = 0
    }

    func resetCounters() {
        stop()
        totalHashes = 0
        sessionHashes = 0
        nonce = 0
        lastHash = "—"
        sessions.removeAll()
    }

    deinit { worker?.cancel() }
}
