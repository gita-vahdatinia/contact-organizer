import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = NSPersistentContainer(name: "ContactReminder")

        let description = persistentContainer.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                print("Failed to load Core Data: \(error)")
                self.handleMigrationError()
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data: \(error)")
        }
    }

    private func handleMigrationError() {
        // Delete and reset database if migration fails
        let storeURL = persistentContainer.persistentStoreDescriptions.first?.url
        if let storeURL = storeURL {
            do {
                try FileManager.default.removeItem(at: storeURL)
                print("Deleted old Core Data store due to migration failure.")
                persistentContainer.loadPersistentStores { _, error in
                    if let error = error {
                        fatalError("Failed to reload Core Data: \(error)")
                    }
                }
            } catch {
                print("Failed to delete old Core Data store: \(error)")
            }
        }
    }
}
