import SwiftUI
import Contacts

import SwiftUI
import Contacts

struct ContactsView: View {
    @ObservedObject var contactManager = ContactManager()
    @State private var iCloudLists: [CNGroup] = []
    @State private var contactsByGroup: [String: [CNContact]] = [:] // Stores contacts per group

    var body: some View {
        NavigationView {
            List {
                ForEach(iCloudLists, id: \.identifier) { group in
                    GroupSection(group: group, contacts: contactsByGroup[group.identifier] ?? [])
                }
            }
            .navigationTitle("iCloud Contact Lists")
            .onAppear {
                loadGroupsAndContacts()
            }
        }
    }

    private func loadGroupsAndContacts() {
        iCloudLists = contactManager.fetchiCloudContactLists()
        var newContactsByGroup: [String: [CNContact]] = [:]
        for group in iCloudLists {
            newContactsByGroup[group.identifier] = contactManager.fetchContactsInGroup(groupIdentifier: group.identifier)
        }
        contactsByGroup = newContactsByGroup
    }
}

struct GroupSection: View {
    var group: CNGroup
    var contacts: [CNContact]

    var body: some View {
        Section(header: Text(group.name)) {
            if contacts.isEmpty {
                Text("No contacts in this list").foregroundColor(.gray)
            } else {
                ForEach(contacts, id: \.identifier) { contact in
                    ContactRow(contact: contact)
                }
            }
        }
    }
}




struct ContactRow: View {
    var contact: CNContact
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(contact.givenName) \(contact.familyName)").font(.headline)

            if let birthdayComponents = contact.birthday {
                let calendar = Calendar.current
                if let birthdayDate = calendar.date(from: birthdayComponents) {
                    Text("🎂 Birthday: \(formattedDate(birthdayDate))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                Text("No birthday available").font(.subheadline).foregroundColor(.gray)
            }

            if let phone = contact.phoneNumbers.first?.value.stringValue {
                Text(phone)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        if let url = URL(string: "sms:\(phone.replacingOccurrences(of: " ", with: ""))") {
                            openURL(url)
                        }
                    }
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
