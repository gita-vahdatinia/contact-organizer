import SwiftUI

struct ContactsView: View {
    @ObservedObject var contactManager = ContactManager()
    @State private var reverseOrder = false

    var body: some View {
        NavigationView {
            List {
                Toggle("Reverse Order", isOn: $reverseOrder)
                
                ForEach(reverseOrder ? ContactGroup.allCases.reversed() : ContactGroup.allCases, id: \.self) { group in
                    let filteredContacts = contactManager.contacts.filter { $0.group == group }

                    if !filteredContacts.isEmpty {
                        Section(header: Text(group.rawValue)) {
                            ForEach(filteredContacts) { contact in
                                ContactRow(contact: contact, contactManager: contactManager)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Contact Groups")
            .onAppear {
                contactManager.fetchContacts()
            }
        }
    }
}

struct ContactRow: View {
    var contact: ContactModel
    var contactManager: ContactManager

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(contact.name).font(.headline)
            
            if let birthday = contact.birthday {
                Text("🎂 Birthday: \(formattedDate(birthday))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            
            if let phone = contact.phoneNumber {
                Text(phone)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Picker("", selection: Binding(
                get: { contact.group },
                set: { newGroup in
                    contactManager.updateContactGroup(contact: contact, newGroup: newGroup)
                }
            )) {
                ForEach(ContactGroup.allCases, id: \.self) { group in
                    Text(group.rawValue).tag(group)
                }
            }
            .pickerStyle(MenuPickerStyle()) // Dropdown picker
        }
        .padding(.vertical, 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
