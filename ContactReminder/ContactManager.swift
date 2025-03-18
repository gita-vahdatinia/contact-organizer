import Foundation
import Contacts
import CoreData

class ContactManager: ObservableObject {
    @Published var contacts: [ContactModel] = []

    let store = CNContactStore()
    let context = CoreDataManager.shared.context

    func fetchContacts() {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()

        do {
            let savedContacts = try context.fetch(request)

            if savedContacts.isEmpty {
                print("No contacts in Core Data, importing from iOS Contacts.")
                importContactsFromiOS()
            } else {
                contacts = savedContacts.map { $0.toModel() }
            }
        } catch {
            print("Error fetching contacts from Core Data: \(error)")
        }
    }
    func importContactsFromiOS() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        var newContacts: [ContactModel] = []

        do {
            try store.enumerateContacts(with: request) { (contact, _) in
                let fullName = "\(contact.givenName) \(contact.familyName)"
                let phone = contact.phoneNumbers.first?.value.stringValue

                let newContact = ContactModel(name: fullName, phoneNumber: phone, group: .monthly) // Default to Monthly
                newContacts.append(newContact)

                // Save to Core Data
                let entity = ContactEntity(context: context)
                entity.id = newContact.id
                entity.name = newContact.name
                entity.phoneNumber = newContact.phoneNumber
                entity.group = newContact.group.rawValue
            }

            CoreDataManager.shared.save()
            DispatchQueue.main.async {
                self.fetchContacts() // Refresh the UI
            }
        } catch {
            print("Failed to import contacts: \(error)")
        }
    }


    func saveContact(_ contact: ContactModel) {
        let entity = ContactEntity(context: context)
        entity.id = contact.id
        entity.name = contact.name
        entity.phoneNumber = contact.phoneNumber
        entity.birthday = contact.birthday
        entity.group = contact.group.rawValue

        CoreDataManager.shared.save()
        fetchContacts() // Refresh list
    }

    func updateContactGroup(contact: ContactModel, newGroup: ContactGroup) {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.group = newGroup.rawValue
                CoreDataManager.shared.save()
                fetchContacts()
            }
        } catch {
            print("Error updating contact group: \(error)")
        }
    }

    func deleteContact(_ contact: ContactModel) {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                context.delete(entity)
                CoreDataManager.shared.save()
                fetchContacts()
            }
        } catch {
            print("Error deleting contact: \(error)")
        }
    }
}
