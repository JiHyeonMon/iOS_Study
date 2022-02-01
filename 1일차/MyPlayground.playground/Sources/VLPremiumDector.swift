import UIKit

/// Premium 사용 여부를 감지(판별)한다.
///
class VLPremiumDector: NSObject {
    
    /// Premium Types
    ///
    enum VLPremiumType {
        
        case feature_video_in_animation
        case feature_video_out_animation
        case feature_text_characterwise
        case feature_overlay_bg_blur
        case feature_overlay_actionframe_blur
        case feature_overlay_blend_mode
        case feature_visualclip_transition
        case feature_overlay_effect
        
        case content_media_stock
        case content_caption
        case content_actor
        case content_filter_fx
        case content_sound
        case content_pip_video
        case content_mosaic
        case content_effect
    }
    
    class VLPremiumSet {
        
        let decoData: VLDeco
        let premiumType: VLPremiumType
        
        init(decoData: VLDeco, premiumType: VLPremiumType) {
            self.decoData = decoData
            self.premiumType = premiumType
        }
    }
    
    // MARK: - Project
    
    /// Check that user can export video with project
    ///
    /// - Parameter project:Project
    /// - Returns: Can export or not
    static public func canExport(project: VLProject) -> Bool {
        
        if VLProductManager.sharedInstance.isAvailableAllFeatures() {
            return true
        }
        
        return !Self.isUsingPremium(project: project, withList: false).using
    }
    
    /// Check
    ///
    /// - Parameter project: 프로젝트
    /// - Returns: 프리미엄 사용여부
    static public func isUsingPremium(project: VLProject, withList: Bool = false) -> (using: Bool, premiumSetList: [VLPremiumSet]) {
        
        var premiumSetList: [VLPremiumSet] = []
        
        // VisualClip
        //
        for visualClip in project.getVisualClipList() {
            
            let result = Self.isUsingPremium(decoData: visualClip, withList: withList)
            if result.using {
                if withList {
                    for premiumType in result.premiumTypeList {
                        premiumSetList.append(VLPremiumSet(decoData: visualClip, premiumType: premiumType))
                    }
                } else {
                    return (true, premiumSetList)
                }
            }
            
            // Transition
            //
            if let transition = visualClip.endTransition {
                let transitionResult = Self.isUsingPremium(transition: transition, withList: withList)
                if transitionResult.using {
                    if withList {
                        for premiumType in transitionResult.premiumTypeList {
                            premiumSetList.append(VLPremiumSet(decoData: visualClip, premiumType: premiumType))
                        }
                    } else {
                        return (true, premiumSetList)
                    }
                }
            }
        }
        
        // Decos
        //
        for decoData in project.getAllDecosInLayers() {
            
            let result = Self.isUsingPremium(decoData: decoData, withList: withList)
            if result.using {
                if withList {
                    for premiumType in result.premiumTypeList {
                        premiumSetList.append(VLPremiumSet(decoData: decoData, premiumType: premiumType))
                    }
                } else {
                    return (true, premiumSetList)
                }
            }
        }
        
        // Return
        //
        return (premiumSetList.count > 0, premiumSetList)
    }
    
    
    // MARK: - DecoData
    
    /// Check that user can export video with decodata
    ///
    /// - Parameter decoData: DecoData
    /// - Returns: Can export or not
    static public func canExport(deco: VLDeco) -> Bool {
        
        if VLProductManager.sharedInstance.isAvailableAllFeatures() {
            return true
        }
        
        return !Self.isUsingPremium(decoData: deco, withList: false).using
    }
    
