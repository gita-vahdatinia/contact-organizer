import SwiftUI
import Contacts

struct ContactsView: View {
    @ObservedObject var contactManager = ContactManager()
    @State private var iCloudLists: [CNGroup] = []
    @State private var showingBirthdayView = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var expandedGroups: Set<String> = []

    var body: some View {
        NavigationView {
            List {
                ForEach(iCloudLists, id: \.identifier) { group in
                    GroupSection(
                        group: group,
                        contacts: contactManager.fetchContactsInGroup(groupIdentifier: group.identifier),
                        isExpanded: expandedGroups.contains(group.identifier),
                        onToggle: { isExpanded in
                            if isExpanded {
                                expandedGroups.insert(group.identifier)
                            } else {
                                expandedGroups.remove(group.identifier)
                            }
                        },
                        contactManager: contactManager
                    )
                }
            }
            .navigationTitle("Baddies Only")
                .navigationBarTitleDisplayMode(.inline)
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
    let isExpanded: Bool
    let onToggle: (Bool) -> Void
    let contactManager: ContactManager
    
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { isExpanded },
                set: { onToggle($0) }
            )
        ) {
            if contacts.isEmpty {
                Text("No contacts in this list")
                    .foregroundColor(.gray)
                    .padding(.leading)
            } else {
                ForEach(contacts, id: \.identifier) { contact in
                    ContactRow(contact: contact, contactManager: contactManager)
                        .padding(.leading)
                }
            }
        } label: {
            HStack {
                Text(group.name)
                    .font(.headline)
                Spacer()
                Text("\(contacts.count) contacts")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ContactRow: View {
    let contact: CNContact
    @ObservedObject var contactManager: ContactManager
    @Environment(\.openURL) private var openURL
    @State private var showingNotes = false
    
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
        HStack {
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
            
            Spacer()
            
            Button(action: {
                showingNotes.toggle()
            }) {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 5)
        .sheet(isPresented: $showingNotes) {
            NotesView(contact: contact, contactManager: contactManager)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        let formatter = DateFormatter()
        // If the year is 1 or 1900 (common placeholder for no year), only show month and day
        if year <= 1900 {
            formatter.dateFormat = "MMMM d"
        } else {
            formatter.dateStyle = .long
        }
        return formatter.string(from: date)
    }
}

struct NotesView: View {
    let contact: CNContact
    @ObservedObject var contactManager: ContactManager
    @State private var newNote: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // New note input
                TextField("Add a new note...", text: $newNote)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if !newNote.isEmpty {
                        contactManager.updateContactNotes(contact: contact, newNote: newNote)
                        newNote = ""
                        dismiss()
                    }
                }) {
                    Text("Add Note")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                // Existing notes
                ScrollView {
                    Text(contact.note)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .navigationTitle("Notes for \(contact.givenName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
