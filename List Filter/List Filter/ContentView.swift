//
//  ContentView.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import Combine
import SwiftUI

// N.B. These need to be classes to avoid copy-by-value.
class ListItem: Identifiable, Hashable {

    public var id = UUID()
    var title: String

    init(title: String) {
        self.title = title
    }

    static func == (lhs: ListItem, rhs: ListItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

func items() -> [ListItem] {
    let range = 0..<100000
    let items = range.map { _ in ListItem(title: UUID().uuidString) }
    return items
}

class ItemProvider: ObservableObject {

    @Published var items = List_Filter.items()

    init() {
        print("creating item provider")
    }

    func reload() {
        DispatchQueue.global(qos: .background).async {
            let items = List_Filter.items()
            DispatchQueue.main.async {
                self.items = items
            }
        }
    }

}

typealias SortDescriptor<Value> = (_ lhs: Value, _ rhs: Value) -> Bool


class LazyFilter<T>: ObservableObject where T: Hashable {

    let queue = DispatchQueue(label: "LazyFilter.queue")
    var subscription: Cancellable?

    @Published var _filter: String = ""
    @Published var _sortDescriptor: SortDescriptor<T> = { lhs, rhs in true }

    @Published var filteredItems: [T] = []
    var filter: Binding<String>!
    var sortDescriptor: Binding<SortDescriptor<T>>!

    init(items: Published<[T]>.Publisher,
         test: @escaping (_ filter: String, _ item: T) -> Bool,
         initialSortDescriptor: @escaping SortDescriptor<T>) {
        __sortDescriptor = Published(initialValue: initialSortDescriptor)
        subscription = items
            .combineLatest($_filter, $_sortDescriptor)
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: queue)
            .map { items, filter, sortDescriptor in
                print("regenerating list")
                return items
                    .filter { test(filter, $0) }
                    .sorted(by: sortDescriptor)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredItems, on: self)
        filter = Binding {
            return self._filter
        } set: { value in
            self._filter = value
        }
        sortDescriptor = Binding {
            return self._sortDescriptor
        } set: { value in
            self._sortDescriptor = value
        }
    }

}

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

struct ListView: View {

    var provider: ItemProvider
    @StateObject var filter: LazyFilter<ListItem>
    @State var sort: SortIdentifier = .titleAscending {
        didSet {
            filter.sortDescriptor.wrappedValue = sort.sortDescriptor
            print("sort = \(sort)")
        }
    }

    init(provider: ItemProvider) {
        self.provider = provider
        self._filter = StateObject(wrappedValue: LazyFilter(items: provider.$items, test: { filter, item in
            filter.isEmpty ? true : item.title.localizedCaseInsensitiveContains(filter)
        }, initialSortDescriptor: SortIdentifier.titleAscending.sortDescriptor))
    }

    var columns: [GridItem] = [
        GridItem(.flexible(minimum: 0, maximum: .infinity))
    ]

    var body: some View {
        VStack {
            HStack {
                Button {
                    provider.reload()
                } label: {
                    Text("Reload")
                }
                Button {
                    sort = sort == .titleAscending ? .titleDescending : .titleAscending
                } label: {
                    Text("Change Sort")
                }
            }
            TextField("Search", text: filter.filter)
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(filter.filteredItems) { item in
                        HStack {
                            Text(item.title)
                            Spacer()
                        }
                    }
                }
            }
            Text("\(filter.filteredItems.count) items")
        }
    }

}

struct ContentView: View {

    @State var counter: Int = 0
    @StateObject var provider = ItemProvider()

    var body: some View {
        VStack {
            Text("count = \(counter)")
                .padding()
            ListView(provider: provider)
                .padding()
            VStack {
                Button {
                    print("increment counter")
                    counter = counter + 1
                } label: {
                    Text("Click")
                }
                Text("Increments a counter; shouldn't reload the list, or recreate any list state")
                    .font(.caption)
            }
            .padding()
        }
    }
}
