import Foundation
import CloudKit
import Combine

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var iCloudStatus: String = "正在检查..."
    
    private let container: CKContainer
    private let privateDB: CKDatabase
    
    private init() {
        // Container identifier must match the one in entitlements
        container = CKContainer(identifier: "iCloud.com.zhenghuoju.app")
        privateDB = container.privateCloudDatabase
        
        // Restore last sync time
        lastSyncTime = UserDefaults.standard.object(forKey: "lastCloudSyncTime") as? Date
    }
    
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.iCloudStatus = "状态获取失败: \(error.localizedDescription)"
                    return
                }
                
                switch status {
                case .available:
                    self?.iCloudStatus = "iCloud 已开启"
                case .noAccount:
                    self?.iCloudStatus = "iCloud 未登录"
                case .restricted:
                    self?.iCloudStatus = "iCloud 受限"
                case .couldNotDetermine:
                    self?.iCloudStatus = "iCloud 状态未知"
                case .temporarilyUnavailable:
                    self?.iCloudStatus = "iCloud 暂时不可用"
                @unknown default:
                    self?.iCloudStatus = "iCloud 未知错误"
                }
            }
        }
    }
    
    func syncNow() {
        guard iCloudStatus == "iCloud 已开启" else { return }
        
        DispatchQueue.main.async {
            self.isSyncing = true
            self.iCloudStatus = "正在同步..."
        }
        
        // Mock sync process: In a real app this would query CKRecords and merge with local CoreData/UserDefaults
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.iCloudStatus = "iCloud 已开启"
                self.lastSyncTime = Date()
                UserDefaults.standard.set(self.lastSyncTime, forKey: "lastCloudSyncTime")
            }
        }
    }
}
