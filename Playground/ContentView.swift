//
//  ContentView.swift
//  playground
//
//  Created by musa.yazuju on 2023/11/06.
//

import SwiftUI

struct ContentView: View {
    let pageNames: [String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    @State private var selectedPage = "A"
    
    var body: some View {
        VStack {
            TabView(selection: $selectedPage) {
                ForEach(pageNames, id: \.self) { name in
                    ZStack {
                        Color.black
                        ScrollView {
                            ForEach(1...100, id: \.self) { index in
                                Text("Page: \(name), index:\(index)").foregroundColor(.white)
                            }
                        }
                        .toolbar(.hidden, for: .tabBar)
                    }
                    .tag(name)
                }
                .padding(.all, 10)
            }
            .frame(width: UIScreen.main.bounds.width, height: 500)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(pageNames, id: \.self) { name in
                        Button(action: {
                            withAnimation(nil) {
                                selectedPage = name
                            }
                        }, label: {
                            Text("Go to " + name)
                        })
                        .buttonStyle(BorderedButtonStyle())
                        .frame(width: 100, height: 50)
                    }
                }
            }.frame(height: 100)
        }
    }
}

#Preview {
    ContentView()
}
