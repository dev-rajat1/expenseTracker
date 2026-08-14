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
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Add Transaction"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
        
        typeSegment.selectedSegmentIndex = 0
        typeSegment.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(typeSegment)
        
        let scanBtn = UIButton(type: .system)
        scanBtn.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        scanBtn.setTitle(" Scan Receipt", for: .normal)
        scanBtn.addTarget(self, action: #selector(didTapScan), for: .touchUpInside)
        scanBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanBtn)
        
        amountField.placeholder = "Amount (e.g. 50.00)"
        amountField.keyboardType = .decimalPad
        amountField.borderStyle = .roundedRect
        amountField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(amountField)
        
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        categoryPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryPicker)
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            typeSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            typeSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            typeSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scanBtn.topAnchor.constraint(equalTo: typeSegment.bottomAnchor, constant: 16),
            scanBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            amountField.topAnchor.constraint(equalTo: scanBtn.bottomAnchor, constant: 16),
            amountField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            categoryPicker.topAnchor.constraint(equalTo: amountField.bottomAnchor, constant: 20),
            categoryPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categoryPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            categoryPicker.heightAnchor.constraint(equalToConstant: 120),
            
            datePicker.topAnchor.constraint(equalTo: categoryPicker.bottomAnchor, constant: 20),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func fetchCategories() {
        let req: NSFetchRequest<Category> = NSFetchRequest(entityName: "Category")
        do {
            categories = try CoreDataManager.shared.context.fetch(req)
            categoryPicker.reloadAllComponents()
        } catch {
            print("Err fetching cats: \(error)")
        }
    }
    
    @objc private func didTapScan() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "Camera Unavailable", message: "Cannot access camera.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
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
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row].name
    }
}

extension AddTransactionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage, let cgImage = image.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
            
            var maxAmount: Double = 0.0
            
            for observation in observations {
                if let candidate = observation.topCandidates(1).first?.string {
                    // Extract numbers (ignoring currencies and commas)
                    let cleanStr = candidate.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                    if let val = Double(cleanStr), val > maxAmount {
                        maxAmount = val
                    }
                }
            }
            
            DispatchQueue.main.async {
                if maxAmount > 0 {
                    self?.amountField.text = String(format: "%.2f", maxAmount)
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                }
            }
        }
        
        request.recognitionLevel = .accurate
        
        do {
            try handler.perform([request])
        } catch {
            print("Vision error: \(error)")
        }
    }
}
