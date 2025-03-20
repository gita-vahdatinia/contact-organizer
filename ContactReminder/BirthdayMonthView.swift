import SwiftUI

struct BirthdayMonthView: View {
    @ObservedObject var contactManager: ContactManager
    @State private var selectedMonth: Int
    
    init(contactManager: ContactManager) {
        self._contactManager = ObservedObject(wrappedValue: contactManager)
        // Initialize with current month (1-12)
        self._selectedMonth = State(initialValue: Calendar.current.component(.month, from: Date()))
    }
    
    var filteredContacts: [ContactModel] {
        // Filter contacts that have birthdays and are in selected month
        let contactsWithBirthdays = contactManager.contacts.filter { $0.birthday != nil }
        let monthContacts = contactsWithBirthdays.filter {
            Calendar.current.component(.month, from: $0.birthday!) == selectedMonth
        }
        
        // Sort by day of month
        return monthContacts.sorted {
            Calendar.current.component(.day, from: $0.birthday!) <
            Calendar.current.component(.day, from: $1.birthday!)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(monthName(month))
                            .tag(month)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                List {
                    ForEach(filteredContacts) { contact in
                        if let phoneNumber = contact.phoneNumber {
                            Button(action: {
                                if let url = URL(string: "sms:\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Birthday: \(formattedDate(contact.birthday!))")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 5)
                            }
                        } else {
                            // For contacts without phone numbers, show non-tappable view
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(.headline)
                                Text("Birthday: \(formattedDate(contact.birthday!))")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("Birthday Month")
            .onAppear {
                contactManager.fetchContacts()
            }
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        return dateFormatter.monthSymbols[month - 1]
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
} 