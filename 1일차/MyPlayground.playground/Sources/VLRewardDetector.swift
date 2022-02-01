import UIKit

class VLRewardDetector: NSObject {
    
    static public let Key_Register_Reward_Time          = "reward_manager_reward_time"          // 보상형 광고 시청하고 기록한 시간
    static private let ExpiredTime = 10 // 8*60           // 보상형 광고 시간 8시간 유효 (분)
    
    enum VLRewardType: String, Codable {
        case RewardBGM
        case RewardMotionSticker
        case RewardFrame
        case RewardLabel
        case RewardCaption
    }
    
    /// UserDefulat에 저장될 구조체
    ///
    struct VLRewardContent: Codable {
        var RewardBGM: Date?
        var RewardMotionSticker: Date?
        var RewardFrame: Date?
        var RewardLabel: Date?
        var RewardCaption: Date?
    }
    
    /// canExport -> isUsing 하는지 검사할 때 사용한다면 어떤 데코를 사용하는지 반환해야 한다.
    ///
    class VLRewardSet {
        
        let decoData: VLDeco
        let rewardType: VLRewardType
        
        init(decoData: VLDeco, rewardType: VLRewardType) {
            self.decoData = decoData
            self.rewardType = rewardType
        }
    }
    
    /// Singleton instance
    ///
    static public let sharedInstance = VLRewardDetector()
    
//    /// 기능 사용 할 때, 보상형 광고 봤는지 check
//    /// - Returns: Bool
//    ///
//    public func canUseRewardContent(product: VLRewardType) -> Bool {
//
//        // Premium User Can Use All Content
//        //
//        if VLDetectManager.sharedInstance.checkUserType() == .Premium {
//            return true
//        }
//
//        switch product {
//        case .RewardBGM:
//            return !isExpiredReward(dataInfo: )
//        case .RewardMotionSticker:
//            return !isExpiredReward(dataInfo: .RewardMotionSticker)
//        case .RewardFrame:
//            return !isExpiredReward(dataInfo: .RewardFrame)
//        case .RewardLabel:
//            return !isExpiredReward(dataInfo: .RewardLabel)
//        case .RewardCaption:
//            return !isExpiredReward(dataInfo: .RewardCaption)
//        }
//
//    }
    
    /// 보상형 광고 봤다면, 시간 지났는지 check
    /// - Returns: Bool
    ///
    public func isExpiredReward(contentType: VLDataInfo.ContentType) -> Bool {
        print("??? VLRewardManager isExpiredReward \(contentType)")

        // 한번도 시간 저장 안된 사람 - 처음 업데이트
        // 전부 nil로 설정
        if UserDefaults.standard.object(forKey: Self.Key_Register_Reward_Time) == nil {
            print("??? 한번도 설정 안한 사람 ==> 전부 nil로 reward 설정")

            // Key not exists
            //
            let time = VLRewardContent(RewardBGM: nil, RewardMotionSticker: nil, RewardFrame: nil, RewardLabel: nil, RewardCaption: nil)
            let encoder = JSONEncoder()
            let data = try! encoder.encode(time)
            
            UserDefaults.standard.set(String(data: data, encoding: .utf8), forKey: Self.Key_Register_Reward_Time)
        }
        
        // Key 있는 사람들
        
        let time = UserDefaults.standard.string(forKey: Self.Key_Register_Reward_Time) ?? ""
        let decoder = JSONDecoder()
        let data = try! decoder.decode(VLRewardContent.self, from: time.data(using: .utf8)!) as VLRewardContent
        print("??? reward 가져온다. \(data)")
        let current = Date()
        var isExpired: Bool = true

        switch contentType {
        case .bgm:
            guard let rewardBGM = data.RewardBGM else { break }
            
            let distanceMinute: Int = Calendar.current.dateComponents([.minute], from: rewardBGM, to: current).minute!
            print("??? rewardBGM time \(distanceMinute)")

            isExpired = distanceMinute > Self.ExpiredTime ? true : false
            
        case .sticker:
            guard let rewardMotionStickeer = data.RewardMotionSticker else { break }
            
            let distanceMinute: Int = Calendar.current.dateComponents([.minute], from: rewardMotionStickeer, to: current).minute!
            print("??? rewardMotionStickeer time \(distanceMinute)")

            isExpired = distanceMinute > Self.ExpiredTime ? true : false

        case .frame:
            
            guard let rewardFrame = data.RewardFrame else { break }
            
            let distanceMinute: Int = Calendar.current.dateComponents([.minute], from: rewardFrame, to: current).minute!
            print("??? rewardFrame time \(distanceMinute)")

            isExpired = distanceMinute > Self.ExpiredTime ? true : false

        case .label:
            
            guard let rewardLabel = data.RewardLabel else { break }
            
            let distanceMinute: Int = Calendar.current.dateComponents([.minute], from: rewardLabel, to: current).minute!
            print("??? rewardLabel time \(distanceMinute)")

            isExpired = distanceMinute > Self.ExpiredTime ? true : false

        case .caption:
            
            guard let rewardCaption = data.RewardCaption else { break }
            
            let distanceMinute: Int = Calendar.current.dateComponents([.minute], from: rewardCaption, to: current).minute!
            print("??? rewardCaption time \(distanceMinute)")

            isExpired = distanceMinute > Self.ExpiredTime ? true : false

        default: break
        }

        print("??? isExpired? \(isExpired)")
        
        return isExpired
    }
    
