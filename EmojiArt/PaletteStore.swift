//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/2/5.
//
import SwiftUI

class PaletteStore: ObservableObject {
    let name: String
    
    @Published var paletteSet: [Palette] {
        didSet {
            //check oldValue to avoid infinite loop
            if paletteSet.isEmpty, !oldValue.isEmpty {
                paletteSet = oldValue
            }
        }
    }
    
    init(named name: String) {
        self.name = name
        paletteSet = Palette.builtins
        // in case builtin gives empty palette
        if paletteSet.isEmpty {
            paletteSet = [Palette(name: "Warning", emojis: "⚠️")]
        }
    }
    
    @Published private var _cursorIndex = 0
    
    var cursorIndex: Int {
        get { boundsCheckedPaletteIndex(_cursorIndex) }
        set { _cursorIndex = boundsCheckedPaletteIndex(newValue) }
    }
    
    private func boundsCheckedPaletteIndex(_ index: Int) -> Int {
        var index = index % paletteSet.count
        if index < 0 {
            index += paletteSet.count
        }
        return index
    }
    
    // MARK: - Adding Palettes
    
    // these functions are the recommended way to add Palettes to the PaletteStore
    // since they try to avoid duplication of Identifiable-ly identical Palettes
    // by first removing/replacing any Palette with the same id that is already in paletteSet
    // it does not "remedy" existing duplication, it just does not "cause" new duplication
    
    func insert(_ palette: Palette, at insertionIndex: Int? = nil) { // "at" default is cursorIndex
        let insertionIndex = boundsCheckedPaletteIndex(insertionIndex ?? cursorIndex)
        if let index = paletteSet.firstIndex(where: { $0.id == palette.id }) {
            paletteSet.move(fromOffsets: IndexSet([index]), toOffset: insertionIndex)
            paletteSet.replaceSubrange(insertionIndex...insertionIndex, with: [palette])
        } else {
            paletteSet.insert(palette, at: insertionIndex)
        }
    }
    
    func insert(name: String, emojis: String, at index: Int? = nil) {
        insert(Palette(name: name, emojis: emojis), at: index)
    }
    
    func append(_ palette: Palette) { // at end of paletteSet
        if let index = paletteSet.firstIndex(where: { $0.id == palette.id }) {
            if paletteSet.count == 1 {
                paletteSet = [palette]
            } else {
                paletteSet.remove(at: index)
                paletteSet.append(palette)
            }
        } else {
            paletteSet.append(palette)
        }
    }
    
    func append(name: String, emojis: String) {
        append(Palette(name: name, emojis: emojis))
    }
}
