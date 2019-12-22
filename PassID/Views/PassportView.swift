//
//  PassportReaderView.swift
//  PassID
//
//  Created by smlu on 16/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct PassportView: View {
    
    private var dismissCallback: (() -> Void)? = nil
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        HStack {
            Text("Hello, passport screen!")
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
}

struct PassportReaderView_Previews: PreviewProvider {
    static var previews: some View {
        PassportView()
            .environment(\.colorScheme, .dark)
    }
}
