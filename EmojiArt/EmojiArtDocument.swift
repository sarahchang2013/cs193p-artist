//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "cs193p.emojiart")
}

class EmojiArtDocument: ReferenceFileDocument {
    // SwiftUI begins by calling the ``snapshot(contentType:)`` method to get
    ///a copy of the document data in its current state.
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        //SwiftUI passes that snapshot to this method
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    //error "fix" generates this, set it to Data, "fix" again to get other functions for Data
    typealias Snapshot = Data
    
    static var readableContentTypes: [UTType] {
        [.emojiart]
    }
    
    // initialize EmojiArtDocument from .emojiart file
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArt(json: data)
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    typealias Emoji = EmojiArt.Emoji
    @Published private var emojiArt = EmojiArt() {
        didSet{
            //if user changes background url, run state machine
            if emojiArt.background != oldValue.background {
                // fork it off because didSet cannot be async function
                Task {
                    await fetchBackgroundImage()
                }
            }
        }
    }
    
    // required by DocumentGroup's parameter
    init() {
        
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
    // file isn't correctly saved without undo function
    private func undoablyPerform(_ action: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.registerUndo(withTarget: self) { myself in
            // 1. closure captures local variable oldEmojiArt,
            // and keeps it in heap to wait for undo operation
            // 2. redoing is just undoing undo
            myself.undoablyPerform(action, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(action)
    }
    
    func setBackground(_ url: URL?, undoWith undoManager: UndoManager? = nil) {
        undoablyPerform("Set Background", with: undoManager) {
            emojiArt.background = url
        }
    }
    
    func addEmoji(_ emoji: String, at position: Emoji.Position, size: CGFloat, undoWith undoManager: UndoManager? = nil) {
        undoablyPerform("Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(emoji, at: position, size: Int(size))
        }
    }
}

extension EmojiArt.Emoji {
    var font: Font {
        Font.system(size: CGFloat(size))
    }
    
    var bbox: CGRect {
        CGRect(
            // here center is .zero of IOS coordinate system
            // final bbox is relative to .zero,
            // only need its center's vector for zoomToFit's rect.midX/Y
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
        // convert Position to values in IOS coordinate system
        return CGPoint(x: center.x + CGFloat(x), y: center.y - CGFloat(y))
        
    }
}
