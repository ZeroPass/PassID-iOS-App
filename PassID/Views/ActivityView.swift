//
//  ActivityView.swift
//  PassID
//
//  Created by smlu on 05/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct ActivityIndicator: View {
    
    @State private var degress = 0.0
    @State private var timer: Timer?

    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.6)
            .stroke(Color.blue, lineWidth: 5.0)
            .frame(width: 60, height: 60)
            .rotationEffect(Angle(degrees: degress))
            .onAppear(perform: { self.start() })
            .onDisappear(perform: { self.stop() })
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            withAnimation {
                self.degress += 10.0
            }
            if self.degress == 360.0 {
                self.degress = 0.0
            }
        }
    }

    private func stop() {
        self.timer?.invalidate()
    }
}


struct ActivityView<Content>: View where Content: View {

    var msg: String = "Please wait ..."
    @Binding var showActivity: Bool
    
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
               
               self.content()
                   .disabled(self.showActivity)
                   .blur(radius: self.showActivity ? 3 : 0)

               if self.showActivity {
                   VStack {
                       ActivityIndicator()
                       Text(self.msg)
                           .padding(.horizontal, 20)
                   }
                   .frame(minWidth: geometry.size.width / 2, maxHeight: geometry.size.height / 5)
                   .background(Color.secondary.colorInvert())
                   .foregroundColor(Color.primary)
                   .cornerRadius(20)
               }
            }
        }
        // Disable drag gesture (on sheets) when activity is visible
        // Note: Doesn't work on multi finger drag gesture.
        .highPriorityGesture(DragGesture(), including: .all)
    }
}


struct ActivityView_Previews: PreviewProvider {
    @State static var show = true
    static var previews: some View {
        Group {
            ActivityView(showActivity: $show) {
                Text("Test")
            }.environment(\.colorScheme, .dark)
        }
    }
}