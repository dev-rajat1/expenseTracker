import UIKit

enum Theme {
    static let background = UIColor.systemGroupedBackground
    static let cardBackground = UIColor(white: 1.0, alpha: 0.15)
    static let glassBorder = UIColor(white: 1.0, alpha: 0.2)
    static let accent = UIColor.systemBlue
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let incomeColor = UIColor.systemGreen
    static let expenseColor = UIColor.systemRed
    
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Automatically uses the user's local currency symbol
        return formatter
    }()
}

class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: UIUserInterfaceStyle {
        get {
            let saved = UserDefaults.standard.integer(forKey: "appTheme")
            return UIUserInterfaceStyle(rawValue: saved) ?? .unspecified
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appTheme")
            applyTheme()
        }
    }
    
    static let themeChangedNotification = Notification.Name("themeChanged")
    
    func applyTheme() {
        NotificationCenter.default.post(name: ThemeManager.themeChangedNotification, object: nil)
        
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = currentTheme
                }
            }
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIImage {
    static func gradientImage(bounds: CGRect, colors: [UIColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

