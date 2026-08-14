import UIKit
import CoreData

class SummaryViewController: UIViewController {
    
    private let chartCard = GlassView()
    private let cardTitleLabel = UILabel()
    private let pieChartView = PieChartView()
    private let centerTotalLabel = UILabel()
    private let centerSubtitleLabel = UILabel()
    private let selectedCategoryLabel = UILabel()
    
    private let sectionHeaderLabel = UILabel()
    private var collectionView: UICollectionView!
    
    private var allTransactions: [Transaction] = []
    private var categoryTotals: [(category: Category, total: Double)] = []
    private var totalExpense: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Analytics"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 1. Chart Card
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chartCard)
        
        cardTitleLabel.text = "Expense Breakdown"
        cardTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        cardTitleLabel.textColor = .label
        cardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.contentView.addSubview(cardTitleLabel)
        
        pieChartView.delegate = self
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        chartCard.contentView.addSubview(pieChartView)
        
        // Center labels for Donut Chart
        centerTotalLabel.font = .systemFont(ofSize: 22, weight: .bold)
        centerTotalLabel.textColor = .label
        centerTotalLabel.textAlignment = .center
        centerTotalLabel.adjustsFontSizeToFitWidth = true
        centerTotalLabel.translatesAutoresizingMaskIntoConstraints = false
        pieChartView.addSubview(centerTotalLabel)
        
        centerSubtitleLabel.text = "Total Spent"
        centerSubtitleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        centerSubtitleLabel.textColor = .secondaryLabel
        centerSubtitleLabel.textAlignment = .center
        centerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pieChartView.addSubview(centerSubtitleLabel)
        
        selectedCategoryLabel.text = "Tap a chart slice for details"
        selectedCategoryLabel.font = .systemFont(ofSize: 14, weight: .medium)
        selectedCategoryLabel.textColor = Theme.accent
        selectedCategoryLabel.textAlignment = .center
        selectedCategoryLabel.translatesAutoresizingMaskIntoConstraints = false
        chartCard.contentView.addSubview(selectedCategoryLabel)
        
        // 2. Section Header
        sectionHeaderLabel.text = "Top Categories"
        sectionHeaderLabel.font = .systemFont(ofSize: 20, weight: .bold)
        sectionHeaderLabel.textColor = .label
        sectionHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionHeaderLabel)
        
        // 3. Collection View
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        let width = (view.bounds.width - 48) / 2
        layout.itemSize = CGSize(width: width, height: width * 0.85)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(CategoryGridCell.self, forCellWithReuseIdentifier: "gridCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            chartCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            chartCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chartCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartCard.heightAnchor.constraint(equalToConstant: 310),
            
            cardTitleLabel.topAnchor.constraint(equalTo: chartCard.contentView.topAnchor, constant: 16),
            cardTitleLabel.leadingAnchor.constraint(equalTo: chartCard.contentView.leadingAnchor, constant: 16),
            
            pieChartView.topAnchor.constraint(equalTo: cardTitleLabel.bottomAnchor, constant: 16),
            pieChartView.centerXAnchor.constraint(equalTo: chartCard.contentView.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: 200),
            pieChartView.heightAnchor.constraint(equalToConstant: 200),
            
            centerTotalLabel.centerXAnchor.constraint(equalTo: pieChartView.centerXAnchor),
            centerTotalLabel.centerYAnchor.constraint(equalTo: pieChartView.centerYAnchor, constant: -6),
            centerTotalLabel.widthAnchor.constraint(equalToConstant: 100),
            
            centerSubtitleLabel.centerXAnchor.constraint(equalTo: pieChartView.centerXAnchor),
            centerSubtitleLabel.topAnchor.constraint(equalTo: centerTotalLabel.bottomAnchor, constant: 2),
            
            selectedCategoryLabel.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16),
            selectedCategoryLabel.centerXAnchor.constraint(equalTo: chartCard.contentView.centerXAnchor),
            selectedCategoryLabel.leadingAnchor.constraint(equalTo: chartCard.contentView.leadingAnchor, constant: 16),
            selectedCategoryLabel.trailingAnchor.constraint(equalTo: chartCard.contentView.trailingAnchor, constant: -16),
            
            sectionHeaderLabel.topAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: 24),
            sectionHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            collectionView.topAnchor.constraint(equalTo: sectionHeaderLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchData() {
        let request: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
        do {
            allTransactions = try CoreDataManager.shared.context.fetch(request)
            calculateSummary()
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    private func calculateSummary() {
        var totalsDict: [Category: Double] = [:]
        totalExpense = 0.0
        
        for t in allTransactions where t.type == "expense" {
            totalExpense += t.amount
            if let cat = t.category {
                totalsDict[cat, default: 0.0] += t.amount
            }
        }
        
        centerTotalLabel.text = Theme.currencyFormatter.string(from: NSNumber(value: totalExpense))
        selectedCategoryLabel.text = "Tap a chart slice for details"
        
        categoryTotals = totalsDict.map { (category: $0.key, total: $0.value) }.sorted(by: { $0.total > $1.total })
        
        var segments: [PieChartSegment] = []
        let defaultColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemPink]
        
        for (idx, item) in categoryTotals.enumerated() {
            let color = item.category.colorHex != nil ? UIColor(hex: item.category.colorHex!) : defaultColors[idx % defaultColors.count]
            segments.append(PieChartSegment(color: color, value: item.total, title: item.category.name ?? ""))
        }
        
        pieChartView.segments = segments
        collectionView.reloadData()
    }
}

extension SummaryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryTotals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as! CategoryGridCell
        let item = categoryTotals[indexPath.row]
        let defaultColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemPink]
        let color = item.category.colorHex != nil ? UIColor(hex: item.category.colorHex!) : defaultColors[indexPath.row % defaultColors.count]
        
        cell.configure(category: item.category, amount: item.total, color: color)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let selectedCat = categoryTotals[indexPath.row].category
        let detailVC = CategoryDetailViewController()
        detailVC.category = selectedCat
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension SummaryViewController: PieChartViewDelegate {
    func didSelectSegment(withTitle title: String) {
        guard let item = categoryTotals.first(where: { $0.category.name == title }) else { return }
        let amountStr = Theme.currencyFormatter.string(from: NSNumber(value: item.total)) ?? "$0.00"
        let percentage = (item.total / totalExpense) * 100
        
        UIView.transition(with: selectedCategoryLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.selectedCategoryLabel.text = "\(title): \(amountStr) (\(String(format: "%.1f", percentage))%)"
        }, completion: nil)
    }
}
