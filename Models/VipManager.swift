import Foundation
import Combine
 
final class VipManager: ObservableObject {
    static let shared = VipManager()
    
    private let isVipKey = "ZhengHuoJu_IsVip"
    private let vipExpiryKey = "ZhengHuoJu_VipExpiry"
    private let vipPlanKey = "ZhengHuoJu_VipPlan"
    
    @Published var isVip: Bool {
        didSet { UserDefaults.standard.set(isVip, forKey: isVipKey) }
    }
    
    @Published var planName: String {
        didSet { UserDefaults.standard.set(planName, forKey: vipPlanKey) }
    }
    
    @Published var expiryDate: Date? {
        didSet {
            if let date = expiryDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: vipExpiryKey)
            } else {
                UserDefaults.standard.removeObject(forKey: vipExpiryKey)
            }
        }
    }
    
    private init() {
        self.isVip = UserDefaults.standard.bool(forKey: isVipKey)
        self.planName = UserDefaults.standard.string(forKey: vipPlanKey) ?? ""
        let ts = UserDefaults.standard.double(forKey: vipExpiryKey)
        self.expiryDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }
    
    func activate(plan: String, expiry: Date?) {
        planName = plan
        expiryDate = expiry
        isVip = true
    }
    
    func deactivate() {
        isVip = false
        planName = ""
        expiryDate = nil
    }
    
    func toggleForDebug() {
        if isVip {
            deactivate()
        } else {
            activate(plan: "调试 VIP", expiry: nil)
        }
    }
    
    var expiryDisplay: String {
        if let date = expiryDate {
            let f = DateFormatter()
            f.dateFormat = "yyyy.MM.dd 到期"
            return f.string(from: date)
        }
        return "永久会员"
    }
}

WorksStore.swift
