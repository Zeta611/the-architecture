//
//  GroupView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import Combine
import SwiftUI

final class GroupViewModel: ObservableObject {
    @Published var groups: [Group]
    @Published var selectedGroups: Set<UUID> {
        didSet {
            if let groupId = selectedGroups.first,
               selectedGroups.count == 1
            {
                if let oldGroupId = oldValue.first,
                   oldValue.count == 1 && oldGroupId == groupId
                {
                    // same group selected
                    return
                }

                guard let group = groups.first(where: { $0.id == groupId }) else {
                    fatalError("programming error")
                }
                destination = .itemView(ItemViewModel(group: group))
            } else {
                destination = nil
            }
        }
    }

    @Published var destination: Destination? {
        didSet {
            self.bind()
        }
    }
    private var destinationCancellable: AnyCancellable?

    enum Destination {
        case itemView(ItemViewModel)
    }

    init(groups: [Group], selectedGroups: Set<UUID> = []) {
        self.groups = groups
        self.selectedGroups = selectedGroups
        self.groups.sort()
        self.bind()
    }

    private func bind() {
        guard case let .itemView(itemViewModel) = destination else {
            return
        }

        // nothing to do
//        itemViewModel.onDelete = { [weak self] in
//            guard let self else { return }
//        }

        destinationCancellable = itemViewModel.$group.sink { [weak self] group in
            guard let self else { return }
            guard let index = self.groups.firstIndex(where: { $0.id == group.id }) else {
                return
            }
            self.groups[index] = group
        }
    }

    func addGroup() {
        let newGroup = Group(id: UUID(), name: "G\(groups.count + 1)", items: [])
        groups.append(newGroup)
        groups.sort()
    }

    func deleteGroups(offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
    }
}

struct GroupView: View {
    @ObservedObject private(set) var viewModel: GroupViewModel

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedGroups) {
                ForEach(viewModel.groups) { group in
                    NavigationLink(group.name, value: group.id)
                }
                .onDelete(perform: viewModel.deleteGroups)
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: viewModel.addGroup) {
                        Label("Add Group", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if case let .itemView(itemViewModel) = viewModel.destination {
                ItemView(viewModel: itemViewModel)
            } else {
                Text("Select a group")
            }
        }
    }
}

struct GroupView_Previews: PreviewProvider {
    static let groups = {
        let viewContext = PersistenceController.preview.container.viewContext
        let groups = try! viewContext.fetch(GroupStore.fetchRequest())
        return groups.map(Group.init)
    }()

    static var previews: some View {
        GroupView(viewModel: GroupViewModel(groups: groups)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
