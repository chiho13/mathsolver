import Foundation
import SwiftData
import SwiftUI

@Model
class SearchHistoryItem {
    let id: UUID
    let query: String
    let result: String
    let timestamp: Date
    
    init(query: String, result: String) {
        self.id = UUID()
        self.query = query
        self.result = result
        self.timestamp = Date()
    }
}

class SearchHistoryManager: ObservableObject {
    @Published private(set) var items: [SearchHistoryItem] = []
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshItems()
    }
    
    private func refreshItems() {
        let descriptor = FetchDescriptor<SearchHistoryItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        items = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addItem(query: String, result: String) {
        // Don't add duplicate queries
        let descriptor = FetchDescriptor<SearchHistoryItem>(
            predicate: #Predicate<SearchHistoryItem> { item in
                item.query == query
            }
        )
        
        if let existingItems = try? modelContext.fetch(descriptor), existingItems.isEmpty {
            let newItem = SearchHistoryItem(query: query, result: result)
            modelContext.insert(newItem)
            try? modelContext.save()
            refreshItems()
        }
    }
    
    func deleteItem(_ item: SearchHistoryItem) {
        modelContext.delete(item)
        try? modelContext.save()
        refreshItems()
    }
    
    func clearAll() {
        let descriptor = FetchDescriptor<SearchHistoryItem>()
        if let items = try? modelContext.fetch(descriptor) {
            items.forEach { modelContext.delete($0) }
            try? modelContext.save()
            refreshItems()
        }
    }
} 