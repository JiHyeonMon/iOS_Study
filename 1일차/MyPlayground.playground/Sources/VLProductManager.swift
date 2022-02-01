import UIKit
import StoreKit

/// Manage product which is saling on AppStore.
///
class VLProductManager: NSObject {
    
    /// Notification Keys
    ///
    static public let Key_Purchased             = "product_manager_product_prucased"        // 구매 완료
    static public let Key_Restored              = "product_manager_restored"                // 복원 완료
    static public let Key_Failed                = "product_manager_failed"                  // 구매 및 복원 실패
    static public let Key_LoadedProducts        = "product_manager_loaded_products"         // 상품 로드 완료
    static public let Key_FailedToLoadProducts  = "product_manager_failed_to_load_products" // 상품 로드 실패
    
    /// Singleton instance
    ///
    static public let sharedInstance = VLProductManager()
    
    /// iTunesConnect에서 가져온 SharedSecret으로, AppStore의 결제 내역을 받아오기 위해서 필요하다.
    ///
    static fileprivate let SharedSecret     = "b59058e276e44047a03f4894be8a778e"
    
    /// Available premium product list
    ///
    public var premiumProductList: [VLProduct] = []
    
    /// Available premium product list
    ///
    public var subscriptionProductList: [VLProduct] = []
    
    /// 생성자
    ///
    override init() {
        
        // Product infomation
        //
        for product in VLProduct.allCases {
            
            if product.isAvailablePremium() {
                self.premiumProductList.append(product)
            }
            
            if product.isSubscription() {
                self.subscriptionProductList.append(product)
            }
        }
        
        // 이전에 결제 기록한 내역을 삭제하고 모두 영수증으로 처리하도록 변경한다.
        //
        UserDefaults.standard.setValue(nil, forKey: VLProduct.Everything.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.AllFeatures.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.SubscriptionPremiumMonthly.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.SubscriptionPremiumMonthly2.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.SubscriptionPremiumAnnually.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.SubscriptionPremium2Weekly.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.SubscriptionPremium2Monthly.IAPKey())
        UserDefaults.standard.setValue(nil, forKey: VLProduct.SubscriptionPremium2Annually.IAPKey())
        
        // IAP Helper를 생성한다.
        //
        self.iapHelper = IAPHelper(sharedSecret: Self.SharedSecret)
        
        // Call Super
        //
        super.init()
        
        // Delegate 연결
        //
        self.iapHelper.delegate = self
        
        // 상품을 로드한다.
        //
        _ = self.reloadProducts()
    }
    
    /// Convert product list to product key list
    ///
    /// - Parameter proudctList: Product list
    /// - Returns: Key list
    fileprivate func productListToKeyList(_ proudctList: [VLProduct]) -> [String] {
        
        var productKeyList: [String] = []
        for product in proudctList {
            productKeyList.append(product.IAPKey())
        }
        
        return productKeyList
    }
    
    /// 상품 정보를 store로 부터 가져 왔는지 여부를 반환한다.
    ///
    /// - Returns: 상품 정보 로드 여부
    public func loadedProducts() -> Bool {
        
        return self.iapHelper.loadedProducts
    }
    
    /// 상품 정보를 다시 로드한다.
    ///
    public func reloadProducts() -> Bool {
        
        // 현재 사용중인 IAP 상품
        //
        return self.iapHelper.requestProducts(productIDList: self.productListToKeyList(self.premiumProductList))
    }
    
    
    // MARK: - Payment

    /// 결제를 요청한다.
    /// - Parameters:
    ///   - product: 결제 상품
    ///   - completeHandler: Callback Handler
    public func purchase(product: VLProduct, completeHandler: @escaping (Bool) -> Void) {
        
        // 구매 요청
        //
        if !self.iapHelper.requestPayment(productID: product.IAPKey()) {
            
            completeHandler(false)
            return
        }
        
        // Handler 연결
        //
        self.purchaseCompleteHandler = completeHandler
    }
    
    /// 구매내역을 복원한다.
    /// - Parameters:
    ///   - completeHandler: Callback handler
    public func restore(completeHandler: @escaping (Bool, [String]) -> Void) {
        
        // Handler 연결
        //
        self.restoreCompleteHandler = completeHandler
        
        if !self.iapHelper.requestRestore() {
            
            completeHandler(false, [])
            self.restoreCompleteHandler = nil
            return
        }
    }
    
    /// Objective C 코드 호환성을 위해서 제공하는 method, swift로 100% migration 되면 삭제하도록 한다.
    ///
    @objc static public func isAvailableRemoveAds() -> Bool {
        
        return self.sharedInstance.isAvailable(product: .RemoveAds)
    }
    
    
    // MARK: - Product Infomation
    
    /// 상품의 가격을 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 가격(String, 현지화 가격으로 표기된다.)
    public func priceString(product: VLProduct) -> String? {
        
        return self.iapHelper.priceString(productID: product.IAPKey())
    }
    
    /// 상품의 가격을 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 가격(String, 현지화 가격으로 표기된다.)
    public func price(product: VLProduct) -> Double? {
        
        return self.iapHelper.price(productID: product.IAPKey())
    }
    