    /// Check whether decoData has premium feature or not
    ///
    /// - Parameter decoData: DecoData
    static public func isUsingPremium(decoData: VLDeco, withList: Bool = false) -> (using: Bool, premiumTypeList: [VLPremiumType]) {
        
        var premiumTypeList: [VLPremiumType] = []
        
        // 1. Check premium features
        //
        
        // 1.1 Animation
        //
        if let supportType = decoData.videoInAnimation?.supportType,
           supportType == .paid {
            if withList {
                premiumTypeList.append(.feature_video_in_animation)
            } else {
                return (true, premiumTypeList)
            }
        }
        if let supportType = decoData.videoOutAnimation?.supportType,
           supportType == .paid {
            if withList {
                premiumTypeList.append(.feature_video_out_animation)
            } else {
                return (true, premiumTypeList)
            }
        }
        
        // 1.2 Text
        //
        if let textDecodata = decoData as? VLTextDeco,
           !VLProductManager.sharedInstance.isPurchased(product: .TextCharacterAttirubtes) {
            
            // Characterwise style
            //
            if textDecodata.usingCharacterAttributes() {
                if withList {
                    premiumTypeList.append(.feature_text_characterwise)
                } else {
                    return (true, premiumTypeList)
                }
            }
        }
        
        if let overlay = decoData as? VLOverlayDeco {
            
            // 1.3 BG Blur
            //
            if overlay.bgInfo.type == .blur {
                if withList {
                    premiumTypeList.append(.feature_overlay_bg_blur)
                } else {
                    return (true, premiumTypeList)
                }
            }
            
            // 1.4 ActionFrame Blur
            //
            for actionFrame in overlay.keyFrameSeqSet.keyFrameList(.blur) {
                
                guard let blur = actionFrame.blurSigma else {
                    continue
                }
                if blur > 0 {
                    if withList {
                        premiumTypeList.append(.feature_overlay_actionframe_blur)
                    } else {
                        return (true, premiumTypeList)
                    }
                }
            }
            
            // 1.5 Blend mode
            //
            if overlay.blendModeInfo.supportType == .paid {
                if withList {
                    premiumTypeList.append(.feature_overlay_blend_mode)
                } else {
                    return (true, premiumTypeList)
                }
            }
            
            // 1.6 Effect
            //
            if overlay.visualEffectInfo.info.supportType == .paid {
                if withList {
                    premiumTypeList.append(.feature_overlay_effect)
                } else {
                    return (true, premiumTypeList)
                }
            }
        }
        
        // 2. Check support type
        //
        if decoData.supportType == .paid {
            
            // 2.1. VisualClip
            //
            if let visualClip = decoData as? VLVisualClip {
                
                if visualClip.layerID == .PIPVideo,
                   !VLProductManager.sharedInstance.isPurchased(product: .PIPVideo) {
                    
                    if withList {
                        premiumTypeList.append(.content_pip_video)
                    } else {
                        return (true, premiumTypeList)
                    }
                }
                
                if visualClip.contentInfo is VLMediaStockInfo {
                    
                    if withList {
                        premiumTypeList.append(.content_media_stock)
                    } else {
                        return (true, premiumTypeList)
                    }
                }
                
                // 2.2. Caption
                //
            } else if decoData is VLCaptionDeco,
               !VLProductManager.sharedInstance.isPurchased(product: .AllCaptions) {
                
                if withList {
                    premiumTypeList.append(.content_caption)
                } else {
                    return (true, premiumTypeList)
                }
                
                // 2.3 Actor
                //
            } else if decoData is VLStickerDeco,
                      !VLProductManager.sharedInstance.isPurchased(product: .AllMotionStickers) {
                
                if withList {
                    premiumTypeList.append(.content_actor)
                } else {
                    return (true, premiumTypeList)
                }
                
                // 2.4 Filter
                //
            } else if decoData is VLFilterDeco,
                      !VLProductManager.sharedInstance.isPurchased(product: .FilterAdjustment) {
                
                if withList {
                    premiumTypeList.append(.content_filter_fx)
                } else {
                    return (true, premiumTypeList)
                }
                
                // 2.5 Sound
                //
            } else if decoData is VLSoundDeco,
                      !VLProductManager.sharedInstance.isPurchased(product: .PremiumBGM) {
                
                if withList {
                    premiumTypeList.append(.content_sound)
                } else {
                    return (true, premiumTypeList)
                }
                
                // 2.6 Mosaic
                //
            } else if decoData is VLMosaicDeco {
                
                if withList {
                    premiumTypeList.append(.content_mosaic)
                } else {
                    return (true, premiumTypeList)
                }
            } else if decoData is VLEffectDeco {
                
                if withList {
                    premiumTypeList.append(.content_effect)
                } else {
                    return (true, premiumTypeList)
                }
            }
        }
        
        return (premiumTypeList.count > 0, premiumTypeList)
    }
    
    /// Check that user can export a video with transition
    ///
    /// - Parameter transition: Transition
    /// - Returns: Can export or not
    static public func canExport(transition: VLTransition) -> Bool {
        
        if VLProductManager.sharedInstance.isAvailableAllFeatures() {
            return true
        }
        
        return !Self.isUsingPremium(transition: transition).using
    }
    
    /// Check whether decoData has premium transition or not
    ///
    /// - Parameter transition: Transition
    static public func isUsingPremium(transition: VLTransition, withList: Bool = false) -> (using: Bool, premiumTypeList: [VLPremiumType]) {
        
        var premiumTypeList: [VLPremiumType] = []
        
        // 2.1 Transition
        //
        if transition.transitionInfo.supportType == .paid,
           !VLProductManager.sharedInstance.isPurchased(product: .GraphicTransition) {
            
            if withList {
                premiumTypeList.append(.feature_visualclip_transition)
            } else {
                return (true, premiumTypeList)
            }
        }
        
        return (premiumTypeList.count > 0, premiumTypeList)
    }
    
    
    // MARK: - ContentInfo
    
    /// Check that user can export a video with datainfo
    ///
    /// - Parameter dataInfo: DataInfo
    /// - Returns: Can export or not
    static public func canExport(dataInfo: VLDataInfo) -> Bool {
        
        if VLProductManager.sharedInstance.isAvailableAllFeatures() {
            return true
        }
        
        return !Self.isUsingPremium(dataInfo: dataInfo)
    }
    
    /// Check that text is using premium features
    ///
    /// - Parameter textDeco: Text Deco
    /// - Returns: Is using premium features
    static public func isUsingTextPremiumFeatures(textDeco: VLTextDeco) -> Bool {
        
        if VLProductManager.sharedInstance.isPurchased(product: .TextCharacterAttirubtes) {
            return false
        }
        
        // Characterwise style
        //
        if textDeco.usingCharacterAttributes() {
            return true
        }
        
        return false
    }
    
    /// Return content support type is prefimum.
    ///
    /// - Parameter content: Data Infomation
    /// - Returns: 프리미엄 사용 여부
    static public func isUsingPremium(dataInfo: VLDataInfo) -> Bool {
        
        // Check support type
        //
        if dataInfo.supportType != .paid {
            return false
        }
        
        // Check premium content.
        //
        var product: VLProduct = .Everything
        switch dataInfo.type {
        
        case .frame, .template, .transition, .filter_fx, .blend_mode, .media_stock, .effect:
            product = .Everything
            
        case .sticker, .label:
            product = .AllMotionStickers
            
        case .caption:
            product = .AllCaptions
            
        case .bgm, .sound_fx:
            product = .PremiumBGM
            
        default:
            return false
        }
        
        // Check purchase or not.
        //
        return !VLProductManager.sharedInstance.isPurchased(product: product)
    }
}
