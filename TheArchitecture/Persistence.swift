//
//  Persistence.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        for i in 0..<5 {
            let newGroup = GroupStore(context: viewContext)
            newGroup.id = UUID()
            newGroup.name = "G\(i)"
            newGroup.items = NSSet()
            for j in 0..<100 {
                let newItem = ItemStore(context: viewContext)
                newItem.id = UUID()
                newItem.name = "I\(j)"
                newItem.group = newGroup
                newGroup.addToItems(newItem)
            }
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TheArchitecture")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
