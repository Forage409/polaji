import Foundation
import CloudKit
import Combine

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var iCloudStatus: String = "正在检查..."
    
    private var container: CKContainer? {
        // In unsigned builds or simulator without capabilities, this can throw an NSException.
        // We initialize it lazily to prevent crashing on app launch.
        // Uncomment the actual identifier when entitlements are properly set up.
        // return CKContainer(identifier: "iCloud.com.zhenghuoju.app")
        return nil // Disabled by default for unsigned builds to prevent crashes.
    }
    
    private var privateDB: CKDatabase? {
        return container?.privateCloudDatabase
    }
    
    private init() {
        // Restore last sync time
        lastSyncTime = UserDefaults.standard.object(forKey: "lastCloudSyncTime") as? Date
    }
    
    func checkAccountStatus() {
        guard let container = container else {
            DispatchQueue.main.async {
                self.iCloudStatus = "iCloud 未配置 (需要签名)"
            }
            return
        }
        
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
        
        // Currently iCloud sync is disabled, we rely on the backend API.
        DispatchQueue.main.async {
            self.isSyncing = false
            self.iCloudStatus = "iCloud 已开启"
            self.lastSyncTime = Date()
            UserDefaults.standard.set(self.lastSyncTime, forKey: "lastCloudSyncTime")
        }
    }
}
