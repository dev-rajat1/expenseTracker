import UIKit
import CoreData
import Vision

class AddTransactionViewController: UIViewController {

    private let typeSegment = UISegmentedControl(items: ["Expense", "Income"])
    private let amountField = UITextField()
    private let noteField = UITextField()
    private let categoryPicker = UIPickerView()
    private let datePicker = UIDatePicker()
    
    private var categories: [Category] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCategories()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Add Transaction"
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        let saveBtn = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
        cancelBtn.tintColor = .systemRed
        saveBtn.tintColor = Theme.accent
        
        navigationItem.leftBarButtonItem = cancelBtn
        navigationItem.rightBarButtonItem = saveBtn
        
        let glassView = GlassView()
        glassView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassView)
        
        typeSegment.selectedSegmentIndex = 0
        typeSegment.backgroundColor = .systemGray6
        DispatchQueue.main.async {
            let gradientImage = UIImage.gradientImage(bounds: self.typeSegment.bounds, colors: [UIColor.systemIndigo, UIColor.systemPurple])
            self.typeSegment.selectedSegmentTintColor = UIColor(patternImage: gradientImage)
            self.typeSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            self.typeSegment.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        }
        
        amountField.placeholder = "0.00"
        amountField.keyboardType = .decimalPad
        amountField.font = .systemFont(ofSize: 32, weight: .bold)
        amountField.textAlignment = .center
        
        noteField.placeholder = "Add a note..."
        noteField.borderStyle = .roundedRect
        noteField.backgroundColor = .secondarySystemBackground
        
        let scanBtn = UIButton(type: .system)
        scanBtn.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        scanBtn.setTitle(" Scan Receipt", for: .normal)
        scanBtn.tintColor = Theme.accent
        scanBtn.addTarget(self, action: #selector(didTapScan), for: .touchUpInside)
        
        let catLabel = UILabel()
        catLabel.text = "Category"
        catLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        catLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let newCatBtn = UIButton(type: .system)
        newCatBtn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        newCatBtn.setTitle(" New", for: .normal)
        newCatBtn.addTarget(self, action: #selector(didTapNewCategory), for: .touchUpInside)
        
        let catHeaderStack = UIStackView(arrangedSubviews: [catLabel, UIView(), newCatBtn])
        catHeaderStack.axis = .horizontal
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        
        let saveContainer = UIButton(type: .system)
        saveContainer.setTitle("Save Transaction", for: .normal)
        saveContainer.setTitleColor(.white, for: .normal)
        saveContainer.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveContainer.layer.cornerRadius = 14
        saveContainer.clipsToBounds = true
        DispatchQueue.main.async {
            let btnGradient = UIImage.gradientImage(bounds: saveContainer.bounds, colors: [UIColor.systemIndigo, UIColor.systemPurple])
            saveContainer.setBackgroundImage(btnGradient, for: .normal)
        }
        saveContainer.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        
        let vStack = UIStackView(arrangedSubviews: [typeSegment, amountField, noteField, scanBtn, catHeaderStack, categoryPicker, datePicker, saveContainer])
        vStack.axis = .vertical
        vStack.spacing = 16
        vStack.translatesAutoresizingMaskIntoConstraints = false
        glassView.contentView.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            saveContainer.heightAnchor.constraint(equalToConstant: 50),
            
            glassView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            glassView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            glassView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            glassView.bottomAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 20),
            
            vStack.topAnchor.constraint(equalTo: glassView.topAnchor, constant: 20),
            vStack.leadingAnchor.constraint(equalTo: glassView.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: glassView.trailingAnchor, constant: -16),
            
            categoryPicker.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Tap to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func fetchCategories() {
        let req: NSFetchRequest<Category> = NSFetchRequest(entityName: "Category")
        do {
            categories = try CoreDataManager.shared.context.fetch(req)
            categoryPicker.reloadAllComponents()
        } catch {}
    }
    
    @objc private func didTapNewCategory() {
        let alert = UIAlertController(title: "New Category", message: "Enter a name for the new category.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Category Name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let context = CoreDataManager.shared.context
            let cat = Category(context: context)
            cat.name = text
            cat.colorHex = "#3498db" // Default color for custom
            cat.budgetLimit = 0
            CoreDataManager.shared.saveContext()
            self?.fetchCategories()
            
            // Select the newly added category
            if let index = self?.categories.firstIndex(of: cat) {
                self?.categoryPicker.selectRow(index, inComponent: 0, animated: true)
            }
        })
        present(alert, animated: true)
    }
    
    @objc private func didTapScan() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }
    
    @objc private func didTapSave() {
        guard let amountText = amountField.text, let amount = Double(amountText) else { return }
        
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        
        let context = CoreDataManager.shared.context
        let newTrans = Transaction(context: context)
        newTrans.id = UUID()
        newTrans.amount = amount
        newTrans.note = noteField.text
        newTrans.date = datePicker.date
        newTrans.type = typeSegment.selectedSegmentIndex == 0 ? "expense" : "income"
        if !categories.isEmpty {
            newTrans.category = categories[categoryPicker.selectedRow(inComponent: 0)]
        }
        CoreDataManager.shared.saveContext()
        dismiss(animated: true)
    }
}

extension AddTransactionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return categories.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row].name
    }
}

extension AddTransactionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage, let cgImage = image.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            var maxAmount: Double = 0.0
            for obs in observations {
                if let str = obs.topCandidates(1).first?.string {
                    let clean = str.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                    if let val = Double(clean), val > maxAmount { maxAmount = val }
                }
            }
            DispatchQueue.main.async {
                if maxAmount > 0 {
                    self?.amountField.text = String(format: "%.2f", maxAmount)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
        try? handler.perform([request])
    }
}
