import Foundation


// 상품에 대한 Purchased, Reward를 모두 관리하는
// 추후 이름 바꿀 예정
//
class VLDetectManager {
    
    enum VLUserType {
        case Premium
        case Free
    }
    
    /// Singleton instance
    ///
    static public let sharedInstance = VLDetectManager()
    
    static let UserType: VLUserType = .Free
    
    let premiumDetector: VLPremiumDector = VLPremiumDector()
    let rewardDetector: VLRewardDetector = VLRewardDetector()
    
    func checkUserType() -> VLUserType {
        
        return VLProductManager.sharedInstance.isAvailableAllFeatures() ? .Premium : .Free
    }
    
    
    func canExport(project: VLProject) -> Bool {
        
        switch checkUserType() {
        case .Premium:
            return VLPremiumDector.canExport(project: project)
        case .Free:
            return rewardDetector.canExport(project: project)
        }
    }
    
    func canExport(decoData: VLDeco) -> Bool {
        switch checkUserType() {
            
        case .Premium:
            return VLPremiumDector.canExport(deco: decoData)
        case .Free:
            return rewardDetector.canExport(decoData: decoData)
        }
    }
    
    func canExport(dataInfo: VLDataInfo) -> Bool {
        switch checkUserType() {
        case .Premium:
            return VLPremiumDector.canExport(dataInfo: dataInfo)
        case .Free:
            return true
        }
    }
    
    func isUsingNonFreeContent() {
        
        switch checkUserType() {
        case .Premium:
            return
        case .Free:
            return
        }
    }
    
    
    func canUseContent(dataInfo: VLDataInfo) -> Bool {
        print("??? VLDetectManager canUserContent \(dataInfo)")
        switch checkUserType() {
            
        case .Premium:
            return true
        case .Free:
            switch dataInfo.type {
                
            case .bgm, .frame, .sticker, .label, .caption:
                return !rewardDetector.isExpiredReward(contentType: dataInfo.type)
                
            default: break
            }
        }
        
        return false
    }
}
