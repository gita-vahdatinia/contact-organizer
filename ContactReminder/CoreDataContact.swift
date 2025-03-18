import CoreData

extension ContactEntity {
    func toModel() -> ContactModel {
        return ContactModel(
            id: id ?? UUID(),
            name: name ?? "Unknown",
            phoneNumber: phoneNumber,
            birthday: birthday,
            group: ContactGroup(rawValue: group ?? "Daily") ?? .daily
        )
    }
}
