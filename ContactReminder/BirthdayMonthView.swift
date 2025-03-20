import SwiftUI

struct BirthdayMonthView: View {
    @ObservedObject var contactManager: ContactManager
    @State private var selectedMonth: Int
    @Environment(\.dismiss) private var dismiss
    
    init(contactManager: ContactManager) {
        self._contactManager = ObservedObject(wrappedValue: contactManager)
        self._selectedMonth = State(initialValue: Calendar.current.component(.month, from: Date()))
    }
    
    private var filteredContacts: [ContactModel] {
        contactManager.contacts
            .filter { $0.birthday != nil }
            .filter { Calendar.current.component(.month, from: $0.birthday!) == selectedMonth }
            .sorted { Calendar.current.component(.day, from: $0.birthday!) < Calendar.current.component(.day, from: $1.birthday!) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                monthPicker
                contactsList
            }
            .navigationTitle("Birthday Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                contactManager.fetchContacts()
            }
        }
    }
    
    private var monthPicker: some View {
        Picker("Select Month", selection: $selectedMonth) {
            ForEach(1...12, id: \.self) { month in
                Text(monthName(month))
                    .tag(month)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding()
    }
    
    private var contactsList: some View {
        List {
            ForEach(filteredContacts) { contact in
                BirthdayContactRow(contact: contact)
            }
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        return dateFormatter.monthSymbols[month - 1]
    }
}

struct BirthdayContactRow: View {
    let contact: ContactModel
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Group {
            if let phoneNumber = contact.phoneNumber {
                Button(action: {
                    if let url = URL(string: "sms:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                        openURL(url)
                    }
                }) {
                    ContactInfoView(contact: contact)
                }
            } else {
                ContactInfoView(contact: contact)
            }
        }
        .padding(.vertical, 5)
    }
}

struct ContactInfoView: View {
    let contact: ContactModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(contact.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let birthday = contact.birthday {
                Text("Birthday: \(formattedDate(birthday))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
} 