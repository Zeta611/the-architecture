//
//  ItemView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import SwiftUI

final class ItemViewModel: ObservableObject {
    @Published var group: Group

    // Used in case when this view can remove the group itself
    var onDelete: () -> Void = { }

    init(group: Group) {
        self.group = group
        self.group.items.sort()
    }

    func addItem() {
        withAnimation {
            let newItem = Item(id: Item.ID(UUID()), name: "I\(group.items.count + 1)")
            group.items.append(newItem)
            group.items.sort()
        }
    }

    func deleteItems(offsets: IndexSet) {
        group.items.remove(atOffsets: offsets)
    }
}

struct ItemView: View {
    @ObservedObject private(set) var viewModel: ItemViewModel
    
    var body: some View {
        //        SwiftUI.Group {
        //            if viewModel.group {
        //                EmptyView()
        //            } else {
        List {
            ForEach(viewModel.group.items) { item in
                Text(item.name)
            }
            .onDelete(perform: viewModel.deleteItems)
        }
        .navigationTitle(viewModel.group.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: viewModel.addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        //            }
        //        }
    }
}

struct ItemView_Previews: PreviewProvider {
    static let group = {
        let viewContext = PersistenceController.preview.container.viewContext
        let groups = try! viewContext.fetch(GroupStore.fetchRequest())
        return groups.first!
    }()

    static var previews: some View {
        NavigationStack {
            ItemView(
                viewModel: ItemViewModel(group: Group(store: group))
            ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
