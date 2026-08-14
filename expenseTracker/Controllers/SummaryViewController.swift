import UIKit
import CoreData

class SummaryViewController: UIViewController {
    
    private let pieChartView = PieChartView()
    private let tableView = UITableView()
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.applyDarkBackgroundGradient(to: view)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Summary"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pieChartView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "catCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            pieChartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            pieChartView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: 220),
            pieChartView.heightAnchor.constraint(equalToConstant: 220),
            
            tableView.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        tableView.reloadData()
    }
}

extension SummaryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryTotals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "catCell")
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = Theme.expenseColor
        cell.accessoryType = .disclosureIndicator
        
        let item = categoryTotals[indexPath.row]
        cell.textLabel?.text = item.category.name
        cell.detailTextLabel?.text = Theme.currencyFormatter.string(from: NSNumber(value: item.total))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCat = categoryTotals[indexPath.row].category
        let detailVC = CategoryDetailViewController()
        detailVC.category = selectedCat
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
