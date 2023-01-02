//
//  CoreData+extensions.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import CoreData

extension Group {
    init(store: GroupStore) {
        id = store.id!
        name = store.name!
        items = (store.items! as! Set<ItemStore>).map(Item.init)
    }

    @discardableResult
    func store(context: NSManagedObjectContext, items: Set<ItemStore>) -> GroupStore {
        let store = GroupStore(context: context)
        store.id = id
        store.name = name
        store.items = items as NSSet
        return store
    }
}

extension Item {
    init(store: ItemStore) {
        id = store.id!
        name = store.name!
    }

    @discardableResult
    func store(context: NSManagedObjectContext, group: GroupStore) -> ItemStore {
        let store = ItemStore(context: context)
        store.id = id
        store.name = name
        store.group = group
        return store
    }
}
