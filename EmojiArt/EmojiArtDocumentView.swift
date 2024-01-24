//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    private let emojis = "🐒🐣🐥🪿🦆🐦‍⬛🦅🦉🐝🦋🐌🐞🐜🐅🦓🐆🐘🐫🦒🦘🌳🌲🌹🌸🌼🌴🌻🌷🐑🐕🌥️☀️🌈"
    
    private let paletteSize : CGFloat = 80
    
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            ScrollingEmojis(emojis)
                .font(.system(size: paletteSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                AsyncImage(url: document.background)
                    .position(EmojiArt.Emoji.Position.zero.in(geometry))
                ForEach(document.emojis) { emoji in
                    Text(emoji.string)
                        .font(emoji.font)
                        .position(emoji.position.in(geometry))
                }
            }
            .dropDestination(for: Sturldata.self) {sturldatas, location in
                return drop(sturldatas, at: location, in:geometry)
            }
        }
    }
    
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata{
                case .url(let url):
                    document.setBackground(url)
                    return true
                case .string(let emoji):
                    document.addEmoji(
                        emoji,
                        at: dropPosition(location, in: geometry),
                        size: paletteSize)
                    return true
                default:
                    break
            }
        }
        return false
    }
    
    // convert the location of drop to the position relative to center
    private func dropPosition(_ point: CGPoint, in geometry: GeometryProxy) -> EmojiArt.Emoji.Position {
        let center = geometry.frame(in: .local).center
        return EmojiArt.Emoji.Position(x: Int(point.x - center.x), y: Int(center.y - point.y))
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
    EmojiArtDocumentView(document: EmojiArtDocument())
}
