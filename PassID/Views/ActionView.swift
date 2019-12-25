//
//  SessionView.swift
//  PassID
//
//  Created by smlu on 21/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


enum Action {
    case register
    case login
    
    public func asString() -> String {
        switch self {
        case .register:
            return "register"
        case .login:
            return "login"
        }
    }
}


struct ActionView: View {
    
    init(action: Action) {
        self.action = action
        self.client = PassIdClient(url: self.settings.url, timeout: self.settings.timeout)
    }

    let action: Action
    @State var actionSucceeded = false
    let log = Log(category: "action.view")
    
    private let client: PassIdClient
    @State private var srvMsg: String = ""
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    private let settings = SettingsStore()
    
    @State private var showActivity = false
    
    @State var challenge: ProtoChallenge? = nil
    @State var actionCompletionCallback: ((PassportData) -> ())? = nil
    
    var body: some View {
        return Group {
            if actionSucceeded {
                SuccessView(action: action, uid: client.uid!, srvMsg: srvMsg)
            }
            else {
                ActivityView(msg: "Please wait ...", showActivity: $showActivity) {
                    PassportView(challenge: self.$challenge, action: self.action, settings: self.settings)
                        .onDismiss {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        .onPassportData { data in
                            self.showActivity = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.actionCompletionCallback?(data)
                            }
                        }
                    .navigationBarTitle(self.action.asString().capitalized)
                    .navigationBarItems(trailing:
                       SettingsButton(settings: self.settings)
                           .onDismiss {
                               self.updateClient()
                           }
                    )
                }
                .onDisappear {
                    self.client.cancelChallenge()
                }
                .onAppear{
                    self.showActivity = true
                    self.initClient()
                    
                    switch self.action {
                        case .register:
                            self.connectCallbacks(
                                self.client.register()
                            )
                        case .login:
                            self.connectCallbacks(
                                self.client.login()
                            )
                    }
                }
            }
        }
    }
    
    func initClient() {
        updateClient()
        client.onConnectionError { _, retry in
            self.showActivity = false
            let alert = AlertController(title: "Connection Error", message: "Failed to connect to server", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go Back", style: .cancel) { _ in
                self.goBack()
            })
            alert.addAction(UIAlertAction(title: "Retry", style: .default) {_ in
                self.showActivity = true
                retry(true)
            })
            self.showAlert(alert)
       }
    }
    
    func updateClient() {
        self.client.url     = self.settings.url
        self.client.timeout = self.settings.timeout
    }
    
    private func goBack() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func connectCallbacks(_ promise: PassIdClient.SessionPromise) {
        promise
            .onChallenge{ challenge, cb in
                self.showActivity = false
                self.signChallenge(challenge, cb)
            }
            .onSuccess{ uid in
                self.handleSuccess(uid)
            }
            .onError{ error in
                self.showActivity = true
                self.handleError(error)
            }
    }
    
    private func signChallenge(_ challenge: ProtoChallenge, _ completion: @escaping (PassportData) -> Void) {
        log.debug("Got challenge cid: %@ challenge: %@", challenge.id.data.hex(), challenge.data.hex())
        self.challenge = challenge
        self.actionCompletionCallback = completion
    }
    
    private func handleSuccess(_ uid: UserId) {
        log.debug("PassId session was successfully created, uid: %@", uid.data.hex())
        self.showActivity = true
        self.client.requestGreeting { msg, error in
            if error != nil {
                self.handleError(error!)
            }
            else {
                self.actionSucceeded = true
                self.srvMsg = msg!
            }
        }
    }
    
    private func handleError(_ error: ApiError) {
        log.error("Failed to create passId session! error: '%@'", error.localizedDescription)
        self.showActivity = false
        switch error {
        case .apiError(let apiError):
            var title = "PassID Error"
            var msg: String? = "Server returned error:\n\(apiError.message)"
            switch apiError.code {
                case 401:
                    msg = "Authorisation failed!"
                case 404:
                    msg = apiError.message
                case 406:
                    msg = "Passport verification failed!"
                    if apiError.message == "Invalid DG1 file" {
                         msg = "Server refused to accept sent personal data!"
                    }
                    else if apiError.message == "Invalid DG15 file" {
                         msg = "Server refused to accept passport's public key!"
                    }
                case 409:
                    msg = "Account already exists!"
                case 412:
                    msg = "Passport trust chain verification failed!"
                default:
                    title = msg!
                    msg = nil
            }
            showFatalAlert(title: title, message: msg)
        case .rpcError(let rpcError):
            showFatalAlert(title: rpcError.message, message: nil)
        default:
            self.goBack()
        }
    }
    
    private func showFatalAlert(title: String, message: String?) {
        let alert = AlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { _ in
            self.goBack()
        })
        self.showAlert(alert)
    }
}


struct ActionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActionView(action: .register)
                .environment(\.colorScheme, .dark)
        }
    }
}
