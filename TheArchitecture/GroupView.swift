//
//  GroupView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import Combine
import CoreData
import IdentifiedCollections
import SwiftUI
import SwiftUINavigation
import Tagged

final class GroupViewModel: ObservableObject {
    @Published var groups: IdentifiedArrayOf<Group>
    @Published var selectedGroups: Set<Group.ID> = []

    private var cancellables: Set<AnyCancellable> = []

    @Published var navigationDestination: NavigationDestination? {
        didSet { bind() }
    }
    private var destinationCancellable: AnyCancellable?
    enum NavigationDestination {
        case itemView(ItemViewModel)
    }

    var editMode: Binding<EditMode> {
        Binding { [weak self] in
            guard let self else { return .inactive }
            switch self.editDestination {
            case .none:
                return .inactive
            case .isEditing:
                return .active
            }
        } set: { [weak self] editMode in
            guard let self else { return }
            self.editDestination = .isEditing(nil)
        }
    }

    @Published var editDestination: EditDestination?
    enum EditDestination: Equatable {
        case isEditing(ConfirmationDialogState<DialogAction>?)

        enum DialogAction {
            case delete
            case cancel
        }
    }

    init(
        viewContext: NSManagedObjectContext,
        navigationDestination: NavigationDestination? = nil,
        editDestination: EditDestination? = nil
    ) {
        defer { bind() }

        let fetchRequest = GroupStore.fetchRequest()
        do {
            let groupStores = try viewContext.fetch(fetchRequest)
            self.groups = IdentifiedArray(uniqueElements: groupStores.map(Group.init))
        } catch {
            self.groups = []
        }

        defer { self.groups.sort() }

        self.navigationDestination = navigationDestination
        self.editDestination = editDestination

        self.$groups
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { groups in
                // Save to Core Data
                let requestForUpdateExisting = GroupStore.fetchRequest()
                requestForUpdateExisting.predicate = NSPredicate(
                    format: "%K IN %@",
                    // \GroupStore.id worked before, but not now:
                    // https://stackoverflow.com/a/74004215
                    NSExpression(forKeyPath: \GroupStore.id).keyPath,
                    groups.map { $0.id.rawValue as NSUUID }
                )

                let requestForRemoveExisting = GroupStore.fetchRequest()
                requestForRemoveExisting.predicate = NSPredicate(
                    format: "NOT (%K IN %@)",
                    NSExpression(forKeyPath: \GroupStore.id).keyPath,
                    groups.map { $0.id.rawValue as NSUUID }
                )

                // This is a stupid logic that should be modified; but it serves its purpose for now
                do {
                    // For updating existing groups
                    let updateGroupStores = try viewContext.fetch(requestForUpdateExisting)
                    for groupStore in updateGroupStores {
                        let groupID = groupStore.id!
                        guard let group = groups[id: Tagged(groupID)] else {
                            // Group deleted
                            viewContext.delete(groupStore)
                            continue
                        }

                        if group.name != groupStore.name {
                            groupStore.name = group.name
                        }

                        for itemStore in groupStore.items! as! Set<ItemStore> {
                            let itemID = itemStore.id!
                            guard let item = group.items[id: Tagged(itemID)] else {
                                // Item deleted
                                viewContext.delete(itemStore)
                                continue
                            }

                            if item.name != itemStore.name {
                                itemStore.name = item.name
                            }
                        }
                        for item in group.items {
                            guard !(groupStore.items! as! Set<ItemStore>).contains(where: { $0.id == item.id.rawValue }) else {
                                continue
                            }

                            item.store(context: viewContext, group: groupStore)
                        }
                    }

                    // For adding new groups
                    for group in groups {
                        guard !updateGroupStores.contains(where : { $0.id == group.id.rawValue }) else {
                            continue
                        }

                        let newGroupStore = group.store(context: viewContext, items: [])
                        for item in group.items {
                            item.store(context: viewContext, group: newGroupStore)
                        }
                    }

                    // For removing existing groups
                    let removeGroupStores = try viewContext.fetch(requestForRemoveExisting)
                    removeGroupStores.forEach { viewContext.delete($0) }

                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
            .store(in: &cancellables)
    }

    func groupTapped(_ group: Group) {
        navigationDestination = .itemView(ItemViewModel(group: group))
    }

    func addGroup() {
        let newGroup = Group(id: Group.ID(UUID()), name: "G\(groups.count + 1)", items: [])
        groups.append(newGroup)
        groups.sort()
    }

    func deleteGroups(offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
    }

    func delete(group: Group) {
        guard groups.remove(group) != nil else {
            assertionFailure()
            return
        }
        if case let .itemView(itemViewModel) = navigationDestination,
            itemViewModel.group.id == group.id
        {
            navigationDestination = nil
        }
    }

    func toggleEditMode() {
        withAnimation {
            switch editDestination {
            case .isEditing:
                editDestination = nil
            case .none:
                editDestination = .isEditing(nil)
            }
        }
    }

    func deleteSelectedGroups() {
        withAnimation {
            groups.removeAll { group in
                selectedGroups.contains(group.id)
            }
            editDestination = nil
        }
    }

    func dispatch(_ action: EditDestination.DialogAction) {
        switch action {
        case .cancel:
            editDestination = .isEditing(nil)
        case .delete:
            deleteSelectedGroups()
        }
    }

    func confirmDelete() {
        editDestination = .isEditing(.deleteGroups)
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
            self.groups[id: group.id] = group
        }
    }
}

struct GroupView: View {
    @ObservedObject private(set) var viewModel: GroupViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedGroups) {
                ForEach(viewModel.groups) { group in
                    Button {
                        viewModel.groupTapped(group)
                    } label: {
                        HStack(spacing: 0) {
                            Text(group.name)
                            Spacer()
                        }
                        // a hack to make the button tappable outside the text
                        .contentShape(Rectangle())
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            viewModel.delete(group: group)
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .environment(\.editMode, viewModel.editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        viewModel.editMode.wrappedValue.isEditing ? "Done" : "Edit",
                        action: viewModel.toggleEditMode
                    )
                }
                ToolbarItem {
                    Button(action: viewModel.addGroup) {
                            Label("Add Group", systemImage: "plus")
                    }
                }
                if viewModel.editMode.wrappedValue.isEditing {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete", action: viewModel.confirmDelete)
                    }
                }
            }
            .confirmationDialog(unwrapping: $viewModel.editDestination, case: /GroupViewModel.EditDestination.isEditing) { action in
                viewModel.dispatch(action)
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

extension ConfirmationDialogState where Action == GroupViewModel.EditDestination.DialogAction {
    static let deleteGroups = ConfirmationDialogState(
        title: TextState("Delete groups?"),
        titleVisibility: .visible,
        buttons: [
            .destructive(TextState("Delete"), action: .send(.delete)),
            .cancel(TextState("Cancel"), action: .send(.cancel))
        ]
    )
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        let viewContext = PersistenceController.preview.container.viewContext
        GroupView(
            viewModel: GroupViewModel(
                viewContext: viewContext,
                editDestination: .isEditing(.deleteGroups)
            )
        )
        .environment(\.managedObjectContext, viewContext)
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
