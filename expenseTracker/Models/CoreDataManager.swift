import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        // Build the NSManagedObjectModel programmatically
        let model = NSManagedObjectModel()
        
        let categoryEntity = NSEntityDescription()
        categoryEntity.name = "Category"
        categoryEntity.managedObjectClassName = NSStringFromClass(Category.self)
        
        let idAttrC = NSAttributeDescription()
        idAttrC.name = "id"
        idAttrC.attributeType = .UUIDAttributeType
        idAttrC.isOptional = true
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = true
        
        let colorAttr = NSAttributeDescription()
        colorAttr.name = "colorHex"
        colorAttr.attributeType = .stringAttributeType
        colorAttr.isOptional = true
        
        let iconAttr = NSAttributeDescription()
        iconAttr.name = "iconName"
        iconAttr.attributeType = .stringAttributeType
        iconAttr.isOptional = true
        
        let budgetAttr = NSAttributeDescription()
        budgetAttr.name = "budgetLimit"
        budgetAttr.attributeType = .doubleAttributeType
        budgetAttr.isOptional = false
        budgetAttr.defaultValue = 1000.0 // Default limit
        
        categoryEntity.properties = [idAttrC, nameAttr, colorAttr, iconAttr, budgetAttr]
        
        let transactionEntity = NSEntityDescription()
        transactionEntity.name = "Transaction"
        transactionEntity.managedObjectClassName = NSStringFromClass(Transaction.self)
        
        let idAttrT = NSAttributeDescription()
        idAttrT.name = "id"
        idAttrT.attributeType = .UUIDAttributeType
        idAttrT.isOptional = true
        
        let amountAttr = NSAttributeDescription()
        amountAttr.name = "amount"
        amountAttr.attributeType = .doubleAttributeType
        amountAttr.isOptional = false
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true
        
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = true
        
        let noteAttr = NSAttributeDescription()
        noteAttr.name = "note"
        noteAttr.attributeType = .stringAttributeType
        noteAttr.isOptional = true
        
        transactionEntity.properties = [idAttrT, amountAttr, dateAttr, typeAttr, noteAttr]
        
        // Relationships
        let catToTrans = NSRelationshipDescription()
        catToTrans.name = "transactions"
        catToTrans.destinationEntity = transactionEntity
        catToTrans.minCount = 0
        catToTrans.maxCount = 0 // To-many
        catToTrans.deleteRule = .cascadeDeleteRule
        
        let transToCat = NSRelationshipDescription()
        transToCat.name = "category"
        transToCat.destinationEntity = categoryEntity
        transToCat.minCount = 0
        transToCat.maxCount = 1 // To-one
        transToCat.deleteRule = .nullifyDeleteRule
        
        catToTrans.inverseRelationship = transToCat
        transToCat.inverseRelationship = catToTrans
        
        categoryEntity.properties.append(catToTrans)
        transactionEntity.properties.append(transToCat)
        
        model.entities = [categoryEntity, transactionEntity]
        
        persistentContainer = NSPersistentContainer(name: "ExpenseTrackerModel", managedObjectModel: model)
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    // Seed initial categories
    func seedDefaultCategoriesIfNeeded() {
        let request: NSFetchRequest<Category> = NSFetchRequest(entityName: "Category")
        do {
            let count = try context.count(for: request)
            if count == 0 {
                let defaultNames = ["Food", "Travel", "Shopping", "Health", "Bills", "Groceries", "Entertainment", "Salary"]
                
                for name in defaultNames {
                    let cat = Category(context: context)
                    cat.id = UUID()
                    cat.name = name
                    cat.budgetLimit = 1000.0 // Default budget
                }
                
                saveContext()
            }
        } catch {
            print("Failed to seed categories: \(error)")
        }
    }
    
    func clearAllData() {
        let fetchTrans = NSFetchRequest<NSFetchRequestResult>(entityName: "Transaction")
        let fetchCat = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        
        let batchTrans = NSBatchDeleteRequest(fetchRequest: fetchTrans)
        let batchCat = NSBatchDeleteRequest(fetchRequest: fetchCat)
        
        do {
            try context.execute(batchTrans)
            try context.execute(batchCat)
            saveContext()
            seedDefaultCategoriesIfNeeded()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}
