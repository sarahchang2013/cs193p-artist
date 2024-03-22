//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        // This creates new document(view model) for each window(view)
        DocumentGroup (newDocument: {EmojiArtDocument()}) { config in
            EmojiArtDocumentView(document: config.document)
        }
    }
}
