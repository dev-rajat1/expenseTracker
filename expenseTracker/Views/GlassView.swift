import UIKit

class GlassView: UIVisualEffectView {
    override init(effect: UIVisualEffect?) {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        super.init(effect: blurEffect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1.0
        self.layer.borderColor = Theme.glassBorder.cgColor
        
        // Add a subtle shadow behind the glass view
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 10
        self.clipsToBounds = false // Allow shadow to bleed outside bounds
        self.contentView.layer.cornerRadius = 16
        self.contentView.layer.masksToBounds = true
    }
}
