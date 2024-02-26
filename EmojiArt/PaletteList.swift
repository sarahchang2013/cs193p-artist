//
//  PaletteList.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/2/26.
//

import SwiftUI

struct PaletteList: View {
    //use the injected EnvironmentObject in EmojiArtApp
    @EnvironmentObject var store: PaletteStore
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.paletteSet) { palette in
                    NavigationLink(value: palette){
                        Text(palette.name)
                    }
                }
            }
            //destination when navigate out of the List
            .navigationDestination(for:Palette.self){ palette in
                PaletteView(palette: palette)
            }
            .navigationTitle("\(store.name)")
        }
    }
}

struct PaletteView: View {
    let palette: Palette
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(palette.emojis.uniqued.map(String.init), id: \.self) { emoji in
                    NavigationLink(value: emoji) {
                        Text(emoji)
                    }
                }
            }
            .navigationDestination(for: String.self) { emoji in
                Text(emoji).font(.system(size: 300))
            }
            Spacer()
        }
        .padding()
        .font(.largeTitle)
        .navigationTitle(palette.name)
    }
}

#Preview {
    PaletteList()
}
