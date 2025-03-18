import SwiftUI

@main
struct ContactReminderApp: App {
    let coreDataManager = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ContactsView()
                .environment(\.managedObjectContext, coreDataManager.context) // Provide Core Data context
        }
    }
}