    /// 구독 상품의 갱신 기간을 반환한다.
    ///
    /// - Parameter product: Product
    /// - Returns: 갱신 기간
    public func subscriptionPeriod(product: VLProduct) -> SKProductSubscriptionPeriod? {
        
        return self.iapHelper.subscriptionPeriod(productID: product.IAPKey())
    }
    
    /// 무료 체험 기간 중인지 여부를 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 무료 체험 중인지 여부
    public func isFreeTrial() -> Bool {
        
        for product in self.subscriptionProductList {
            if self.isFreeTrial(product: product) {
                return true
            }
        }
        
        return false
    }
    
    /// 무료 체험 기간 중인지 여부를 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 무료 체험 중인지 여부
    public func isFreeTrial(product: VLProduct) -> Bool {
        
        return self.iapHelper.available(productID: product.IAPKey()) && self.iapHelper.isFreeTrial(productID: product.IAPKey())
    }
    
    /// 상품의 구독 만료일을 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 만료 일
    public func expireDate(product: VLProduct) -> Date? {
        
        return self.iapHelper.expireDate(productID: product.IAPKey())
    }
    
    /// Intoryductory 가격 정보를 반환한다.
    ///
    /// - Parameter product: Product
    /// - Returns: Discount
    public func introductoryPrice(product: VLProduct) -> SKProductDiscount? {
        
        return self.iapHelper.introductoryPrice(productID: product.IAPKey())
    }
    
    /// 상품 명을 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 상품 명
    public func title(product: VLProduct) -> String? {
        
        return self.iapHelper.title(productID: product.IAPKey())
    }
    
    /// 상품 설명을 반환한다.
    ///
    /// - Parameter product: 상품
    /// - Returns: 상품 설명
    public func description(product: VLProduct) -> String? {
        
        return self.iapHelper.description(productID: product.IAPKey())
    }
    
    
    // MARK: - 구매 여부
    
    public func isAvailableAllFeatures() -> Bool {
        
        #if DEBUG
        if VLConfiguration.SupportType == .paid {
            return true
        }
        #endif
        
        // 유료 구매 여부 확인
        //
        for product in self.premiumProductList {
            if self.iapHelper.available(productID: product.IAPKey()) {
                return true
            }
        }
        
        return false
    }
    
    /// 상품 사용 가능 여부를 반환한다.
    ///
    /// - Returns: 사용 가능 여부
    public func isAvailable(product: VLProduct) -> Bool {
        
        #if DEBUG
        if VLConfiguration.SupportType == .paid {
            return true
        }
        #endif
        
        // 유료 구매 여부 확인
        //
        if self.isAvailableAllFeatures() {
            return true
        }
        
        // 해당 기능 사용 여부를 반환한다.
        //
        return self.isPurchased(product: product)
    }
    
    /// 해당 상품의 구매 여부를 반환한다.
    ///
    /// - Parameter product: Product
    /// - Returns: 구매 여부
    public func isPurchased(product: VLProduct) -> Bool {
        
        // 해당 기능 사용 여부를 반환한다.
        //
        return self.iapHelper.available(productID: product.IAPKey())
    }
    
    // MARK: - Private properties
    
    // IAPHelper
    //
    internal let iapHelper: IAPHelper
    
    // Purchase complete handler
    //
    fileprivate var purchaseCompleteHandler: ((Bool) -> Void)?
    
    // Restore complete handler
    //
    fileprivate var restoreCompleteHandler: ((Bool, [String]) -> Void)?
}

// MARK: - IAPHelperDelegate
extension VLProductManager: IAPHelperDelegate {
    
    /// Product 로드에 성공하면 호출된다.
    ///
    /// - Parameters:
    ///   - iapHelper: IAPHelper
    ///   - products: Products
    func iapHelper(_ iapHelper: IAPHelper, loadCompleted products: [SKProduct]) {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.Key_LoadedProducts), object: products)
    }
    
    /// Product 로드 실패하면 호출된다.
    ///
    /// - Parameters:
    ///   - iapHelper: IAPHelper
    ///   - error: Error
    func iapHelper(_ iapHelper: IAPHelper, loadFailed error: Error) {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.Key_FailedToLoadProducts), object: error)
    }
    
    /// Product의 상태(state)가 변경되면 호출된다.
    ///
    /// - Parameters:
    ///   - iapHelper: IAPHelper
    ///   - productID: ProductManager
    func iapHelper(_ iapHelper: IAPHelper, productID: String, purchaseComplete: Bool, error: Error?) {

        self.purchaseCompleteHandler?(purchaseComplete)
        self.purchaseCompleteHandler = nil
        if purchaseComplete {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.Key_Purchased), object: productID)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.Key_Failed), object: productID)
        }
    }

    /// 구매 복원 성공/실패시 호출된다.
    ///
    /// - Parameters:
    ///   - iapHelper: IAPHelper
    ///   - restoreComplete: Restore  성공/실패 여부
    ///   - error: 실패 시 Error 값
    func iapHelper(_ iapHelper: IAPHelper, restoreProductID: [String], restoreComplete: Bool, error: Error?) {

        self.restoreCompleteHandler?(restoreComplete, restoreProductID)
        self.restoreCompleteHandler = nil
        
        if let err = error {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.Key_Failed), object: err)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Self.Key_Restored), object: nil)
        }
    }
}
