//
//  Item.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import Foundation
import Tagged

struct Item: Identifiable, Hashable, Comparable {
    let id: Tagged<Item, UUID>
    var name: String

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.name < rhs.name
        || lhs.name == rhs.name && lhs.id < rhs.id
    }
}

extension UUID: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.uuidString < rhs.uuidString
    }
}
