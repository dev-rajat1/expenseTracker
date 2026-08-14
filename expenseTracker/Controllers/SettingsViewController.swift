import UIKit
import CoreData

class SettingsViewController: UITableViewController {

    private let menuItems = [
        "Export Data (CSV)",
        "Clear All Data"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row]
        
        if indexPath.row == 1 {
            cell.textLabel?.textColor = .systemRed
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            exportData()
        } else if indexPath.row == 1 {
            clearDataPrompt()
        }
    }
    
    private func exportData() {
        let request: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
        do {
            let transactions = try CoreDataManager.shared.context.fetch(request)
            var csvText = "Date,Amount,Type,Category,Note\n"
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            
            for t in transactions {
                let date = t.date != nil ? formatter.string(from: t.date!) : ""
                let cat = t.category?.name ?? ""
                let note = t.note ?? ""
                let type = t.type ?? ""
                let row = "\(date),\(t.amount),\(type),\(cat),\(note)\n"
                csvText.append(row)
            }
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("ExpenseTracker_Export.csv")
            
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            present(activityVC, animated: true)
            
        } catch {
            print("Export error: \(error)")
        }
    }
    
    private func clearDataPrompt() {
        let haptic = UIImpactFeedbackGenerator(style: .heavy)
        haptic.impactOccurred()
        
        let alert = UIAlertController(title: "Clear All Data", message: "Are you sure? This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            CoreDataManager.shared.clearAllData()
            let successHaptic = UINotificationFeedbackGenerator()
            successHaptic.notificationOccurred(.success)
        }))
        present(alert, animated: true)
    }
}
