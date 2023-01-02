//
//  GroupView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import SwiftUI

struct GroupView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroupStore.name, ascending: true)],
        animation: .default)
    private var groups: FetchedResults<GroupStore>

    @State var selectedGroups: Set<GroupStore> = []

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedGroups) {
                ForEach(groups, id: \.self) { group in
                    NavigationLink(group.name!, value: group)
                }
                .onDelete(perform: deleteGroups)
            }
            .navigationDestination(for: GroupStore.self) { group in
                ItemView(group: group)
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addGroup) {
                        Label("Add Group", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if !selectedGroups.isEmpty {
                ItemView(group: selectedGroups.first!)
            } else {
                Text("Select a group")
            }
        }
    }

    private func addGroup() {
        withAnimation {
            let newGroup = GroupStore(context: viewContext)
            newGroup.id = UUID()
            newGroup.name = "G\(groups.count + 1)"
            newGroup.items = []

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteGroups(offsets: IndexSet) {
        withAnimation {
            offsets.map { groups[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
