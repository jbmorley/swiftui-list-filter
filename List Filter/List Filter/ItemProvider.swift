//
//  ItemProvider.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import Foundation

class ItemProvider: ObservableObject {

    static func generateItems() -> [ListItem] {
        return (0..<6000).map { _ in ListItem() }
    }

    @Published var items: [ListItem] = []

    init() {
        reload()
    }

    func reload() {
        DispatchQueue.global(qos: .background).async {
            let items = Self.generateItems()
            DispatchQueue.main.async {
                self.items = items
            }
        }
    }

}
