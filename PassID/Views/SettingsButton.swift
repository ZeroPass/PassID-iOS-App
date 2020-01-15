//
//  StettingsButton.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct SettingsSheet: View {
    @EnvironmentObject var settings: SettingsStore

    @State private var showActivity = false
    @Environment(\.presentationMode)
    private var presentationMode: Binding<PresentationMode>
    var body: some View {
        ActivityView(msg: "Trying to connect to server ...", showActivity: $showActivity) {
            // Note: when activity is visible it won't cover the whole screen when using this view as modal popup.
            NavigationView {
                Form {
                    Section(header: Text("PassID Server")) {
                        TextEdit("Server URL", value: self.$settings.url)
                            .defaultValue(SettingsStore.DEFAULT_URL)
                            .inputValidator({ v in return Utils.isValidUrl(v, forceAddressAndPort: false) })
                            .keyboardType(.URL)
                            .textContentType(.URL)
                        TextEdit("Timeout", placeholder: String(SettingsStore.DEFAULT_TIMEOUT), value: self.$settings.timeout)
                            .defaultValue(SettingsStore.DEFAULT_TIMEOUT)
                            .keyboardType(.decimalPad)
                            .minValue(1.0)
                            .maxValue(99.9)
                    
                        Button(action: {
                            self.showActivity = true
                            let api = PassIdApi(url: self.settings.url, timeout: self.settings.timeout)
                            api.ping(ping: UInt32.random(in: 0..<UInt32.max)) { response in
                                self.showActivity = false
                                if response.value != nil {
                                    Toast.show(message: "Connection succeeded!")
                                }
                                else {
                                    Toast.show(message: "Connection failed!")
                                }
                            }
                        }) {
                            HStack(alignment: .center) {
                                Spacer()
                                Text("Test Connection")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationBarTitle(Text("Settings"))
                .navigationBarItems(trailing: Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                    Text("Close")
                })
            }
        }
    }
}


struct SettingsButton : View {
    public let settings: SettingsStore
    
    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
    }
    
    private var dismissCallback: (() -> Void)? = nil
    @State private var showSheet = false
    
    var body: some View {
        Button(action: { self.showSheet = true }){
            Text("Settings")
        }
        .sheet(isPresented: $showSheet, onDismiss: { self.showSheet = false; self.dismissCallback?() }) {
            SettingsSheet().environmentObject(self.settings)
        }
    }
}

extension SettingsButton {
    func onDismiss(callback: (() -> Void)? = nil) -> SettingsButton {
        var copy = self
        copy.dismissCallback = callback
        return copy
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsSheet()
                .environmentObject(SettingsStore())
                .environment(\.colorScheme, .dark)
            SettingsButton()
                .environment(\.colorScheme, .dark)
        }
    }
}
