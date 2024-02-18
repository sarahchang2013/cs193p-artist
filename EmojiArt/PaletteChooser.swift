//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/2/5.
//

import SwiftUI

struct PaletteChooser: View {
    @EnvironmentObject var store: PaletteStore
    
    var body: some View {
        HStack {
            chooser
            view(for: store.paletteSet[store.cursorIndex])
        }
        //otherwise replaced palette still hovers
        .clipped()
    }
    
    private var chooser: some View {
        AnimatedActionButton(systemImage:"paintpalette"){
            //pressing the palette icon causes the cursor to increase, with animation that changes palette view
                store.cursorIndex += 1
        }
        .contextMenu{
            AnimatedActionButton("New",systemImage: "plus"){
                store.insert(name:"Road Signs", emojis:"⚠️🚸🚷")
            }
            AnimatedActionButton("Delete",systemImage: "minus.circle",role:.destructive){
                store.paletteSet.remove(at: store.cursorIndex)
            }
        }
    }
    
    private func view(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojis(palette.emojis)
        }
        //change id to replace the palette view
        .id(palette.id)
        //rolling effect
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
    }
}

struct ScrollingEmojis: View {
    let emojis: [String]
    
    init(_ emojis: String) {
        self.emojis = emojis.uniqued.map{ String($0)}
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .draggable(emoji)
                }
            }
        }
    }
}

#Preview {
        PaletteChooser()
            .environmentObject(PaletteStore(named: "Preview"))
}
