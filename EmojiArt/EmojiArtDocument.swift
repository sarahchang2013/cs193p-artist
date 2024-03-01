//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    typealias Emoji = EmojiArt.Emoji
    @Published private var emojiArt = EmojiArt() {
        didSet{
            autosave()
            //if user changes background url, run state machine
            if emojiArt.background != oldValue.background {
                // fork it off because didSet cannot be async function
                Task {
                    await fetchBackgroundImage()
                }
            }
        }
    }
    
    private let autosaveURL : URL = URL.documentsDirectory.appendingPathComponent("Autosaved.emojiart")
    
    private func autosave() {
        save(to: autosaveURL)
        //print("Autosaved to \(autosaveURL)")
    }
    
    private func save(to url: URL) {
        do {
            let data = try emojiArt.json()
            try data.write(to: url)
        } catch let error {
            print("EmojiArtDocument: error when saving \(error.localizedDescription)")
        }
        
    }
    
    init() {
        // if either trial fails, use default emojiArt
        if let jsonData = try? Data(contentsOf: autosaveURL),
           let autosaved = try? EmojiArt(json: jsonData) {
            emojiArt = autosaved
        }
    }
    
    
    var emojis: [Emoji] {
        emojiArt.emojis
    }
    
//    var background: URL? {
//        emojiArt.background
//    }
    
    // have UI to watch the states of background.
    @Published var background: Background = .none
    
    // MARK: - Background Image
    //use an enum as a state machine to switch between different states of UI background
    @MainActor
    // any UI updates need to be in MainActor thread to remove deadly purple runtime error
    private func fetchBackgroundImage() async {
        if let url = emojiArt.background {
            background = .fetching(url)
            do {
                background = try await .found(fetchUIImage(from: url))
            } catch {
                // or failed
                background = .failed("Couldn't set background: \(error.localizedDescription)")
            }
        } else {
            background = .none
        }
    }
    
    // async function to unblock UI thread
    private func fetchUIImage(from url: URL) async throws-> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        // UIImage returns nil if found no jpeg
        if let uiImage =  UIImage(data: data) {
            return uiImage
        } else {
            throw FetchError.badImageData
        }
    }
    
    enum FetchError: Error {
        case badImageData
    }
    
    enum Background {
        case none
        //(X) is enum associated value, indicates case xx can only be X type.
        case fetching(URL)
        case found(UIImage)
        case failed(String)
        
        var uiImage: UIImage? {
            switch self {
            case .found(let uiImage): return uiImage
            default: return nil
            }
        }
        
        var urlBeingFetched: URL? {
            switch self {
            case .fetching(let url): return url
            default: return nil
            }
        }
        
        var isFetching: Bool { urlBeingFetched != nil }
        
        var failureReason: String? {
            switch self {
            case .failed(let reason): return reason
            default: return nil
            }
        }
    }
    
    //MARK: - Intent(s)
    
    func setBackground(_ url: URL?) {
        emojiArt.background = url
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: CGFloat){
        emojiArt.addEmoji(emoji, at: position, size: Int(size))
    }
}

extension EmojiArt.Emoji {
    var font: Font {
        Font.system(size: CGFloat(size))
    }
}

extension EmojiArt.Emoji.Position {
    func `in`(_ geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(x: center.x + CGFloat(x), y: center.y - CGFloat(y))
        
    }
}
