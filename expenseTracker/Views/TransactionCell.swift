import UIKit

class TransactionCell: UITableViewCell {
    
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let amountLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.05
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        iconContainer.layer.cornerRadius = 20
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconContainer)
        
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconImageView)
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(vStack)
        
        amountLabel.font = .systemFont(ofSize: 16, weight: .bold)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            vStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            vStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: vStack.trailingAnchor, constant: 8)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Add spacing between cells
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }
    
    func configure(with transaction: Transaction) {
        let catName = transaction.category?.name ?? "Other"
        titleLabel.text = catName
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateLabel.text = transaction.date != nil ? formatter.string(from: transaction.date!) : ""
        
        let amountStr = Theme.currencyFormatter.string(from: NSNumber(value: transaction.amount)) ?? "0.00"
        
        if transaction.type == "income" {
            amountLabel.text = "+\(amountStr)"
            amountLabel.textColor = .systemGreen
            iconContainer.backgroundColor = Theme.incomeColor
            iconImageView.image = UIImage(systemName: catName.iconForCategory())
        } else {
            amountLabel.text = "-\(amountStr)"
            amountLabel.textColor = .systemRed
            iconContainer.backgroundColor = transaction.category?.colorHex != nil ? UIColor(hex: transaction.category!.colorHex!) : Theme.accent
            iconImageView.image = UIImage(systemName: catName.iconForCategory())
        }
    }
}
