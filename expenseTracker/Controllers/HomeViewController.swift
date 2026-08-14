import UIKit
import CoreData

class HomeViewController: UIViewController {

    private let searchBar = UISearchBar()
    private let segmentedControl = UISegmentedControl(items: ["Today", "7 Days", "Month"])
    private let balanceCard = GlassView()
    private let balanceLabel = UILabel()
    private let tableView = UITableView()
    private let fab = UIButton(type: .system)
    
    private var allTransactions: [Transaction] = []
    private var filteredTransactions: [Transaction] = []
    
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
        title = "Home"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 1. Search Bar
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search expenses..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // 2. Filters
        segmentedControl.selectedSegmentIndex = 2
        segmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // 3. Balance Card
        balanceCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(balanceCard)
        
        let balanceTitle = UILabel()
        balanceTitle.text = "Total Balance"
        balanceTitle.textColor = .lightGray
        balanceTitle.font = .systemFont(ofSize: 14, weight: .medium)
        balanceTitle.textAlignment = .center
        
        balanceLabel.font = .systemFont(ofSize: 32, weight: .bold)
        balanceLabel.textColor = .white
        balanceLabel.textAlignment = .center
        balanceLabel.text = "$0.00"
        
        let vStack = UIStackView(arrangedSubviews: [balanceTitle, balanceLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.translatesAutoresizingMaskIntoConstraints = false
        balanceCard.contentView.addSubview(vStack)
        
        // 4. Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // 5. Floating Action Button (FAB)
        fab.setImage(UIImage(systemName: "plus"), for: .normal)
        fab.backgroundColor = Theme.accent
        fab.tintColor = .white
        fab.layer.cornerRadius = 28
        fab.layer.shadowColor = UIColor.black.cgColor
        fab.layer.shadowOpacity = 0.3
        fab.layer.shadowOffset = CGSize(width: 0, height: 5)
        fab.layer.shadowRadius = 10
        fab.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        fab.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fab)
        
        // AutoLayout
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            balanceCard.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            balanceCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            balanceCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            balanceCard.heightAnchor.constraint(equalToConstant: 100),
            
            vStack.centerXAnchor.constraint(equalTo: balanceCard.centerXAnchor),
            vStack.centerYAnchor.constraint(equalTo: balanceCard.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: balanceCard.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fab.widthAnchor.constraint(equalToConstant: 56),
            fab.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func filterChanged() {
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        fetchData()
    }
    
    @objc private func didTapAdd() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        let vc = AddTransactionViewController()
        vc.modalPresentationStyle = .pageSheet
        present(UINavigationController(rootViewController: vc), animated: true)
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
            allTransactions = try CoreDataManager.shared.context.fetch(request)
            applySearchFilter(query: searchBar.text)
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    private func applySearchFilter(query: String?) {
        if let q = query, !q.isEmpty {
            filteredTransactions = allTransactions.filter { t in
                let noteMatch = t.note?.lowercased().contains(q.lowercased()) ?? false
                let catMatch = t.category?.name?.lowercased().contains(q.lowercased()) ?? false
                return noteMatch || catMatch
            }
        } else {
            filteredTransactions = allTransactions
        }
        
        var total = 0.0
        for t in filteredTransactions {
            if t.type == "expense" { total -= t.amount } else { total += t.amount }
        }
        balanceLabel.text = Theme.currencyFormatter.string(from: NSNumber(value: total))
        
        tableView.reloadData()
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySearchFilter(query: searchText)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTransactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let t = filteredTransactions[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .lightGray
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateStr = t.date != nil ? formatter.string(from: t.date!) : ""
        let catName = t.category?.name ?? "Other"
        
        cell.textLabel?.text = "\(catName) - \(dateStr)"
        
        let amountStr = Theme.currencyFormatter.string(from: NSNumber(value: t.amount)) ?? "0.00"
        if t.type == "income" {
            cell.detailTextLabel?.text = "+\(amountStr)"
            cell.detailTextLabel?.textColor = Theme.incomeColor
        } else {
            cell.detailTextLabel?.text = "-\(amountStr)"
            cell.detailTextLabel?.textColor = Theme.expenseColor
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
