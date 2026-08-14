import UIKit
import CoreData

class SettingsViewController: UITableViewController {
    
    private let menuSections = ["Appearance", "Data Management", "Danger Zone"]
    private let menuItems = [
        ["Dark Mode"],
        ["Export Data (Excel)", "Export Data (PDF)"],
        ["Clear All Data"]
    ]
    
    private let themeSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        themeSwitch.isOn = ThemeManager.shared.currentTheme == .dark
        themeSwitch.addTarget(self, action: #selector(themeSwitchToggled(_:)), for: .valueChanged)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return menuSections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menuSections[section]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.section][indexPath.row]
        cell.accessoryView = nil
        cell.textLabel?.textColor = .label
        
        if indexPath.section == 0 { // Theme
            cell.accessoryView = themeSwitch
            cell.selectionStyle = .none
        } else if indexPath.section == 2 { // Clear Data
            cell.textLabel?.textColor = .systemRed
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                exportDataCSV()
            } else {
                exportDataPDF()
            }
        } else if indexPath.section == 2 {
            clearDataPrompt()
        }
    }
    
    @objc private func themeSwitchToggled(_ sender: UISwitch) {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        ThemeManager.shared.currentTheme = sender.isOn ? .dark : .light
    }
    
    private func exportDataCSV() {
        let request: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
        do {
            let transactions = try CoreDataManager.shared.context.fetch(request)
            var csvText = "Date,Amount,Type,Category,Note\n"
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            for t in transactions {
                let date = t.date != nil ? formatter.string(from: t.date!) : ""
                let row = "\(date),\(t.amount),\(t.type ?? ""),\(t.category?.name ?? ""),\(t.note ?? "")\n"
                csvText.append(row)
            }
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ExpenseTracker_Export.csv")
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            presentShareSheet(for: fileURL)
        } catch { print("Export error: \(error)") }
    }
    
    private func exportDataPDF() {
        let request: NSFetchRequest<Transaction> = NSFetchRequest(entityName: "Transaction")
        do {
            let transactions = try CoreDataManager.shared.context.fetch(request)
            let pdfData = NSMutableData()
            
            UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 612, height: 792), nil)
            UIGraphicsBeginPDFPage()
            
            let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 24)]
            let textAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
            
            "Expense Tracker Report".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttrs)
            
            var yOffset: CGFloat = 100
            for t in transactions {
                if yOffset > 700 {
                    UIGraphicsBeginPDFPage()
                    yOffset = 50
                }
                let cat = t.category?.name ?? "Unknown"
                let amt = Theme.currencyFormatter.string(from: NSNumber(value: t.amount)) ?? "0.00"
                let type = t.type == "income" ? "+" : "-"
                let text = "\(cat): \(type)\(amt)"
                text.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: textAttrs)
                yOffset += 30
            }
            
            UIGraphicsEndPDFContext()
            
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ExpenseTracker_Report.pdf")
            try pdfData.write(to: fileURL, options: .atomic)
            presentShareSheet(for: fileURL)
        } catch {}
    }
    
    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
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
