
+2
import Foundation
 
class WorksStore: ObservableObject {
    static let shared = WorksStore()
    
    @Published var works: [Work] = []
    
    private let worksKey = "ZhengHuoJu_Works_Metadata"

CacheManager.swift
