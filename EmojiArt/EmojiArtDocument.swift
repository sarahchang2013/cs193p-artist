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
    
    // bounding box, union of all emojis' and background's bbox
    var bbox: CGRect {
        var bbox = CGRect.zero
        for emoji in emojiArt.emojis {
            bbox = bbox.union(emoji.bbox)
        }
        if let backgroundSize = background.uiImage?.size {
            bbox = bbox.union(CGRect(center: .zero, size: backgroundSize))
        }
        return bbox
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
                let image = try await fetchUIImage(from: url)
                // If while fetching, user dropped another fast url,
                // it finished updating background first.
                // slow url's function stack still holds old url,
                // but background url is changed on heap,
                // when the slow url returns an image,
                // make sure the latter returned image doesn't update UI
                if url == emojiArt.background {
                    background = .found(image)
                }
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
    
    var bbox: CGRect {
        CGRect(
            // absolute position, no need of a view's geometry
            center: position.in(nil),
            size: CGSize(width: CGFloat(size), height: CGFloat(size))
        )
    }
}

extension EmojiArt.Emoji.Position {
    func `in`(_ geometry: GeometryProxy?) -> CGPoint {
        // no geometry needed when getting bbox of an emoji
        // .zero is the (0,0) of default coordinate system
        let center = geometry?.frame(in: .local).center ?? .zero
        return CGPoint(x: center.x + CGFloat(x), y: center.y - CGFloat(y))
        
    }
}
