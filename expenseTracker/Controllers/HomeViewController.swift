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
    

    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Home"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 1. Search Bar (Premium Styling)
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search expenses..."
        searchBar.backgroundImage = UIImage() // Remove default borders
        
        // Text field styling
        let textField = searchBar.searchTextField
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.layer.cornerRadius = 18 // Pill shape
        textField.clipsToBounds = true
        textField.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Icon styling
        if let leftIcon = textField.leftView as? UIImageView {
            leftIcon.tintColor = Theme.accent
        }
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // 2. Filters
        segmentedControl.selectedSegmentIndex = 2
        segmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        
        // Custom Segment Styling (Premium Pill)
        segmentedControl.backgroundColor = .secondarySystemGroupedBackground
        let segFont = UIFont.systemFont(ofSize: 15, weight: .bold)
        segmentedControl.setTitleTextAttributes([.font: segFont, .foregroundColor: UIColor.secondaryLabel], for: .normal)
        segmentedControl.setTitleTextAttributes([.font: segFont, .foregroundColor: UIColor.white], for: .selected)
        
        let gradImage = UIImage.gradientImage(bounds: CGRect(x: 0, y: 0, width: 200, height: 50), colors: [UIColor.systemIndigo, UIColor.systemPurple])
        segmentedControl.selectedSegmentTintColor = UIColor(patternImage: gradImage)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // 3. Balance Card
        balanceCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(balanceCard)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.systemIndigo.cgColor, UIColor.systemPurple.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 24
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        balanceCard.contentView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Ensure gradient resizes
        DispatchQueue.main.async {
            gradientLayer.frame = self.balanceCard.bounds
        }
        
        let balanceTitle = UILabel()
        balanceTitle.text = "Total Balance"
        balanceTitle.textColor = UIColor(white: 1.0, alpha: 0.8)
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
        tableView.separatorStyle = .none
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // 5. Floating Action Button (FAB)
        fab.setImage(UIImage(systemName: "plus"), for: .normal)
        fab.tintColor = .white
        fab.layer.cornerRadius = 28 // Perfectly round circle
        fab.clipsToBounds = true
        
        DispatchQueue.main.async {
            let fabGradient = UIImage.gradientImage(bounds: self.fab.bounds, colors: [UIColor.systemIndigo, UIColor.systemPurple])
            self.fab.setBackgroundImage(fabGradient, for: .normal)
        }
        
        fab.layer.shadowColor = UIColor.systemIndigo.cgColor
        fab.layer.shadowOpacity = 0.5
        fab.layer.shadowOffset = CGSize(width: 0, height: 6)
        fab.layer.shadowRadius = 12
        fab.layer.masksToBounds = false
        fab.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        fab.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fab)
        
        // AutoLayout
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            balanceCard.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TransactionCell
        let t = filteredTransactions[indexPath.row]
        cell.configure(with: t)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let t = filteredTransactions[indexPath.row]
        let noteText = (t.note != nil && !t.note!.isEmpty) ? t.note! : "No note provided."
        
        let alert = UIAlertController(title: "Transaction Note", message: noteText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
