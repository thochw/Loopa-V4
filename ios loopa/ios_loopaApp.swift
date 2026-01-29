//
//  ios_loopaApp.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit

@main
struct ios_loopaApp: App {
    init() {
#if DEBUG
        logAvailableFonts()
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func logAvailableFonts() {
        let families = UIFont.familyNames.sorted()
        families.forEach { family in
            print("Font family: \(family)")
            let names = UIFont.fontNames(forFamilyName: family).sorted()
            names.forEach { name in
                print("  \(name)")
            }
        }
    }
}
