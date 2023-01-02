//
//  ItemView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import SwiftUI

struct ItemView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject private(set) var group: GroupStore
    private var items: [ItemStore] {
        return Array(group.items! as! Set<ItemStore>).sorted(by: { x, y in
            x.name! < y.name!
            || x.name! == y.name! && x.id!.uuidString < y.id!.uuidString
        })
    }
    
    var body: some View {
        Group {
            if group.isFault {
                EmptyView()
            } else {
                List {
                    ForEach(items, id: \.self) { item in
                        Text(item.name!)
                    }
                    .onDelete(perform: deleteItems)
                }
                .navigationTitle(group.name!)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = ItemStore(context: viewContext)
            newItem.id = UUID()
            newItem.name = "I\(items.count + 1)"
            newItem.group = group

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let items = items
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ItemView_Previews: PreviewProvider {
    static let group = {
        let viewContext = PersistenceController.preview.container.viewContext
        do {
            let groups = try viewContext.fetch(GroupStore.fetchRequest())
            return groups.first!
        } catch {
            fatalError("\(error)")
        }
    }()

    static var previews: some View {
        NavigationStack {
            ItemView(group: group).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
