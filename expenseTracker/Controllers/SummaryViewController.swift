import UIKit
import CoreData

class SummaryViewController: UIViewController {
    
    private let pieChartView = PieChartView()
    private var collectionView: UICollectionView!
    
    private var allTransactions: [Transaction] = []
    private var categoryTotals: [(category: Category, total: Double)] = []
    
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
        title = "Summary"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pieChartView)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        let width = (view.bounds.width - 48) / 2
        layout.itemSize = CGSize(width: width, height: width * 0.9)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(CategoryGridCell.self, forCellWithReuseIdentifier: "gridCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            pieChartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            pieChartView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: 220),
            pieChartView.heightAnchor.constraint(equalToConstant: 220),
            
            collectionView.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16),
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
        
        for t in allTransactions where t.type == "expense" {
            if let cat = t.category {
                totalsDict[cat, default: 0.0] += t.amount
            }
        }
        
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