    /// 보상형 광고 안본 User 대상, 광고 다 봤으면 다 본 시간 기록
    ///
    public func setExpiredTime(product: VLRewardType) {
        print("??? setExpiredTime \(product)")

        let time = UserDefaults.standard.string(forKey: Self.Key_Register_Reward_Time) ?? ""
        let decoder = JSONDecoder()
        var data = try! decoder.decode(VLRewardContent.self, from: time.data(using: .utf8)!) as VLRewardContent

        switch product {
            
        case .RewardBGM:
            data.RewardBGM = Date()
            
        case .RewardMotionSticker:
            data.RewardMotionSticker = Date()

        case .RewardFrame:
            data.RewardFrame = Date()

        case .RewardLabel:
            data.RewardLabel = Date()

        case .RewardCaption:
            data.RewardCaption = Date()

        }
        
        // Register
        //
        let encoder = JSONEncoder()
        UserDefaults.standard.set(String(data: try! encoder.encode(data), encoding: .utf8)!, forKey: Self.Key_Register_Reward_Time)
        UserDefaults.standard.synchronize()

    }
    
    /// 프로젝트 추출시, 보상형 광고 콘텐츠 있는지 확인
    /// - Returns: Bool
    ///
    public func canExport(project: VLProject) -> Bool {
        return !isUSingRewardContent(project: project, withList: false).using
    }
    
    public func canExport(decoData: VLDeco) -> Bool {
        return !isUsingRewardContent(decoData: decoData).using
    }
    
    /// 해당 데코가 보상형 콘텐츠인지, 시간 만료 되었는지 확인
    ///
    public func isUSingRewardContent(project: VLProject, withList: Bool = false) -> (using: Bool, rewardSet: [VLRewardSet]) {
        
        var rewardSetList: [VLRewardSet] = []
        
        for decoData in project.getAllDecosInLayers() {
            let result = isUsingRewardContent(decoData: decoData, withList: withList)
            if result.using {
                if withList {
                    for rewardType in result.rewardTypeList {
                        rewardSetList.append(VLRewardSet(decoData: decoData, rewardType: rewardType))
                    }
                } else {
                    return (true, rewardSetList)
                }
            }
        }
        return (rewardSetList.count > 0, rewardSetList)
    }
    
    
    public func isUsingRewardContent(decoData: VLDeco, withList: Bool = false) -> (using: Bool, rewardTypeList: [VLRewardType]){
        
        var rewardTypeList: [VLRewardType] = []
        
        // Check Reward Features
        //
        if decoData.supportType == .reward {
            
            // 1. BGM
            //
            if decoData is VLSoundDeco && isExpiredReward(contentType: .bgm) { //, BGM 시간 지났는지 체크
                if withList {
                    rewardTypeList.append(.RewardBGM)
                } else {
                    return (true, rewardTypeList)
                }
                
                // 2. Caption
                //
            } else if decoData is VLCaptionDeco
            // , Caption 부분만 시간 Check
            {
                if withList {
                    rewardTypeList.append(.RewardCaption)
                } else {
                    return (true, rewardTypeList)
                }
                
                // 3. Label
                //
            } else if decoData is VLLabelDeco
            {
                if withList {
                    rewardTypeList.append(.RewardLabel)
                } else {
                    return (true, rewardTypeList)
                }
            }
            
                // 4. Frame
                //
            else if decoData is VLFrameDeco
            {
                if withList {
                    rewardTypeList.append(.RewardFrame)
                } else {
                    return (true, rewardTypeList)
                }
                
                // 5. Motion Sticker
                //
            } else if decoData is VLStickerDeco
            {
                if withList {
                    rewardTypeList.append(.RewardMotionSticker)
                } else {
                    return (true, rewardTypeList)
                }
            }
        }
        
        return (rewardTypeList.count > 0, rewardTypeList)
    }
}
