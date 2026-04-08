import WidgetKit
import SwiftUI

// MARK: - Shared constants

private let appGroupId = "group.com.jlerisla.safebeacon.safe_beacon"
private let isActiveKey = "is_alert_active"

// MARK: - Timeline entry

struct PanicWidgetEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
}

// MARK: - Timeline provider

struct PanicWidgetProvider: TimelineProvider {

    private func readIsActive() -> Bool {
        UserDefaults(suiteName: appGroupId)?.bool(forKey: isActiveKey) ?? false
    }

    func placeholder(in context: Context) -> PanicWidgetEntry {
        PanicWidgetEntry(date: .now, isActive: false)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (PanicWidgetEntry) -> Void
    ) {
        completion(PanicWidgetEntry(date: .now, isActive: readIsActive()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<PanicWidgetEntry>) -> Void
    ) {
        let entry = PanicWidgetEntry(date: .now, isActive: readIsActive())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - Widget views

struct PanicWidgetView: View {
    var entry: PanicWidgetEntry

    var body: some View {
        if entry.isActive {
            ActiveView()
        } else {
            NormalView()
        }
    }
}

/// Standby state – ready to activate.
private struct NormalView: View {
    var body: some View {
        // Tap opens the app; Flutter shows the panic button screen.
        Link(destination: URL(string: "safebeacon://open")!) {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.12)

                VStack(spacing: 4) {
                    Text("SOS")
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(Color(red: 1.0, green: 0.09, blue: 0.27))
                        .tracking(4)

                    Text("BOTÓN DEL PÁNICO")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                        .tracking(1.5)

                    Spacer().frame(height: 8)

                    Text("ACTIVAR ALERTA")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 1.0, green: 0.09, blue: 0.27))
                        )
                }
                .padding(12)
            }
        }
    }
}

/// Active state – alert is live, prompt user to open the app.
private struct ActiveView: View {
    var body: some View {
        Link(destination: URL(string: "safebeacon://open")!) {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.12)

                VStack(spacing: 4) {
                    Text("ALERTA ACTIVA")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.43, blue: 0.0))
                        .multilineTextAlignment(.center)

                    Text("SOS enviado a tus contactos")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Spacer().frame(height: 8)

                    Text("ABRIR SAFEBEACON")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.9, green: 0.32, blue: 0.0))
                        )
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Widget configuration

struct SafeBeaconWidget: Widget {
    let kind = "SafeBeaconWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PanicWidgetProvider()) { entry in
            PanicWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SafeBeacon SOS")
        .description("Activa tu botón del pánico desde la pantalla de inicio.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Xcode preview

#Preview(as: .systemSmall) {
    SafeBeaconWidget()
} timeline: {
    PanicWidgetEntry(date: .now, isActive: false)
    PanicWidgetEntry(date: .now, isActive: true)
}
