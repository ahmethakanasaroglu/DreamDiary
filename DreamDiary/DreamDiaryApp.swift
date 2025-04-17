//
//  DreamDiaryApp.swift
//  DreamDiary
//
//  Created by Ahmet Hakan Asaroğlu on 17.04.2025.
//

import SwiftUI

@main
struct DreamDiaryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
