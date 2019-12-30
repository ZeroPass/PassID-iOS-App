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
    var background: Color
    var foreground: Color
    
    init(text: String){
        self.text = text
        self.background = Color(UIColor.tertiarySystemBackground)
        self.foreground = .primary
    }
    
    var body: some View {
        Text(self.text)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
            .border(Color(UIColor.separator), width: 0.65)
            .background(self.background)
            .foregroundColor(self.foreground)
    }
    
    func foregroundColor(_ color: Color) -> ButtonView {
        var copy = self
        copy.foreground = color
        return copy
    }
    
    func background(_ color: Color) -> ButtonView {
        var copy = self
        copy.background = color
        return copy
    }
}


struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(text: "Test")
    }
}
