//
//  ContentView.swift
//  List Filter
//
//  Created by Jason Barrie Morley on 11/12/2020.
//

import SwiftUI

struct ContentView: View {

    @State var counter: Int = 0
    @StateObject var provider = ItemProvider()

    var body: some View {
        ListView(provider: provider)
    }
}
