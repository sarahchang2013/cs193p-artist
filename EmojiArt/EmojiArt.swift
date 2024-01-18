//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import Foundation

struct EmojiArt {
    var background: URL?
    var emojis = [Emoji]()
    
    struct Emoji {
        let string: String
        var position: Position
        var size: Int
        
        struct Position{
            var x: Int
            var y: Int
        }
    }
}
