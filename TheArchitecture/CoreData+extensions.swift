//
//  CoreData+extensions.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import CoreData
import IdentifiedCollections

extension Group {
    init(store: GroupStore) {
        id = Group.ID(store.id!)
        name = store.name!
        items = IdentifiedArray(uniqueElements: (store.items! as! Set<ItemStore>).map(Item.init))
    }

    @discardableResult
    func store(context: NSManagedObjectContext, items: Set<ItemStore>) -> GroupStore {
        let store = GroupStore(context: context)
        store.id = id.rawValue
        store.name = name
        store.items = items as NSSet
        return store
    }
}

extension Item {
    init(store: ItemStore) {
        id = Item.ID(store.id!)
        name = store.name!
    }

    @discardableResult
    func store(context: NSManagedObjectContext, group: GroupStore) -> ItemStore {
        let store = ItemStore(context: context)
        store.id = id.rawValue
        store.name = name
        store.group = group
        return store
    }
}
