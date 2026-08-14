import UIKit

class CategoryGridCell: UICollectionViewCell {
    
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.layer.shadowRadius = 6
        
        iconContainer.layer.cornerRadius = 24
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconContainer)
        
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        
        amountLabel.font = .systemFont(ofSize: 18, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .center
        
        let vStack = UIStackView(arrangedSubviews: [iconContainer, titleLabel, amountLabel])
        vStack.axis = .vertical
        vStack.alignment = .center
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            vStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(category: Category, amount: Double, color: UIColor) {
        titleLabel.text = category.name ?? "Other"
        amountLabel.text = Theme.currencyFormatter.string(from: NSNumber(value: amount)) ?? "$0.00"
        
        DispatchQueue.main.async {
            let gradientImage = UIImage.gradientImage(bounds: self.iconContainer.bounds, colors: [color.withAlphaComponent(0.8), color])
            self.iconContainer.backgroundColor = UIColor(patternImage: gradientImage)
        }
        
        iconImageView.image = UIImage(systemName: "tag.fill") // Can be dynamic later
    }
}
