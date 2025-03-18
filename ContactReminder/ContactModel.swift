import Foundation
import Contacts

enum ContactGroup: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case rarely = "Rarely"
    case never = "Never"
}

struct ContactModel: Identifiable {
    var id = UUID()
    var name: String
    var phoneNumber: String?
    var birthday: Date?
    var group: ContactGroup {
        didSet {
            // Save to storage later
        }
    }

}
