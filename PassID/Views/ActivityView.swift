//
//  ActivityView.swift
//  PassID
//
//  Created by smlu on 05/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


struct ActivityIndicator: View {
    
    @State private var degrees = 0.0
    @State private var timer: Timer?

    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.6)
            .stroke(Color.blue, lineWidth: 5.0)
            .frame(width: 60, height: 60)
            .rotationEffect(Angle(degrees: degrees))
            .onAppear(perform: { self.start() })
            .onDisappear(perform: { self.stop() })
    }
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            withAnimation {
                self.degrees += 10.0
            }
            if self.degrees == 360.0 {
                self.degrees = 0.0
            }
        }
    }

    private func stop() {
        self.timer?.invalidate()
    }
}

struct ActivityIndicator2: View {

    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader { (geometry: GeometryProxy) in
            ForEach(0..<5) { index in
                Circle()
                    .frame(width: geometry.size.width / 5, height: geometry.size.height / 5)
                    .scaleEffect(!self.isAnimating ? 1 - CGFloat(index) / 5 : 0.2 + CGFloat(index) / 5)
                    .offset(y: geometry.size.width / 10 - geometry.size.height / 2)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .rotationEffect(!self.isAnimating ? .degrees(0) : .degrees(360))
                    .animation(Animation
                    .timingCurve(0.5, 0.15 + Double(index) / 5, 0.25, 1, duration: 1.5)
                    .repeatForever(autoreverses: false))
            }
        }
        .frame(width: 60, height: 60)
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
          self.isAnimating = true
        }
    }
}


struct ActivityView<Content>: View where Content: View {

    var msg: String
    @Binding var showActivity: Bool
    var content: () -> Content
    
    public init(msg: String = "Please wait ...", showActivity: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.msg = msg
        self.content = content
        self._showActivity = showActivity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
               
                self.content()
                    .disabled(self.showActivity)
                    .blur(radius: self.showActivity ? 3 : 0)
                    .navigationBarHidden(self.showActivity)
                    .navigationBarBackButtonHidden(self.showActivity)
                
                if self.showActivity {
                   VStack {
                        ActivityIndicator2()
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
        // Note: Doesn't work for multi finger drag gesture.
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
