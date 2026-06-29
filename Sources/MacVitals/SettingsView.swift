import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var monitor: SystemMonitor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Form {
                Section {
                    Picker(L.t("settings.menuBar"), selection: Binding(
                        get: { monitor.settings.menuBarDisplayMode },
                        set: { newValue in
                            monitor.setMenuBarDisplayMode(newValue)
                        }
                    )) {
                        ForEach(MenuBarDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(L.t("settings.general"))
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { monitor.settings.notificationsEnabled },
                        set: { enabled in
                            monitor.setNotificationsEnabled(enabled)
                        }
                    )) {
                        Label(L.t("settings.notifications"), systemImage: "bell")
                    }
                    .toggleStyle(.switch)

                    ThresholdRow(
                        title: L.t("settings.memoryThreshold"),
                        value: monitor.settings.memoryPressureThreshold,
                        range: 0.65...0.95,
                        display: monitor.settings.memoryPressureThreshold.percentText
                    ) { threshold in
                        monitor.setMemoryPressureThreshold(threshold)
                    }
                    .disabled(!monitor.settings.notificationsEnabled)

                    SwapThresholdRow(value: monitor.settings.swapThresholdBytes) { bytes in
                        monitor.setSwapThresholdBytes(bytes)
                    }
                    .disabled(!monitor.settings.notificationsEnabled)
                } header: {
                    Text(L.t("settings.alerts"))
                } footer: {
                    Text(L.t("settings.alertsFooter"))
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { monitor.launchAtLoginEnabled },
                        set: { enabled in
                            monitor.setLaunchAtLoginEnabled(enabled)
                        }
                    )) {
                        Label(L.t("settings.launchAtLogin"), systemImage: "power")
                    }
                    .toggleStyle(.switch)
                } header: {
                    Text(L.t("settings.startup"))
                }

                if let settingsError = monitor.settingsError {
                    Section {
                        Text(settingsError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 420, height: 430)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            Text(L.t("action.settings"))
                .font(.system(size: 18, weight: .semibold))
            Spacer()
        }
        .padding(16)
    }
}

private struct ThresholdRow: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let display: String
    let setValue: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(display)
                    .monospacedDigit()
            }
            .font(.system(size: 12))

            Slider(value: Binding(
                get: { value },
                set: { newValue in
                    setValue(newValue)
                }
            ), in: range, step: 0.01)
        }
        .padding(.vertical, 4)
    }
}

private struct SwapThresholdRow: View {
    let value: UInt64
    let setValue: (UInt64) -> Void

    private var gbValue: Double {
        Double(value) / 1_073_741_824
    }

    var body: some View {
        ThresholdRow(
            title: L.t("settings.swapThreshold"),
            value: gbValue,
            range: 1...16,
            display: ByteText.format(value)
        ) { newValue in
            setValue(UInt64(newValue * 1_073_741_824))
        }
    }
}
