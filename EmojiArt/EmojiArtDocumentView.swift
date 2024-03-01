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
            PaletteChooser()
                .font(.system(size: paletteSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                if document.background.isFetching {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.blue)
                }
                documentContents(in: geometry)
                    .scaleEffect(zoom * zoomState)
                    .offset(pan + panState)
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .dropDestination(for: Sturldata.self) {sturldatas, location in
                return drop(sturldatas, at: location, in:geometry)
            }
        }
    }
    
    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    @GestureState private var zoomState: CGFloat = 1
    @GestureState private var panState: CGOffset = .zero
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($zoomState) { inMotionPinchScale, zoomState, _ in
                zoomState = inMotionPinchScale
            }
            .onEnded{ endPinchScale in
                zoom *= endPinchScale
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($panState) { inMotionPan, panState, _ in
                panState = inMotionPan.translation
            }
            .onEnded { endPosition in
                pan += endPosition.translation
            }
    }
    
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        // sets background image when uiImage is not nil
        if let uiImage = document.background.uiImage {
            Image(uiImage: uiImage)
                .position(EmojiArt.Emoji.Position.zero.in(geometry))
        }
        ForEach(document.emojis) { emoji in
            Text(emoji.string)
                .font(emoji.font)
                .position(emoji.position.in(geometry))
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
                        size: paletteSize/zoom)
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
        //print("center x: \(center.x) center y: \(center.y)")
        //de-pan/zoom the emoji, otherwise it pans/zooms with the documentContents
        return EmojiArt.Emoji.Position(x: Int((point.x - center.x - pan.width)/zoom), y: Int(-(point.y - center.y - pan.height)/zoom))
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
}
