//
//  ContentView.swift
//  testIos
//
//  Created by Peter Karoly Szokol on 2024. 10. 13..
//

import SwiftUI

class Model: ObservableObject {
    func something() async {
        print("hi1")
    }
    
    init() {
        Task { @MainActor in
            await something()
            somethingElse()
        }
    }
    
    func somethingElse() {
        print("hi2")
    }
}

struct ContentView: View {
    @ObservedObject var model: Model
    
    //var body: some View {
        //Text("Hello, world!")
      //      .padding()
    //}
    
    @State private var isShowingImagePicker = false
    
    var body: some View {
        VStack {
            Button("Pick Image") {
                isShowingImagePicker = true
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePickerView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: Model())
    }
}
