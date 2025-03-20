import Foundation
import Contacts
import CoreData

class ContactManager: ObservableObject {
    @Published var contacts: [ContactModel] = []
    
    private let store = CNContactStore()
    private let context = CoreDataManager.shared.context
    
    private let contactKeys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactBirthdayKey as CNKeyDescriptor,
        CNContactIdentifierKey as CNKeyDescriptor
    ]
    
    func fetchContacts() {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        
        do {
            let savedContacts = try context.fetch(request)
            
            if savedContacts.isEmpty {
                importContactsFromiOS()
            } else {
                contacts = savedContacts.map { $0.toModel() }
            }
        } catch {
            print("Error fetching contacts from Core Data: \(error)")
        }
    }
    
    func importContactsFromiOS() {
        DispatchQueue.global(qos: .userInitiated).async {
            let request = CNContactFetchRequest(keysToFetch: self.contactKeys)
            
            do {
                try self.store.enumerateContacts(with: request) { [weak self] contact, _ in
                    guard let self = self else { return }
                    
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    let phone = contact.phoneNumbers.first?.value.stringValue
                    let birthdayDate = contact.birthday.flatMap { Calendar.current.date(from: $0) }
                    
                    let newContact = ContactModel(
                        name: fullName,
                        phoneNumber: phone,
                        birthday: birthdayDate,
                        group: .never
                    )
                    
                    // Save to Core Data
                    let entity = ContactEntity(context: self.context)
                    entity.id = newContact.id
                    entity.name = newContact.name
                    entity.phoneNumber = newContact.phoneNumber
                    entity.group = newContact.group.rawValue
                    entity.birthday = birthdayDate
                }
                
                CoreDataManager.shared.save()
                
                DispatchQueue.main.async {
                    self.fetchContacts()
                }
            } catch {
                print("Failed to import contacts: \(error)")
            }
        }
    }
    
    func fetchContactsInGroup(groupIdentifier: String) -> [CNContact] {
        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        
        do {
            return try store.unifiedContacts(matching: predicate, keysToFetch: contactKeys)
        } catch {
            print("Failed to fetch contacts for group \(groupIdentifier): \(error)")
            return []
        }
    }
    
    func fetchiCloudContactLists() -> [CNGroup] {
        do {
            return try store.groups(matching: nil)
        } catch {
            print("Failed to fetch iCloud Contact Lists: \(error)")
            return []
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
        fetchContacts()
    }
    
    func updateContactGroup(contact: ContactModel, newGroup: ContactGroup) {
        let request: NSFetchRequest<ContactEntity> = ContactEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
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
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                CoreDataManager.shared.save()
                fetchContacts()
            }
        } catch {
            print("Error deleting contact: \(error)")
        }
    }

    func addContactToiCloudList(contact: CNMutableContact, listName: String) {
        let store = CNContactStore()
        
        // Find the group
        let predicate = CNGroup.predicateForGroups(withIdentifiers: [])
        do {
            let groups = try store.groups(matching: predicate)
            if let targetGroup = groups.first(where: { $0.name == listName }) {
                let saveRequest = CNSaveRequest()
                saveRequest.addMember(contact, to: targetGroup)
                
                try store.execute(saveRequest)
                print("✅ Successfully added \(contact.givenName) to \(listName)")
            } else {
                print("❌ Group \(listName) not found.")
            }
        } catch {
            print("❌ Failed to add contact to iCloud list: \(error)")
        }
    }

    func createiCloudContactList(listName: String) {
        let store = CNContactStore()
        
        guard let iCloudContainer = fetchiCloudContactAccount() else {
            print("❌ No iCloud Contact Account Found.")
            return
        }
        
        let newGroup = CNMutableGroup()
        newGroup.name = listName
        
        let saveRequest = CNSaveRequest()
        saveRequest.add(newGroup, toContainerWithIdentifier: iCloudContainer.identifier)
        
        do {
            try store.execute(saveRequest)
            print("✅ Successfully created contact list: \(listName) in iCloud")
        } catch {
            print("❌ Failed to create contact list: \(error)")
        }
    }

    func fetchiCloudContactAccount() -> CNContainer? {
        let store = CNContactStore()
        
        do {
            let containers = try store.containers(matching: nil)
            for container in containers {
                if container.name.lowercased().contains("icloud") { // Check by name
                    print("✅ Found iCloud Contact Account: \(container.name)")
                    return container
                }
            }
        } catch {
            print("❌ Failed to fetch iCloud Contact Account: \(error)")
        }
        
        return nil
    }
}

