import UIKit
import CoreData
import Vision

class AddTransactionViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
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
        view.backgroundColor = .systemGroupedBackground
        title = "New Transaction"
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        cancelBtn.tintColor = .systemRed
        navigationItem.leftBarButtonItem = cancelBtn
        
        // Setup ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 1. Type Segment
        typeSegment.selectedSegmentIndex = 0
        typeSegment.backgroundColor = .secondarySystemGroupedBackground
        let segFont = UIFont.systemFont(ofSize: 15, weight: .bold)
        typeSegment.setTitleTextAttributes([.font: segFont, .foregroundColor: UIColor.secondaryLabel], for: .normal)
        typeSegment.setTitleTextAttributes([.font: segFont, .foregroundColor: UIColor.white], for: .selected)
        let gradImage = UIImage.gradientImage(bounds: CGRect(x: 0, y: 0, width: 200, height: 50), colors: [UIColor.systemIndigo, UIColor.systemPurple])
        typeSegment.selectedSegmentTintColor = UIColor(patternImage: gradImage)
        
        // 2. Amount Card
        let amountCard = createCardView()
        
        let currencyLabel = UILabel()
        currencyLabel.text = "₹"
        currencyLabel.font = .systemFont(ofSize: 42, weight: .semibold)
        currencyLabel.textColor = .label
        
        currencyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        amountField.placeholder = "0.00"
        amountField.keyboardType = .decimalPad
        amountField.font = .systemFont(ofSize: 42, weight: .semibold)
        amountField.textColor = .label
        amountField.adjustsFontSizeToFitWidth = true
        amountField.textAlignment = .left
        
        let scanBtn = UIButton(type: .system)
        let scanIconConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        scanBtn.setImage(UIImage(systemName: "camera.viewfinder", withConfiguration: scanIconConfig), for: .normal)
        scanBtn.tintColor = .secondaryLabel
        scanBtn.addTarget(self, action: #selector(didTapScan), for: .touchUpInside)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let amountStack = UIStackView(arrangedSubviews: [currencyLabel, amountField, spacer, scanBtn])
        amountStack.axis = .horizontal
        amountStack.spacing = 12
        amountStack.translatesAutoresizingMaskIntoConstraints = false
        amountCard.addSubview(amountStack)
        
        // 3. Note Card
        let noteCard = createCardView()
        let noteIcon = UIImageView(image: UIImage(systemName: "pencil"))
        noteIcon.tintColor = .tertiaryLabel
        noteIcon.contentMode = .scaleAspectFit
        noteIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        noteField.placeholder = "Add a note..."
        noteField.borderStyle = .none
        noteField.font = .systemFont(ofSize: 17, weight: .regular)
        
        let noteStack = UIStackView(arrangedSubviews: [noteIcon, noteField])
        noteStack.axis = .horizontal
        noteStack.spacing = 12
        noteStack.translatesAutoresizingMaskIntoConstraints = false
        noteCard.addSubview(noteStack)
        
        // 4. Category Card
        let categoryCard = createCardView()
        let catLabel = UILabel()
        catLabel.text = "Category"
        catLabel.font = .systemFont(ofSize: 16, weight: .medium)
        catLabel.textColor = .secondaryLabel
        
        let newCatBtn = UIButton(type: .system)
        let plusIcon = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        newCatBtn.setImage(UIImage(systemName: "plus", withConfiguration: plusIcon), for: .normal)
        newCatBtn.setTitle(" New", for: .normal)
        newCatBtn.tintColor = .label
        newCatBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        newCatBtn.addTarget(self, action: #selector(didTapNewCategory), for: .touchUpInside)
        
        let catHeaderStack = UIStackView(arrangedSubviews: [catLabel, UIView(), newCatBtn])
        catHeaderStack.axis = .horizontal
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        let catStack = UIStackView(arrangedSubviews: [catHeaderStack, categoryPicker])
        catStack.axis = .vertical
        catStack.spacing = 8
        catStack.translatesAutoresizingMaskIntoConstraints = false
        categoryCard.addSubview(catStack)
        
        // 5. Date Card
        let dateCard = createCardView()
        let dateLabel = UILabel()
        dateLabel.text = "Date & Time"
        dateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        
        let dateStackSpacer = UIView()
        dateStackSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let dateStack = UIStackView(arrangedSubviews: [dateLabel, datePicker, dateStackSpacer])
        dateStack.axis = .horizontal
        dateStack.spacing = 16
        dateStack.alignment = .center
        dateStack.translatesAutoresizingMaskIntoConstraints = false
        dateCard.addSubview(dateStack)
        
        // 6. Save Button
        let saveContainer = UIButton(type: .system)
        saveContainer.setTitle("Save Transaction", for: .normal)
        saveContainer.setTitleColor(.white, for: .normal)
        saveContainer.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveContainer.layer.cornerRadius = 12 // Curved like segment control
        saveContainer.clipsToBounds = true
        DispatchQueue.main.async {
            let btnGradient = UIImage.gradientImage(bounds: saveContainer.bounds, colors: [UIColor.systemIndigo, UIColor.systemPurple])
            saveContainer.setBackgroundImage(btnGradient, for: .normal)
        }
        saveContainer.layer.shadowColor = UIColor.systemIndigo.cgColor
        saveContainer.layer.shadowOpacity = 0.4
        saveContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        saveContainer.layer.shadowRadius = 12
        saveContainer.layer.masksToBounds = false
        saveContainer.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        
        // Main Stack View
        let mainStack = UIStackView(arrangedSubviews: [typeSegment, amountCard, noteCard, categoryCard, dateCard, saveContainer])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.setCustomSpacing(40, after: dateCard) // Extra space before Save button
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            typeSegment.heightAnchor.constraint(equalToConstant: 44),
            saveContainer.heightAnchor.constraint(equalToConstant: 60),
            categoryPicker.heightAnchor.constraint(equalToConstant: 120),
            scanBtn.widthAnchor.constraint(equalToConstant: 44),
            
            amountStack.topAnchor.constraint(equalTo: amountCard.topAnchor, constant: 16),
            amountStack.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 16),
            amountStack.trailingAnchor.constraint(equalTo: amountCard.trailingAnchor, constant: -16),
            amountStack.bottomAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: -16),
            
            noteStack.topAnchor.constraint(equalTo: noteCard.topAnchor, constant: 16),
            noteStack.leadingAnchor.constraint(equalTo: noteCard.leadingAnchor, constant: 16),
            noteStack.trailingAnchor.constraint(equalTo: noteCard.trailingAnchor, constant: -16),
            noteStack.bottomAnchor.constraint(equalTo: noteCard.bottomAnchor, constant: -16),
            
            catStack.topAnchor.constraint(equalTo: categoryCard.topAnchor, constant: 16),
            catStack.leadingAnchor.constraint(equalTo: categoryCard.leadingAnchor, constant: 16),
            catStack.trailingAnchor.constraint(equalTo: categoryCard.trailingAnchor, constant: -16),
            catStack.bottomAnchor.constraint(equalTo: categoryCard.bottomAnchor, constant: -8),
            
            dateStack.topAnchor.constraint(equalTo: dateCard.topAnchor, constant: 16),
            dateStack.leadingAnchor.constraint(equalTo: dateCard.leadingAnchor, constant: 16),
            dateStack.trailingAnchor.constraint(equalTo: dateCard.trailingAnchor, constant: -16),
            dateStack.bottomAnchor.constraint(equalTo: dateCard.bottomAnchor, constant: -16)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func createCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
            cat.colorHex = "#3498db" // Default color
            cat.budgetLimit = 0
            CoreDataManager.shared.saveContext()
            self?.fetchCategories()
            
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
