//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/2/5.
//

import SwiftUI

struct PaletteChooser: View {
    @EnvironmentObject var store: PaletteStore
    @State private var showPaletteEditor = false
    
    var body: some View {
        HStack {
            chooser
            view(for: store.paletteSet[store.cursorIndex])
        }
        //otherwise replaced palette still hovers
        .clipped()
        .sheet(isPresented: $showPaletteEditor){
            PaletteEditor(palette: $store.paletteSet[store.cursorIndex])
                .font(nil)
        }
    }
    
    private var chooser: some View {
        AnimatedActionButton(systemImage:"paintpalette"){
            //pressing the palette icon causes the cursor to increase, with animation that changes palette view
                store.cursorIndex += 1
        }
        .contextMenu{
            // long-pressing the palette icon brings up the menu
            gotoMenu
            AnimatedActionButton("New",systemImage: "plus"){
                store.insert(name:"", emojis:"")
                showPaletteEditor = true
            }
            AnimatedActionButton("Delete",systemImage: "minus.circle",role:.destructive){
                store.paletteSet.remove(at: store.cursorIndex)
            }
            AnimatedActionButton("Edit",systemImage: "pencil"){
                showPaletteEditor = true
            }
        }
    }
    
    private var gotoMenu: some View {
        Menu {
            ForEach(store.paletteSet) { palette in
                AnimatedActionButton(palette.name){
                    //find the chosen palette in paletteSet
                    if let index = store.paletteSet.firstIndex(where:{$0.id == palette.id}){
                        // set shown palette to the chosen one
                        store.cursorIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
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
