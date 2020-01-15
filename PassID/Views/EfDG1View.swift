//
//  DG1View.swift
//  PassID
//
//  Created by smlu on 13/01/2020.
//  Copyright © 2020 ZeroPass. All rights reserved.
//

import SwiftUI

struct EfDG1View: View {

    let dg1: EfDG1
    @Environment(\.presentationMode)
    private var presentationMode: Binding<PresentationMode>
    
    private let df: DateFormatter
    
    init(dg1: EfDG1){
        self.dg1 = dg1
        df = DateFormatter()
        df.dateFormat = MRZ.dateFormat
        df.dateStyle  = .medium
        df.timeStyle  = .none
        df.locale     = Locale.current
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Passport Data")) {
                    HStack {
                        Text("Passport type:")
                            .frame(width: 180, alignment: .leading)
                        Text(dg1.mrz.documentCode)
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Passport no.:")
                            .frame(width: 180, alignment: .leading)
                        Text(dg1.mrz.documentNumber)
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Date of Expiry:")
                            .frame(width: 180, alignment: .leading)
                        Text(df.string(from: dg1.mrz.dateOfExpiry))
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                }
                
                Section(header: Text("Personal Data")) {
                    HStack {
                        Text("Name:")
                        .frame(width: 180, alignment: .leading)
                        Text(dg1.mrz.firstName.capitalized())
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Last Name:")
                            .frame(width: 180, alignment: .leading)
                        Text(dg1.mrz.lastName.capitalized())
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Date of Birth:")
                            .frame(width: 180, alignment: .leading)
                        Text(df.string(from: dg1.mrz.dateOfBirth))
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Sex:")
                            .frame(width: 180, alignment: .leading)
                        Text(dg1.mrz.sex == "M" ? "Male" : "Female")
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Country:")
                            .frame(width: 180, alignment: .leading)
                        Text(countryNameForCode(dg1.mrz.country).capitalized())
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    HStack {
                        Text("Nationality:")
                            .frame(width: 180, alignment: .leading)
                        Text(countryNameForCode(dg1.mrz.nationality).capitalized())
                        Spacer()
                    }.padding([.leading, .trailing])
                    .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    
                    
                    if !dg1.mrz.optionalData.isEmpty {
                        HStack {
                            Text("Additional Data:")
                                .frame(width: 180, alignment: .leading)
                            VStack {
                                Text(dg1.mrz.optionalData)
                                if !dg1.mrz.optionalData2.isEmpty {
                                    Text(dg1.mrz.optionalData2)
                                }
                            }
                            Spacer()
                        }.padding([.leading, .trailing])
                        .listRowBackground(Color(UIColor.tertiarySystemBackground))
                    }
                }
            }
            .navigationBarTitle(Text("Data to be send"))
            .navigationBarItems(trailing: Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                Text("Close")
            })
        }
    }
    
    private func countryNameForCode(_ code: String) -> String {
        return Locale.current.localizedString(forRegionCode: code) ?? code
    }
}
