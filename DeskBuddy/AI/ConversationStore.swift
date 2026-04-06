// DeskBuddy/AI/ConversationStore.swift
import CoreData
import Foundation

class ConversationStore {
    static let shared = ConversationStore()

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Build model programmatically to avoid .xcdatamodeld file dependency
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Message"
        entity.managedObjectClassName = "DeskBuddy.Message"

        let idAttr = NSAttributeDescription(); idAttr.name = "id"; idAttr.attributeType = .UUIDAttributeType
        let roleAttr = NSAttributeDescription(); roleAttr.name = "role"; roleAttr.attributeType = .stringAttributeType
        let contentAttr = NSAttributeDescription(); contentAttr.name = "content"; contentAttr.attributeType = .stringAttributeType
        let tsAttr = NSAttributeDescription(); tsAttr.name = "timestamp"; tsAttr.attributeType = .dateAttributeType
        entity.properties = [idAttr, roleAttr, contentAttr, tsAttr]
        model.entities = [entity]

        container = NSPersistentContainer(name: "DeskBuddy", managedObjectModel: model)
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load failed: \(error)") }
        }
    }

    var context: NSManagedObjectContext { container.viewContext }

    func save(role: String, content: String) {
        let msg = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context)
        msg.setValue(UUID(), forKey: "id")
        msg.setValue(role, forKey: "role")
        msg.setValue(content, forKey: "content")
        msg.setValue(Date(), forKey: "timestamp")
        try? context.save()
    }

    func recentMessages(limit: Int = 20) -> [(role: String, content: String)] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Message")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        let results = (try? context.fetch(request)) ?? []
        return results.reversed().map {
            (role: $0.value(forKey: "role") as? String ?? "user",
             content: $0.value(forKey: "content") as? String ?? "")
        }
    }

    func clearAll() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        try? context.execute(delete)
    }
}
