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
    @Published var selectedGroups: Set<UUID> = [] {
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
                navigationDestination = .itemView(ItemViewModel(group: group))
            } else {
                navigationDestination = nil
            }
        }
    }

    @Published var navigationDestination: NavigationDestination? {
        didSet { bind() }
    }
    private var destinationCancellable: AnyCancellable?

    enum NavigationDestination {
        case itemView(ItemViewModel)
    }

    @Published var editMode: EditMode = .inactive
    @Published var editDestination: EditDestination = .inactive {
        didSet { bindEditMode() }
    }
    enum EditDestination: Equatable {
        case inactive
        case active(confirm: Bool)
    }

    init(groups: [Group]) {
        self.groups = groups
        self.groups.sort()
        self.bind()
    }

    private func bind() {
        guard case let .itemView(itemViewModel) = navigationDestination else {
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

    private func bindEditMode() {
        withAnimation {
            switch editDestination {
            case .inactive:
                editMode = .inactive
            case .active(confirm: _):
                editMode = .active
            }
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

    func delete(group: Group) {
        guard let index = groups.firstIndex(of: group) else {
            assertionFailure()
            return
        }
        groups.remove(at: index)
    }

    func toggleEditMode() {
        switch editDestination {
        case .active(confirm: _):
            editDestination = .inactive
        case .inactive:
            editDestination = .active(confirm: false)
        }
    }

    func deleteSelectedGroups() {
        withAnimation {
            groups.removeAll { group in
                selectedGroups.contains { group.id == $0 }
            }
            editDestination = .inactive
        }
    }

    func confirmDelete() {
        editDestination = .active(confirm: true)
    }
}

struct GroupView: View {
    @ObservedObject private(set) var viewModel: GroupViewModel

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedGroups) {
                ForEach(viewModel.groups) { group in
                    NavigationLink(group.name, value: group.id)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(group: group)
                            }
                        }
                }
            }
            .navigationTitle("Groups")
            .environment(\.editMode, $viewModel.editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        viewModel.editMode.isEditing ? "Done" : "Edit",
                        action: viewModel.toggleEditMode
                    )
                }
                ToolbarItem {
                    Button(action: viewModel.addGroup) {
                            Label("Add Group", systemImage: "plus")
                    }
                }
                if viewModel.editMode.isEditing {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete", action: viewModel.confirmDelete)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(viewModel.selectedGroups.count)",
                isPresented: Binding {
                    viewModel.editDestination == .active(confirm: true)
                } set: {
                    guard case .active = viewModel.editDestination else { return }
                    viewModel.editDestination = .active(confirm: $0)
                }
            ) {
                Button("Delete", role: .destructive, action: viewModel.deleteSelectedGroups)
                Button("Cancel", role: .cancel) {}
            }
        } detail: {
            if case let .itemView(itemViewModel) = viewModel.navigationDestination {
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
