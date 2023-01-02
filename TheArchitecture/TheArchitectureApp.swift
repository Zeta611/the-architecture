//
//  TheArchitectureApp.swift
//  TheArchitecture
//
//  Created by Jay Lee on 2023/01/02.
//

import SwiftUI

@main
struct TheArchitectureApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
