//
//  Group.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import Foundation

// Should have named this differently...
struct Group: Identifiable, Hashable, Comparable {
    let id: UUID
    var name: String
    var items: [Item]

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.name < rhs.name
        || lhs.name == rhs.name && lhs.id < rhs.id
    }
}
