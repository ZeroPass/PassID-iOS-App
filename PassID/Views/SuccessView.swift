//
//  SuccessView.swift
//  PassID
//
//  Created by smlu on 21/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI

struct SuccessView: View {
    let action: Action
    let uid: UserId
    let srvMsg: String
    
    var body: some View {
        VStack {

            // Title
            Text("\(action == .register ? "Registration" : "Login") Succeeded")
                .font(.largeTitle)
                .bold()
            
            Spacer()
                .frame(height: 10)
            
            // Banner
            ZStack {
                Rectangle()
                    .foregroundColor(Color(red: 0.145, green: 0.78, blue: 0.58))//.green)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .foregroundColor(.white)
                    .aspectRatio(contentMode: .fit)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 150, maxHeight: 150)
            }
            
            Spacer()
                .frame(height: 5)
            
            //UID
            HStack {
                Text("UID:")
                    .foregroundColor(.gray)
                Spacer()
                    .frame(width: 1)
                VStack {
                    Spacer()
                        .frame(height: 1)
                    Text(uid.data.toHex())
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            Spacer()
                .frame(height: 65)
            
            // Server msg
            VStack {
                Text("Server says:")
                    .font(.title)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                    .frame(height: 10)
                Text(srvMsg)
                    .font(.title)
            }

            Spacer()
        }
    }
}

struct SuccessView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessView(action: .register, uid: UserId(data: Data.fromHex("5c83b81897ba76915d57092dc7c1586b3cab45cf")!)!, srvMsg: "Hi, Anonymous!")
    }
}
