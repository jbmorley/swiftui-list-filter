//
//  ListView.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import SwiftUI

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
