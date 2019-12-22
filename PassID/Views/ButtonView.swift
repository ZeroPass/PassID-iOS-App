//
//  ButtonView.swift
//  PassID
//
//  Created by smlu on 22/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct ButtonView: View {
    let text: String
    let background: Color
    let foreground: Color
    
    init(text: String, background: Color = Color(UIColor.darkGray), foreground: Color = .white){
        self.text = text
        self.background = background
        self.foreground = foreground
    }
    
    var body: some View {
        Text(self.text)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
            .background(self.background)
            .foregroundColor(self.foreground)
    }
}


struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(text: "Test")
    }
}
