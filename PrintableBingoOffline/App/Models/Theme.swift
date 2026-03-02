import Foundation

enum ThemeMode: String, CaseIterable, Identifiable {
    case auto
    case classic
    case christmas

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto:
            return String(localized: "theme.auto")
        case .classic:
            return String(localized: "theme.classic")
        case .christmas:
            return String(localized: "theme.christmas")
        }
    }
}

struct ThemeResolver {
    static func resolvedTheme(for date: Date, mode: ThemeMode) -> ThemeMode {
        switch mode {
        case .auto:
            return isChristmasSeason(date) ? .christmas : .classic
        default:
            return mode
        }
    }

    static func isChristmasSeason(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return false }

        // Dec 1 – Jan 6
        if month == 12 { return day >= 1 }
        if month == 1 { return day <= 6 }
        return false
    }
}
