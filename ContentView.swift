import SwiftUI

struct ContentView: View {
    @StateObject private var miner = MiningEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 62))
                            .foregroundStyle(.orange)
                        Text("MinBTC").font(.largeTitle.bold())
                        Text("Simulateur de calcul SHA-256")
                            .foregroundStyle(.secondary)
                    }.padding(.top, 18)

                    HStack(spacing: 12) {
                        metric("Hashrate", value: String(format: "%.1f H/s", miner.hashRate), icon: "speedometer")
                        metric("Calculs", value: miner.totalHashes.formatted(), icon: "number")
                    }
                    HStack(spacing: 12) {
                        metric("Session", value: miner.sessionHashes.formatted(), icon: "timer")
                        metric("Nonce", value: miner.nonce.formatted(), icon: "cpu")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Intensité").font(.headline)
                        Slider(value: $miner.intensity, in: 0.2...1)
                            .disabled(miner.isMining)
                        Text("\(Int(miner.intensity * 100)) % de charge souhaitée")
                            .font(.caption).foregroundStyle(.secondary)
                        Toggle("Mode éco (pauses plus longues)", isOn: $miner.ecoMode)
                    }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    Button {
                        miner.isMining ? miner.stop() : miner.start()
                    } label: {
                        Label(miner.isMining ? "Arrêter la simulation" : "Démarrer la simulation",
                              systemImage: miner.isMining ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(miner.isMining ? .red : .green)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dernier hash calculé").font(.headline)
                        Text(miner.lastHash).font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                        .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    if !miner.sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Historique").font(.headline)
                            ForEach(miner.sessions) { session in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        Text("\(session.hashes.formatted()) calculs")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(String(format: "%.1f H/s", session.hashRate))
                                        .font(.subheadline.monospacedDigit())
                                }
                                Divider()
                            }
                        }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    Button("Réinitialiser les compteurs", role: .destructive) {
                        miner.resetCounters()
                    }.font(.footnote)

                    Text("Important : cette application est une démonstration locale. Elle ne mine pas de vrais bitcoins, ne se connecte pas au réseau Bitcoin et n'effectue aucun paiement.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }.padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold().monospacedDigit()).minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
