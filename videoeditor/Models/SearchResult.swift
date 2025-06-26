import Foundation

struct SearchResult: Identifiable, Decodable {
    let id: UUID
    let title: String
    let subtitle: String?
    let url: URL?
} 