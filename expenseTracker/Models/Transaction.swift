import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var date: Date?
    @NSManaged public var type: String? // "income" or "expense"
    @NSManaged public var note: String?
    @NSManaged public var category: Category?
}
