//
//  LazyFilter.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import Combine
import SwiftUI

class LazyFilter<T>: ObservableObject where T: Hashable {

    let queue = DispatchQueue(label: "LazyFilter.queue")
    var subscription: Cancellable?

    @Published var filter: String = ""
    @Published var _sortDescriptor: SortDescriptor<T> = { lhs, rhs in true }

    @Published var filteredItems: [T] = []
    var sortDescriptor: Binding<SortDescriptor<T>>!

    init(items: Published<[T]>.Publisher,
         test: @escaping (_ filter: String, _ item: T) -> Bool,
         initialSortDescriptor: @escaping SortDescriptor<T>) {
        print("LazyFilter.init")
        __sortDescriptor = Published(initialValue: initialSortDescriptor)
        subscription = items
            .combineLatest($filter, $_sortDescriptor)
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .receive(on: queue)
            .map { items, filter, sortDescriptor in
                print("regenerating list")
                return items
                    .filter { test(filter, $0) }
                    .sorted(by: sortDescriptor)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredItems, on: self)
        sortDescriptor = Binding {
            return self._sortDescriptor
        } set: { value in
            self._sortDescriptor = value
        }
    }

}
