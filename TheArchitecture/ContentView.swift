//
//  ContentView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import SwiftUI
import IdentifiedCollections

struct ContentView: View {
    @Environment(\.managedObjectContext) var viewContext

    var body: some View {
        GroupView(
            viewModel: GroupViewModel(
                viewContext: viewContext,
                editDestination: .isEditing(.deleteGroups)
            )
        )
//        GroupView(
//            viewModel: GroupViewModel(
//                groups: IdentifiedArray(uniqueElements: groups.map(Group.init))
//            )
//        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
