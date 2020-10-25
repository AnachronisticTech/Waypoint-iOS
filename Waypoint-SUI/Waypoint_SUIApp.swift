//
//  Waypoint_SUIApp.swift
//  Waypoint-SUI
//
//  Created by Daniel Marriner on 25/10/2020.
//  Copyright © 2020 Daniel Marriner. All rights reserved.
//

import SwiftUI

@main
struct Waypoint_SUIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
