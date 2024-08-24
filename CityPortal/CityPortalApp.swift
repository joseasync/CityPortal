//
//  CityPortalApp.swift
//  CityPortal
//
//  Created by Jose Cruz on 15/08/2024.
//

import SwiftUI

@main
struct CityPortalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
