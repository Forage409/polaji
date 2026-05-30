import Foundation

class WorksStore: ObservableObject {
    @Published var works: [Work] = []
    
    private let worksKey = "ZhengHuoJu_Works_Metadata"
    
    init() {
        loadWorks()
    }
    
    func refresh() {
        loadWorks()
    }
    
    func saveWork(_ work: Work) {
        works.insert(work, at: 0)
        persistWorks()
    }
    
    func deleteWork(id: String) {
        works.removeAll { $0.id == id }
        persistWorks()
    }
    
    private func loadWorks() {
        if let data = UserDefaults.standard.data(forKey: worksKey) {
            if let decoded = try? JSONDecoder().decode([Work].self, from: data) {
                works = decoded
            }
        }
    }
    
    private func persistWorks() {
        if let encoded = try? JSONEncoder().encode(works) {
            UserDefaults.standard.set(encoded, forKey: worksKey)
        }
    }
}
