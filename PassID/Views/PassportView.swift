//
//  PassportReaderView.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct PassportView: View {
    
    init(challenge: Binding<ProtoChallenge?>, action: Action, settings: SettingsStore) {
        self.challenge = challenge
        self.action    = action
        self.settings  = settings
    }
    
    var challenge: Binding<ProtoChallenge?>
    
    public let action: Action
    public let settings: SettingsStore
    
    private var dismissCallback: (() -> Void)? = nil
    private var passportDataCallback: ((PassportData) -> Void)? = nil
    
    @State private var passportNum: String = ""
    @State private var dob = decadeAgo
    @State private var doe = tomorrow
    private let mrtd = MRTDReader()
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    private static let tomorrow  = Date().addingTimeInterval(86400)
    private static let decadeAgo = Calendar.current.date(
                                        byAdding: .year,
                                        value: -10,
                                        to: Date())!
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 20)
            Form {
                Section(header: HStack {
                    Spacer()
                    Text("Enter passport details")
                        .foregroundColor(.secondary)
                        .font(.title)
                    Spacer()
                }) {
                    HStack {
                        Text("Passport Number")
                            Spacer()
                        TextEdit(placeholder: "<<<<<<<<<", value: $passportNum)
                            .keyboardType(.asciiCapable)
                            .textContentType(.name)
                            .inputValidator({ v in return Utils.isValidPassportNumber(v, forceMinSize: false) })
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.primary)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 125)
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    DatePicker(selection: $dob, in: ...PassportView.decadeAgo, displayedComponents: .date) {
                        Text("Date of Birth")
                            .foregroundColor(.primary)
                    }
                    .padding([.leading, .trailing])
                    .foregroundColor(Color.blue)
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    DatePicker(selection: $doe, in: PassportView.tomorrow..., displayedComponents: .date) {
                        Text("Date of Expiry")
                            .foregroundColor(.primary)
                    }
                    .padding([.leading, .trailing])
                    .foregroundColor(Color.blue)
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))

                    if settings.mrzKey != nil {
                        Button(action: {
                            let mrzKey = self.settings.mrzKey!
                            self.passportNum = mrzKey.mrtdNumber()
                            self.dob = mrzKey.dateOfBirth()
                            self.doe = mrzKey.dateOfExpiry()
                        }){
                            HStack {
                                Spacer()
                                Text("Fill from storage")
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    }
                }
            }

            Button(action: {
                let mrzKey = MRZKey(mrtdNumber: self.passportNum, dateOfBirth: self.dob, dateOfExpiry: self.doe)
                self.settings.mrzKey = mrzKey
                self.scanPassport(mrzKey: mrzKey)
            }){
                ButtonView(text: "Scan Passport & \(self.action.asString().capitalized)")
                    .disabled(!validMRZData())
            }.disabled(!validMRZData())
            
            Spacer()
                .frame(minHeight: 50)
        }
        //.onTapGesture { UIApplication.shared.sendAction(#selector(UIView.resignFirstResponder), to: nil, from: nil, for: nil) }
    }
    
    func validMRZData() -> Bool {
        return Utils.isValidPassportNumber(self.passportNum)
    }
    
    func scanPassport(mrzKey: MRZKey) {
        mrtd.startSession(mrzKey: mrzKey) { error in
            if error != nil {
                Log.error("%@", error!.localizedDescription)
                PassportView.dispatchOnMainQueue {
                    Toast.show(message: "Failed to establish passport session")
                }
            }
            else {
                self.mrtd.readLDSFiles(tags: [.efCOM, .efSOD, .efDG1, .efDG14, .efDG15]) {(ldsFiles, error) in
                    if error != nil {
                        Log.error("%@", error!.localizedDescription)
                    }
                    else {
                        if ldsFiles.count != 5 {
                            Log.warning("Error: Not all files were read from passport!")
                            var errorMsg = "Not all files were read from passport.\nPlease try again!"
                            if ldsFiles.contains(.efCOM) {
                                let com: EfCOM = try! ldsFiles[.efCOM]!.asFile()
                                if !com.tags.contains(.efDG15) {
                                    errorMsg = "Unsupported Passport!"
                                }
                            }
                            self.mrtd.endSession(withError: errorMsg)
                        }
                        else {
                            self.mrtd.internalAuthenticate(challenge: self.challenge.wrappedValue!.data) { csigs, error in
                                if error != nil {
                                    Log.error("%@", error!.localizedDescription)
                                    let alert = AlertController(title: "Error", message: "Failed to sign challenge!\nError: \(error!.localizedDescription)", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
                                    PassportView.dispatchOnMainQueue {
                                        self.showAlert(alert)
                                    }
                                    return
                                }
                                
                                self.mrtd.endSession()
                                if self.passportDataCallback != nil {
                                    PassportView.dispatchOnMainQueue {
                                        let data = PassportData(ldsFiles: ldsFiles, csigs: csigs!)
                                        self.passportDataCallback!(data)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    static func dispatchOnMainQueue(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // delay 3 secs
            action()
        }
    }
}

extension PassportView {
    
    private func dismiss() {
        self.presentationMode.wrappedValue.dismiss()
        if dismissCallback != nil {
            dismissCallback!()
        }
    }
    
    func onDismiss(callback: (() -> Void)? = nil) -> PassportView {
        var copy = self
        copy.dismissCallback = callback
        return copy
    }
    
    func onPassportData(_ callback: ((PassportData) -> Void)?) -> PassportView {
        var copy = self
        copy.passportDataCallback = callback
        return copy
    }
}

struct PassportReaderView_Previews: PreviewProvider {
    @State static var challenge: ProtoChallenge? = nil
    static var previews: some View {
        PassportView(challenge: $challenge, action: .register, settings: SettingsStore())
            .environment(\.colorScheme, .dark)
    }
}
