//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import Foundation

struct EmojiArt: Codable {
    var background: URL?
    private(set) var emojis = [Emoji]()
    private var uniqueEmojiId = 0
    
    struct Emoji: Identifiable, Codable {
        let string: String
        var position: Position
        var size: Int
        var id: Int
        
        // coordinates relative to the center of its parent
        struct Position: Codable {
            var x: Int
            var y: Int
            
            static let zero = Self(x: 0, y: 0)
        }
    }
    
    mutating func addEmoji(_ emoji: String, at position: Emoji.Position, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(
            string: emoji,
            position: position,
            size: size,
            id: uniqueEmojiId)
        )
    }
    
    func json() throws-> Data{
        let encoded = try JSONEncoder().encode(self)
        print("Encoded JSON: \(String(data:encoded, encoding:.utf8) ?? "")")
        return encoded
    }
}
