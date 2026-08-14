import UIKit
import CoreData

class CategoryDetailViewController: UIViewController {

    var category: Category?
    private let tableView = UITableView()
    private var transactions: [Transaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchTransactions()
    }
    

    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = category?.name ?? "Details"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchTransactions() {
        guard let cat = category else { return }
        
        let request: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
        request.predicate = NSPredicate(format: "category == %@", cat)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            transactions = try CoreDataManager.shared.context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Error: \(error)")
        }
    }
}

extension CategoryDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        let t = transactions[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.textLabel?.text = t.date != nil ? formatter.string(from: t.date!) : "No Date"
        
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
        let t = transactions[indexPath.row]
        let noteText = (t.note != nil && !t.note!.isEmpty) ? t.note! : "No note provided."
        
        let alert = UIAlertController(title: "Transaction Note", message: noteText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
