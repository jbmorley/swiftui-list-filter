//
//  ContentView.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import Combine
import SwiftUI

struct SearchField: NSViewRepresentable {

    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchField

        init(_ parent: SearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else {
                print("Unexpected control in update notification")
                return
            }
            self.parent.search = searchField.stringValue
        }

    }

    @Binding var search: String

    func makeNSView(context: Context) -> NSSearchField {
        return NSSearchField(frame: .zero)
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        searchField.stringValue = search
        searchField.delegate = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

}


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
    let range = 0..<6000
//    let range = 0..<100000
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8.0) {
                ForEach(filter.filteredItems) { item in
                    HStack {
                        Text(item.title)
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .toolbar(content: {
            ToolbarItem {
                Button {
                    provider.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem {
                Button {
                    sort = sort == .titleAscending ? .titleDescending : .titleAscending
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem {
                SearchField(search: $filter.filter)
                    .frame(width: 200)
            }
        })
    }

}

struct ContentView: View {

    @State var counter: Int = 0
    @StateObject var provider = ItemProvider()

    var body: some View {
//        VStack {
            ListView(provider: provider)
//                .padding()
//        }
    }
}
