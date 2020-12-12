//
//  SortIdentifier.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import Foundation

enum SortIdentifier {
    case titleAscending
    case titleDescending
}

extension SortIdentifier {

    var sortDescriptor: SortDescriptor<ListItem> {
        switch self {
        case .titleAscending:
            return { lhs, rhs in
                return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
        case .titleDescending:
            return { lhs, rhs in
                return lhs.title.localizedCompare(rhs.title) == .orderedDescending
            }
        }
    }

}

extension SortIdentifier: CustomStringConvertible {

    var description: String {
        switch self {
        case .titleAscending:
            return "Title, Ascending"
        case .titleDescending:
            return "Title, Descending"
        }
    }

}
