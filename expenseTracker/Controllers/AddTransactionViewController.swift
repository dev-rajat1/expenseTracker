import UIKit
import CoreData
import Vision

class AddTransactionViewController: UIViewController {

    private let typeSegment = UISegmentedControl(items: ["Expense", "Income"])
    private let amountField = UITextField()
    private let categoryPicker = UIPickerView()
    private let datePicker = UIDatePicker()
    
    private var categories: [Category] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCategories()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.applyDarkBackgroundGradient(to: view)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Add Transaction"
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        let saveBtn = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
        cancelBtn.tintColor = .white
        saveBtn.tintColor = Theme.accent
        
        navigationItem.leftBarButtonItem = cancelBtn
        navigationItem.rightBarButtonItem = saveBtn
        
        let glassView = GlassView()
        glassView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassView)
        
        typeSegment.selectedSegmentIndex = 0
        typeSegment.backgroundColor = .systemGray6
        
        amountField.placeholder = "0.00"
        amountField.keyboardType = .decimalPad
        amountField.font = .systemFont(ofSize: 32, weight: .bold)
        amountField.textAlignment = .center
        amountField.textColor = .white
        
        let scanBtn = UIButton(type: .system)
        scanBtn.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        scanBtn.setTitle(" Scan Receipt", for: .normal)
        scanBtn.tintColor = Theme.accent
        scanBtn.addTarget(self, action: #selector(didTapScan), for: .touchUpInside)
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        
        let vStack = UIStackView(arrangedSubviews: [typeSegment, amountField, scanBtn, categoryPicker, datePicker])
        vStack.axis = .vertical
        vStack.spacing = 20
        vStack.translatesAutoresizingMaskIntoConstraints = false
        glassView.contentView.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            glassView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            glassView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            glassView.bottomAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 20),
            
            vStack.topAnchor.constraint(equalTo: glassView.topAnchor, constant: 20),
            vStack.leadingAnchor.constraint(equalTo: glassView.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: glassView.trailingAnchor, constant: -16),
            
            categoryPicker.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func fetchCategories() {
        let req: NSFetchRequest<Category> = NSFetchRequest(entityName: "Category")
        do {
            categories = try CoreDataManager.shared.context.fetch(req)
            categoryPicker.reloadAllComponents()
        } catch {}
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
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: categories[row].name ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
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
