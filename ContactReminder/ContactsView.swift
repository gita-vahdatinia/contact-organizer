import SwiftUI
import Contacts

struct ContactsView: View {
    @ObservedObject var contactManager = ContactManager()
    @State private var iCloudLists: [CNGroup] = []
    @State private var showingBirthdayView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(iCloudLists, id: \.identifier) { group in
                    GroupSection(group: group, contacts: contactManager.fetchContactsInGroup(groupIdentifier: group.identifier))
                }
            }
            .navigationTitle("iCloud Contact Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingBirthdayView.toggle()
                    }) {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingBirthdayView) {
                BirthdayMonthView(contactManager: contactManager)
            }
            .onAppear {
                iCloudLists = contactManager.fetchiCloudContactLists()
            }
        }
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
            Text("\(contact.givenName) \(contact.familyName)")
                .font(.headline)

            if let birthdayComponents = contact.birthday,
               let birthdayDate = Calendar.current.date(from: birthdayComponents) {
                Text("🎂 Birthday: \(formattedDate(birthdayDate))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
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