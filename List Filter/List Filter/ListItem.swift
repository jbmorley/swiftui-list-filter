//
//  ListItem.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import Foundation

// Class to avoid copy-by-value.
class ListItem: Identifiable, Hashable {

    public var id = UUID()
    var title: String { id.uuidString }

    init() {
    }

    static func == (lhs: ListItem, rhs: ListItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
