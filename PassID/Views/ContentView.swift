//
//  ContentView.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showSetingsView = false
    var body: some View {
        NavigationView {
    
            Text("Hello, PassID!")
            .navigationBarTitle("PassID")
            .navigationBarItems(trailing: SettingsButton())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            //ContentView()
            ContentView()
                .environment(\.colorScheme, .dark)
        }
    }
}
