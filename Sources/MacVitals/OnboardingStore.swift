import Foundation

struct OnboardingStore {
    private enum Key {
        static let completed = "onboardingCompleted"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompleted: Bool {
        defaults.bool(forKey: Key.completed)
    }

    func markCompleted() {
        defaults.set(true, forKey: Key.completed)
    }
}
