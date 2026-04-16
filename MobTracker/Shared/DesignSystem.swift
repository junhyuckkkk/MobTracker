import SwiftUI

extension Color {
    // Deep Navy Theme
    static let slate900 = Color(hex: "0f172a")
    static let slate800 = Color(hex: "1e293b")
    static let slate400 = Color(hex: "94a3b8")
    
    // Trend Colors
    static let trendUp = Color(hex: "ef4444") // Red for Up (Korean Standard)
    static let trendDown = Color(hex: "3b82f6") // Blue for Down
    
    // AdMob Brand Colors
    static let admobBlue = Color(hex: "4285F4")
    static let admobRed = Color(hex: "EA4335")
    static let admobYellow = Color(hex: "FBBC05")
    static let admobGreen = Color(hex: "34A853")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DesignSystem {
    static let appGroupIdentifier = "group.com.JunHyuk.admob-tracker" // Corrected App Group ID
}

class HapticManager {
    static let instance = HapticManager()
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
