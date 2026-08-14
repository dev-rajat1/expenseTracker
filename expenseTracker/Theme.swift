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
    
    static func applyDarkBackgroundGradient(to view: UIView) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 25/255, green: 25/255, blue: 35/255, alpha: 1.0).cgColor,
            UIColor(red: 15/255, green: 15/255, blue: 25/255, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        if let oldGradient = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
            oldGradient.removeFromSuperlayer()
        }
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Automatically uses the user's local currency symbol
        return formatter
    }()
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
