import UIKit
import CoreData

class DashboardViewController: UIViewController {

    private let segmentedControl = UISegmentedControl(items: ["Today", "7 Days", "Month"])
    private let pieChartView = PieChartView()
    private let tableView = UITableView()
    
    private let balanceLabel = UILabel()
    private let budgetWarningLabel = UILabel()
    
    private var transactions: [Transaction] = []
    private var filteredTransactions: [Transaction] = []
    private var selectedCategoryFilter: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        CoreDataManager.shared.seedDefaultCategoriesIfNeeded()
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
        title = "Dashboard"
        
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        let settingsBtn = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(didTapSettings))
        
        navigationItem.rightBarButtonItems = [addBtn]
        navigationItem.leftBarButtonItem = settingsBtn
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white
        
        // Summary Card
        let glassCard = GlassView()
        glassCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassCard)
        
        balanceLabel.font = .systemFont(ofSize: 32, weight: .bold)
        balanceLabel.textColor = .white
        balanceLabel.textAlignment = .center
        balanceLabel.text = Theme.currencyFormatter.string(from: NSNumber(value: 0))
        
        let balanceTitle = UILabel()
        balanceTitle.text = "Total Balance"
        balanceTitle.textColor = .lightGray
        balanceTitle.font = .systemFont(ofSize: 14, weight: .medium)
        balanceTitle.textAlignment = .center
        
        budgetWarningLabel.textColor = .systemRed
        budgetWarningLabel.font = .systemFont(ofSize: 12, weight: .medium)
        budgetWarningLabel.textAlignment = .center
        budgetWarningLabel.numberOfLines = 0
        budgetWarningLabel.isHidden = true
        
        let vStack = UIStackView(arrangedSubviews: [balanceTitle, balanceLabel, budgetWarningLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        glassCard.contentView.addSubview(vStack)
        
        // Segmented Control
        segmentedControl.selectedSegmentIndex = 2
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Pie Chart
        pieChartView.delegate = self
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pieChartView)
        
        let resetFilterBtn = UIButton(type: .system)
        resetFilterBtn.setTitle("Clear Chart Filter", for: .normal)
        resetFilterBtn.addTarget(self, action: #selector(clearChartFilter), for: .touchUpInside)
        resetFilterBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetFilterBtn)
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            glassCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            glassCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            vStack.centerXAnchor.constraint(equalTo: glassCard.centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: glassCard.centerYAnchor),
            vStack.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -16),
            
            segmentedControl.topAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            pieChartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            pieChartView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pieChartView.widthAnchor.constraint(equalToConstant: 160),
            pieChartView.heightAnchor.constraint(equalToConstant: 160),
            
            resetFilterBtn.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 8),
            resetFilterBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: resetFilterBtn.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func filterChanged() {
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        selectedCategoryFilter = nil
        fetchData()
    }
    
    @objc private func clearChartFilter() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        selectedCategoryFilter = nil
        applyFilter()
    }
    
    private func fetchData() {
        let request: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
        
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date?
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: startDate = calendar.startOfDay(for: now)
        case 1: startDate = calendar.date(byAdding: .day, value: -7, to: now)
        case 2: startDate = calendar.date(byAdding: .month, value: -1, to: now)
        default: break
        }
        
        if let start = startDate {
            request.predicate = NSPredicate(format: "date >= %@", start as NSDate)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            transactions = try CoreDataManager.shared.context.fetch(request)
            updateDashboard()
            applyFilter()
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    private func updateDashboard() {
        var totalBalance = 0.0
        var categoryTotals: [String: Double] = [:]
        var categoryColors: [String: UIColor] = [:]
        
        var budgetWarnings: [String] = []
        
        // First get all categories to check limits
        let catRequest: NSFetchRequest<Category> = NSFetchRequest(entityName: "Category")
        var allCategories: [Category] = []
        do {
            allCategories = try CoreDataManager.shared.context.fetch(catRequest)
        } catch {}
        
        for t in transactions {
            let val = t.amount
            if t.type == "expense" {
                totalBalance -= val
                let catName = t.category?.name ?? "Other"
                categoryTotals[catName, default: 0.0] += val
                if let hex = t.category?.colorHex {
                    categoryColors[catName] = UIColor(hex: hex)
                }
            } else {
                totalBalance += val
            }
        }
        
        // Check budget limits
        for cat in allCategories {
            if let catName = cat.name, cat.budgetLimit > 0 {
                let totalSpent = categoryTotals[catName] ?? 0
                if totalSpent > (cat.budgetLimit * 0.8) {
                    if totalSpent >= cat.budgetLimit {
                        budgetWarnings.append("🚨 \(catName) budget exceeded!")
                    } else {
                        budgetWarnings.append("⚠️ \(catName) budget at 80%+")
                    }
                }
            }
        }
        
        if budgetWarnings.isEmpty {
            budgetWarningLabel.isHidden = true
        } else {
            budgetWarningLabel.isHidden = false
            budgetWarningLabel.text = budgetWarnings.joined(separator: "\n")
        }
        
        balanceLabel.text = Theme.currencyFormatter.string(from: NSNumber(value: totalBalance))
        
        var segments: [PieChartSegment] = []
        let defaultColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemPink]
        var colorIdx = 0
        
        for (name, total) in categoryTotals {
            let color = categoryColors[name] ?? defaultColors[colorIdx % defaultColors.count]
            segments.append(PieChartSegment(color: color, value: total, title: name))
            colorIdx += 1
        }
        
        pieChartView.segments = segments
    }
    
    private func applyFilter() {
        if let filter = selectedCategoryFilter {
            filteredTransactions = transactions.filter { $0.category?.name == filter }
            title = "\(filter) Expenses"
        } else {
            filteredTransactions = transactions
            title = "Dashboard"
        }
        tableView.reloadData()
    }
    
    @objc private func didTapAdd() {
        let vc = AddTransactionViewController()
        vc.modalPresentationStyle = .pageSheet
        present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    @objc private func didTapSettings() {
        let vc = SettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension DashboardViewController: PieChartViewDelegate {
    func didSelectSegment(withTitle title: String) {
        selectedCategoryFilter = title
        applyFilter()
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let t = filteredTransactions[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        cell.textLabel?.text = t.category?.name ?? "Transaction"
        let formattedAmount = Theme.currencyFormatter.string(from: NSNumber(value: t.amount)) ?? "0.00"
        
        if t.type == "income" {
            cell.detailTextLabel?.text = "+\(formattedAmount)"
            cell.detailTextLabel?.textColor = Theme.incomeColor
        } else {
            cell.detailTextLabel?.text = "-\(formattedAmount)"
            cell.detailTextLabel?.textColor = Theme.expenseColor
        }
        return cell
    }
}
