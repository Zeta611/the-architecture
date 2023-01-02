//
//  ContentView.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import SwiftUI

struct ContentView: View {
    @FetchRequest(sortDescriptors: []) var groups: FetchedResults<GroupStore>

    var body: some View {
        GroupView(viewModel: GroupViewModel(groups: groups.map(Group.init)))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
