import AppKit
import SwiftUI

@main
@MainActor
final class MacVitalsApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let monitor = SystemMonitor()
    private let onboardingStore = OnboardingStore()
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let contentView = DashboardView { [weak self] in
            self?.showSettingsWindow()
        }
            .environmentObject(monitor)
            .frame(width: 380, height: 560)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 560)
        popover.contentViewController = NSHostingController(rootView: contentView)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.target = self
        item.button?.action = #selector(togglePopover)

        monitor.onStatsChanged = { [weak self] stats in
            guard let self else { return }
            self.statusItem?.button?.title = stats.menuBarTitle(for: self.monitor.settings.menuBarDisplayMode)
        }
        monitor.start()

        if !onboardingStore.hasCompleted {
            showOnboardingWindow()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            monitor.setFocused(false)
            popover.performClose(nil)
        } else {
            monitor.setFocused(true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    private func showSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: SettingsView {
            self.showOnboardingWindow()
        }.environmentObject(monitor))
        let window = NSWindow(contentViewController: controller)
        window.title = L.t("action.settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showOnboardingWindow() {
        if let onboardingWindow {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: OnboardingView { [weak self] in
            guard let self else { return }
            self.onboardingStore.markCompleted()
            self.onboardingWindow?.close()
        })
        let window = NSWindow(contentViewController: controller)
        window.title = L.t("onboarding.windowTitle")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
