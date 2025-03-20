import SwiftUI
import Contacts

struct ContactsView: View {
    @ObservedObject var contactManager = ContactManager()
    @State private var iCloudLists: [CNGroup] = []
    @State private var showingBirthdayView = false
    @Environment(\.scenePhase) private var scenePhase

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
                refreshData()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    refreshData()
                }
            }
        }
    }
    
    private func refreshData() {
        iCloudLists = contactManager.fetchiCloudContactLists()
        contactManager.fetchContacts()
    }
}

struct GroupSection: View {
    let group: CNGroup
    let contacts: [CNContact]

    var body: some View {
        Section(header: Text(group.name)) {
            if contacts.isEmpty {
                Text("No contacts in this list")
                    .foregroundColor(.gray)
            } else {
                ForEach(contacts, id: \.identifier) { contact in
                    ContactRow(contact: contact)
                }
            }
        }
    }
}

struct ContactRow: View {
    let contact: CNContact
    @Environment(\.openURL) private var openURL
    
    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }
    
    private var birthdayText: String? {
        guard let birthdayComponents = contact.birthday,
              let birthdayDate = Calendar.current.date(from: birthdayComponents) else {
            return nil
        }
        return "🎂 Birthday: \(formattedDate(birthdayDate))"
    }
    
    private var phoneNumber: String? {
        contact.phoneNumbers.first?.value.stringValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(fullName)
                .font(.headline)
            
            if let birthday = birthdayText {
                Text(birthday)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if let phone = phoneNumber {
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