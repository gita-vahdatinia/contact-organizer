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
                .onMove(perform: moveGroups)
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
    
    private func moveGroups(from source: IndexSet, to destination: Int) {
        iCloudLists.move(fromOffsets: source, toOffset: destination)
        saveGroupOrder()
    }
    
    private func saveGroupOrder() {
        let groupOrder = iCloudLists.map { $0.identifier }
        UserDefaults.standard.set(groupOrder, forKey: "GroupOrder")
    }
    
    private func refreshData() {
        let newLists = contactManager.fetchiCloudContactLists()
        
        let savedOrder = UserDefaults.standard.array(forKey: "GroupOrder") as? [String] ?? []
        
        iCloudLists = newLists.sorted { first, second in
            let firstIndex = savedOrder.firstIndex(of: first.identifier) ?? Int.max
            let secondIndex = savedOrder.firstIndex(of: second.identifier) ?? Int.max
            return firstIndex < secondIndex
        }
        
        let remainingLists = newLists.filter { group in
            !iCloudLists.contains(where: { $0.identifier == group.identifier })
        }
        iCloudLists.append(contentsOf: remainingLists)
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
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
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
        let formattedDate = formattedDate(birthdayDate)
        let zodiacSign = getZodiacSign(date: birthdayDate)
        return "\(zodiacSign) \(formattedDate)"
    }
    
    private var phoneNumber: String? {
        contact.phoneNumbers.first?.value.stringValue
    }
    
    private func getZodiacSign(date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19):
            return "♈️" // Aries
        case (4, 20...30), (5, 1...20):
            return "♉️" // Taurus
        case (5, 21...31), (6, 1...20):
            return "♊️" // Gemini
        case (6, 21...30), (7, 1...22):
            return "♋️" // Cancer
        case (7, 23...31), (8, 1...22):
            return "♌️" // Leo
        case (8, 23...31), (9, 1...22):
            return "♍️" // Virgo
        case (9, 23...30), (10, 1...22):
            return "♎️" // Libra
        case (10, 23...31), (11, 1...21):
            return "♏️" // Scorpio
        case (11, 22...30), (12, 1...21):
            return "♐️" // Sagittarius
        case (12, 22...31), (1, 1...19):
            return "♑️" // Capricorn
        case (1, 20...31), (2, 1...18):
            return "♒️" // Aquarius
        case (2, 19...29), (3, 1...20):
            return "♓️" // Pisces
        default:
            return ""
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(fullName)
                    .font(.headline)
                
                if let birthday = birthdayText {
                    Text("\(birthday)")
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
            ContactNotesView(contact: contact, contactManager: contactManager)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        let formatter = DateFormatter()
        if year <= 1900 {
            formatter.dateFormat = "MMMM d"
        } else {
            formatter.dateStyle = .long
        }
        return formatter.string(from: date)
    }
}

struct ContactNotesView: View {
    let contact: CNContact
    let contactManager: ContactManager
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedNoteText: String = ""
    @State private var showingAddNote = false
    @State private var currentContact: CNContact
    
    init(contact: CNContact, contactManager: ContactManager) {
        self.contact = contact
        self.contactManager = contactManager
        _currentContact = State(initialValue: contact)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isEditing {
                    TextEditor(text: $editedNoteText)
                        .padding()
                        .font(.body)
                } else {
                    if currentContact.note.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "note.text")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No notes yet")
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            Text(currentContact.note)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle("\(currentContact.givenName)'s Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveNotes()
                            isEditing = false
                        }
                    } else {
                        Menu {
                            Button(action: {
                                editedNoteText = currentContact.note
                                isEditing = true
                            }) {
                                Label("Edit Notes", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                showingAddNote = true
                            }) {
                                Label("Add Entry", systemImage: "plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                            editedNoteText = currentContact.note
                        }
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(contact: currentContact, contactManager: contactManager) {
                    refreshContact()
                }
            }
        }
    }
    
    private func refreshContact() {
        if let updated = contactManager.fetchContact(withId: currentContact.identifier) {
            currentContact = updated
        }
    }
    
    private func saveNotes() {
        guard let mutableContact = currentContact.mutableCopy() as? CNMutableContact else { return }
        mutableContact.note = editedNoteText
        
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        
        do {
            try contactManager.store.execute(saveRequest)
            print("Successfully saved notes")
            refreshContact()
        } catch {
            print("Failed to save notes: \(error)")
        }
    }
}

struct AddNoteView: View {
    let contact: CNContact
    let contactManager: ContactManager
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $noteText)
                    .padding()
                    .frame(maxHeight: .infinity)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !noteText.isEmpty {
                            contactManager.addNoteEntry(for: contact, entry: noteText)
                            onSave()
                            dismiss()
                        }
                    }
                    .disabled(noteText.isEmpty)
                }
            }
        }
    }
} 
