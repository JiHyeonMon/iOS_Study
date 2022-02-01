//
//  VLContentSelectViewController.swift
//  VLLO
//
//  Created by KYUNGHYUN LEE on 2020/05/31.
//  Copyright © 2020 Lee Kyunghyun. All rights reserved.
//

import UIKit

/// VLContentSelectViewController 발생한 이벤트를 전달한다.
///
protocol VLContentSelectDelegate: NSObjectProtocol {
    
    /// Content 선택
    ///
    /// - Parameters:
    ///   - viewController: VLContentSelectViewController
    ///   - content: Content
    func contentSelectViewController(_ viewController: VLContentSelectViewController, selected content: VLContentInfo)
    
    /// Content 선택 해제
    ///
    /// - Parameters:
    ///   - viewController: VLContentSelectViewController
    ///   - content: Content
    func contentSelectViewController(_ viewController: VLContentSelectViewController, deselected content: VLContentInfo)
    
    /// Bookmark가 추가 되면 호출 된다.
    ///
    /// - Parameters:
    ///   - viewController: VLContentSelectViewController
    ///   - content: Content
    func contentSelectViewController(_ viewController: VLContentSelectViewController, addBookmark content: VLContentInfo)
    
    /// Bookmark가 삭제 되면 호출 된다.
    ///
    /// - Parameters:
    ///   - viewController: VLContentSelectViewController
    ///   - content: Content
    func contentSelectViewController(_ viewController: VLContentSelectViewController, removeBookmark content: VLContentInfo)
}

/// Content를 선택하는 ViewController
/// Content에는 Font, Sticker, BGM 등이 있다.
class VLContentSelectViewController: UIViewController {
    
    /// Shortcuts
    ///
    enum Shortcut {
        
        case reward
        case recents
        case bookmark
        case new
        
        /// Shortcut에 해당하는 아이콘을 반환한다.
        ///
        public func icon() -> UIImage {
            
            switch self {
            case .reward:
                return UIImage(named: "common_outlined_icon_reward")!
                
            case .recents:
                return UIImage(named: "common_category_icon_recent.png")!
                
            case .bookmark:
                return UIImage(named: "common_category_icon_bookmark.png")!
                
            case .new:
                return UIImage(named: "common_category_icon_new.png")!
            }
        }
        
        /// Title을 반환한다.
        ///
        public func title() -> String {
            
            switch self {
            case .reward:
                return "Reward"
                
            case .recents:
                return "Recents"
                
            case .bookmark:
                return "Bookmark"
                
            case .new:
                return "New"
            }
        }
        
        /// Localized Title을 반환한다.
        ///
        public func localizedTitle() -> String {
            
            switch self {
            case .reward:
                return "Reward".localized()
                
            case .recents:
                return "Recents".localized()
                
            case .bookmark:
                return "Bookmark".localized()
                
            case .new:
                return "New".localized()
            }
        }
    }
    
    /// Shortcut list
    ///
    public var shortcutList: [Shortcut] = []
    
    /// Delegate
    ///
    public weak var delegate: VLContentSelectDelegate?
    
    /// 패키지를 보여주는 CollectionView
    ///
    @IBOutlet weak var packageCollectionView: UICollectionView?
    
    /// 콘텐츠를 보여주는 CollectionView
    ///
    @IBOutlet weak var contentCollectionView: UICollectionView!
    
    /// Reward 콘텐츠를 보여주는 CollectionView
    ///
    @IBOutlet weak var rewardCollectionView: UICollectionView!
    
    /// 북마크를 알려주는 Guide view
    ///
    @IBOutlet weak var bookmarkGuideView: UIView?
    
    /// Flow Layout
    ///
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    /// 선택된 Content
    ///
    public var selectedContent: VLContentInfo?
    
    /// 선택된 Family
    ///
    public var selectedFamily: VLFamilyInfo?
    
    /// 선택된 Package
    ///
    public var selectedPackage: VLPackageInfo?
    
    /// Content Provider
    ///
    public var contentProvider: VLContentProviderInterface!
    
    /// Sample image
    ///
    public var sampleImage: UIImage?
    
    /// Canvas의 Aspect Ratio
    ///
    public var canvasAspectRatio: Double?
    
    /// Cell Options
    ///
    public var cellWidth: CGFloat?
    public var cellHeight: CGFloat?
    public var cellDiffSize: CGFloat = 0   // (height - width)
    public var cellSelectedColor = UIColor(named: "Point")!
    
    /// Cell BG Color
    ///
    public var cellBGColor: UIColor?
    
    /// 재생 여부
    ///
    public var isPlaying: Bool = false {
        didSet {
            self.play()
        }
    }
    
    /// 스크롤 여부
    ///
    public var isScrolling: Bool = false {
        didSet {
            self.play()
        }
    }
    
    /// 스크롤 애니메이션 진행 여부
    ///
    public var isAnimating: Bool = false

    /// ViewDidLoad
    ///
    override func viewDidLoad() {
        
        // Call Super
        //
        super.viewDidLoad()
        
        // 1개 선택만 지원
        //
        self.contentCollectionView.allowsMultipleSelection = false
        self.contentCollectionView.allowsSelection = true
        if self.flowLayout.scrollDirection == .vertical {
            self.contentCollectionView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        }
        if let rewardCollectionView = self.rewardCollectionView {
            rewardCollectionView.allowsMultipleSelection = false
            rewardCollectionView.allowsSelection = true
            rewardCollectionView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        }
       
        
        // Paragraph Style
        //
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1.1

        // Package Title Attributes
        //
        self.packageTitleAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.packageTitleAttributes[.paragraphStyle] = paragraphStyle
        
        // After loading content in collecitonview, set to start offset
        //
        DispatchQueue.main.async {
            
            for i in 0..<(self.shortcutList.count + self.contentProvider.packageCount()) {
                
                if self.contentCollectionView.numberOfItems(inSection: i) > 0 {
                    
                    self.contentScroll(indexPath: IndexPath(row: 0, section: i))
                    break
                }
            }
        }
    }
    
    /// Content를 선택한다.
    ///
    /// - Parameter contentName: Content Name
    public func select(contentName: String?, animate: Bool = false) {
        
        guard let name = contentName,
              let selectedContent = self.contentProvider.content(contentName: name),
              let selectedFamily = self.contentProvider.family(familyName: selectedContent.familyName),
              let selectedPackage = self.contentProvider.package(packageName: selectedContent.packName) else {
            
            self.selectedContent = nil
            self.selectedFamily = nil
            self.selectedPackage = nil
            
            self.contentCollectionView.selectItem(at: nil, animated: animate, scrollPosition: [.centeredHorizontally, .centeredVertically])
            return
        }
        
        self.selectedContent = selectedContent
        self.selectedFamily = selectedFamily
        self.selectedPackage = selectedPackage
        let index = self.contentProvider.familyIndex(familyInfo: selectedFamily)
        
        let indexPath = IndexPath(row: index, section: selectedPackage.index + self.shortcutList.count)
        self.contentCollectionView.selectItem(at: indexPath, animated: animate, scrollPosition: [.centeredHorizontally, .centeredVertically])
    }
    
    /// 선택된 곳에 포커스를 준다.
    ///
    public func focusSelectedContent() {
        
        // 선택된 것이 없으면 처리하지 않는다.
        //
        guard let family = self.selectedFamily,
            let package = self.selectedPackage else {
                return
        }
        
        // Index를 구성한 다음 선택한다.
        //
        let index = self.contentProvider.familyIndex(familyInfo: family)
        let indexPath = IndexPath(row: index, section: Int(package.index + self.shortcutList.count))
        self.contentCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [.centeredHorizontally, .centeredVertically])
    }
    
    /// 최근 사용 업데이트 (UI).
    ///
    public func updateRecentsUI() {
        
        if let index = self.section(shortcut: .recents) {
            self.contentCollectionView.reloadSections(IndexSet(integer: index))
        }
    }
    
    /// Recent를 초기화 한다.
    ///
    /// - Parameter sender: Reset button
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        
        let viewController = VLAlertViewController.title("Warning".localized(),
                                                         message: "Are you sure to delete all recents?".localized(),
                                                         others: ["Delete".localized(), "No".localized()],
                                                         delegate: nil)
        viewController.tag = 0
        viewController.modalPresentationStyle = .overFullScreen
        viewController.delegate = self
        VLViewControllerManager.present(viewController, animated: false, completion: nil)
    }
    
    /// Package 이름을 반환한다.
    ///
    /// - Parameter indexPath: IndexPath
    /// - Returns: Localized Package Name
    public func localizedPackageName(index: Int) -> String {
        
        if index < self.shortcutList.count {
            return self.shortcutList[index].localizedTitle()
            
        } else {
            return self.contentProvider.package(index: index - self.shortcutList.count)!.localizedDisplayName
        }
    }
    
    /// Icon(image)를 반환한다.
    ///
    /// - Parameter index: Index
    /// - Returns: Image
    public func icon(index: Int) -> UIImage? {
        
        if index < self.shortcutList.count {
            
            return self.shortcutList[index].icon()
            
        } else {
            
            /// Get package
            ///
            guard let package = self.contentProvider.package(index: index - self.shortcutList.count) else {
                return nil
            }
            
            if VLPremiumDector.canExport(dataInfo: package) {
                return UIImage(named: "common_category_icon_dot.png")
            } else {
                return UIImage(named: "common_category_thumb_icon_premium.png")
            }
        }
    }
    
    /// Return family info at indexPath
    ///
    /// - Parameter indexPath: IndexPath
    /// - Returns: Family Info
    public func getFamilyInfo(indexPath: IndexPath) -> VLFamilyInfo? {
        
        // Family를 가져온다.
        //
        if indexPath.section < self.shortcutList.count {
            
            // Shortcut 인 경우
            //
            let shortcut = self.shortcutList[indexPath.section]
            switch shortcut {
            case .reward:
                return self.contentProvider.reward(index: indexPath.row)

            case .recents:
                return self.contentProvider.recentsFamily(index: indexPath.row)
                
            case .bookmark:
                return self.contentProvider.bookmarkFamily(index: indexPath.row)
                
            case .new:
                return self.contentProvider.new(index: indexPath.row)
            }
          
        } else {
            
            // Package 인 경우
            //
            let package = self.contentProvider.package(index: indexPath.section - self.shortcutList.count)!
            return self.contentProvider.family(packageName: package.name, index: indexPath.row)
        }
    }
    
    /// Return content info at indexPath
    ///
    /// - Parameter indexPath: IndexPath
    /// - Returns: Content Info
    public func getContentInfoList(indexPath: IndexPath) -> [VLContentInfo] {
        
        guard let familyInfo = self.getFamilyInfo(indexPath: indexPath) else {
            return []
        }
        return self.contentProvider.contentList(packageName: familyInfo.packName, familyName: familyInfo.name)
    }
    
    /// Update UI of Cell
    ///
    /// - Parameter cell: Content Cell
    /// - Parameter family: Family Info
    /// - Parameter contentList: Content Info list
    public func update(cell: VLContentCell, family: VLFamilyInfo, contentList: [VLContentInfo]) {
        
        cell.familyInfo = family
        cell.contentInfoList = contentList
        
        // 이미 선택한 경우 현재 Index를 그대로 설정한다.
        //
        if cell.isSelected,
           let content = self.selectedContent {
            
            cell.index = Int(content.index)
            
            // 화면 및 콘텐츠의 해상도 값이 존재하는 경우 가장 비슷한 콘텐츠를 시작 인덱스로 설정한다.
            //
        } else if contentList.count > 0,
            let canvasAspectRatio = self.canvasAspectRatio,
            let overlayInfoList = contentList as? [VLOverlayInfo],
            overlayInfoList[0].aspectRatio != nil {
            
            // 가장 유사한 해상도를 가진 콘텐츠를 시작 인덱스로 설정한다.
            //
            var delta: Double = 100
            for (i, overlayInfo) in overlayInfoList.enumerated() {
                
                guard let aspectRatio = overlayInfo.aspectRatio else {
                    break
                }
                
                // 더 비슷한 해상도인 경우 시작 index를 변경한다.
                //
                let delta2 = abs(canvasAspectRatio - aspectRatio)
                if delta2 < delta {
                    cell.index = i
                    delta = delta2
                }
            }
            
            // 화면에 등장하는 경우 시작 인덱스는 무조건 0부터 시작한다.
            //
        } else {
            
            cell.index = 0
        }
        
        // 잠금 및 즐겨찾기 설정
        //
        cell.isPremium = !VLPremiumDector.canExport(dataInfo: contentList[cell.index])
        cell.isBookmarked = self.contentProvider.isBookmarked(familyName: family.name)
        cell.isDeletable = contentList[cell.index].deletable
        
        // 2개 이상의 콘텐츠를 가지고 있는 경우
        //
        if contentList.count > 1 {
          
            cell.containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            cell.pageControl?.isHidden = false
            cell.pageControl?.numberOfPages = contentList.count
            
            // 1개인 경우
            //
        } else {
            
            cell.containerView?.backgroundColor = .clear
            cell.pageControl?.isHidden = true
        }
    }
    
    /// Package Title Attributes
    ///
    fileprivate var packageTitleAttributes: [NSAttributedString.Key : Any] = [:]
    
    /// Play
    ///
    fileprivate func play() {
        
        guard let collectionView = self.contentCollectionView else {
            return
        }
        
        for cell in collectionView.visibleCells as! [VLContentCell] {
            cell.isPlaying = self.isPlaying
        }
    }
    
    /// 컬럼의 개수를 반환한다.
    ///
    /// - Returns: Column 개수
    fileprivate func columnCount() -> Int {
        
        return max(1, Int(self.contentCollectionView.bounds.width / self.cellWidth!))
    }
    
    /// 로우의 개수를 반환한다.
    ///
    /// - Returns: Row 개수
    fileprivate func rowCount() -> Int {
        
        return max(1, Int(self.contentCollectionView.bounds.height / self.cellHeight!))
    }
    
    /// Shortcut에 해당하는 Index를 반환한다.
    ///
    /// - Parameter shortcut: Shortcut
    /// - Returns: Index
    fileprivate func section(shortcut: Shortcut) -> Int? {
        
        for (i, short) in self.shortcutList.enumerated() {
            
            if short == shortcut {
                
                return i
            }
        }
        
        return nil
    }
    
    /// Index에 해당하는 Content의 개수를 반환한다.
    ///
    /// - Parameter index: Index (shortcut + package 순서에 해당하는 Index)
    /// - Returns: Content 개수
    fileprivate func contentCount(index: Int) -> Int {

        // Shortcut section
        //
        if index < self.shortcutList.count {
            
            let shortcut = self.shortcutList[index]
            switch shortcut {
            case .reward:
                let count = self.contentProvider.rewardCount()
                return count
                
            case .recents:
                let count = self.contentProvider.recentsCount()
                return count
                
            case .bookmark:
                let count = self.contentProvider.bookmarkCount()
                return count
                
            case .new:
                let count = self.contentProvider.newCount()
                return count
            }
            
        } else {
            
            let package = self.contentProvider.package(index: index - self.shortcutList.count)!
            return self.contentProvider.familyCount(packageName: package.name)
        }
    }
    
    /// IndexPath의 시작 부분으로 스크롤한다.
    ///
    /// - Parameter indexPath: IndexPath
    fileprivate func contentScroll(indexPath: IndexPath, animate: Bool = true) {
        
        // 시작 위치를 찾는다.
        //
        guard var offset = self.contentCollectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath)?.frame.origin else {
            
            if self.flowLayout.scrollDirection == .vertical {
                self.contentCollectionView.scrollToItem(at: indexPath, at: .top, animated: animate)
            } else {
                self.contentCollectionView.scrollToItem(at: indexPath, at: .left, animated: animate)
            }
            return
        }
        
        // 같은 위치면 스크롤 하지 않는다.
        //
        if offset == self.contentCollectionView.contentOffset {
            return
        }
        
        // 최대/최소 스크롤 위치 보정
        //
        offset.x = max(0, min(offset.x, self.contentCollectionView.contentSize.width - self.contentCollectionView.bounds.width))
        offset.y = max(0, min(offset.y, self.contentCollectionView.contentSize.height - self.contentCollectionView.bounds.height)) - self.contentCollectionView.contentInset.top
        
        // 스크롤
        //
        if animate {
            self.isScrolling = true
            self.isAnimating = true
        }
        self.contentCollectionView.setContentOffset(offset, animated: animate)
        self.packageCollectionView?.scrollToItem(at: IndexPath(row: indexPath.section, section: 0), at: .centeredHorizontally, animated: animate)
    }
}

// MARK: - UICollectionViewDelegate & UICollectionViewDataSource
extension VLContentSelectViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// 총 Section의 개수를 반환한다.
    ///
    /// - Parameter collectionView: CollectionView - Package or Content
    /// - Returns: 총 Section의 개수를 반환한다. Package는 무조건 1개, Content는 Pacage 개수 + 2개를 반환한다.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView == self.packageCollectionView {
            return 1
        } else if collectionView == self.rewardCollectionView {
            return 1
        } else {
            return self.contentProvider.packageCount() + self.shortcutList.count
        }
    }
    
    /// Section 안에 아이템 개수를 반환한다.
    ///
    /// - Parameters:
    ///   - collectionView: CollectionView - Package or Content
    ///   - section: Section
    /// - Returns: Section내 아이템 개수 - Package는 모든 Package의 개수, Content는 Package내 Content의 개수를 반환한다.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.packageCollectionView {
            return self.contentProvider.packageCount() + self.shortcutList.count
            
        } else {
            return self.contentCount(index: section)
        }
    }
    
    /// Package Cell을 보여준다.
    ///
    /// - Parameters:
    ///   - collectionView: CollectionView - ContentCollectionView
    ///   - kind: 종류 - Header
    ///   - indexPath: IndexPath
    /// - Returns: UICollectionReusableView
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "package", for: indexPath)
        guard let packageView = header as? VLContentPackageReusableView else {
            return header
        }
        
        // Package 정보를 가져온다.
        //
        packageView.titleLabel?.text = self.localizedPackageName(index: indexPath.section)
        packageView.imageView?.image = self.icon(index: indexPath.section)

        // Bookmark인 경우 Guide Label을 보여준다.
        //
        if indexPath.section < self.shortcutList.count,
           self.shortcutList[indexPath.section] == .bookmark {
            
            packageView.bookmarkGuideLabel.isHidden = false
            packageView.resetButton?.isHidden = true
            
        } else if indexPath.section < self.shortcutList.count,
                  self.shortcutList[indexPath.section] == .recents {
            
            packageView.bookmarkGuideLabel.isHidden = true
            packageView.resetButton?.isHidden = false
            packageView.resetButton?.isEnabled = true
            
            // 그 외에는 숨긴다.
            //
        } else {
            
            packageView.bookmarkGuideLabel.isHidden = true
            packageView.resetButton?.isHidden = true
        }
        
        return packageView
    }
    
    /// Cell을 반환한다.
    ///
    /// - Parameters:
    ///   - collectionView:CollectionView - Package or Content
    ///   - indexPath: IndexPath
    /// - Returns:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.rewardCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "content", for: indexPath) as! VLContentCell
            cell.containerView?.layer.borderColor = self.cellSelectedColor.cgColor
            cell.delegate = self
            cell.backgroundColor = self.cellBGColor
            cell.accessibilityIdentifier = "content_" + "\(indexPath.section)" + "\(indexPath.row)"
            cell.isAccessibilityElement = true
            
            if let family = self.getFamilyInfo(indexPath: indexPath) {
                print("??? cellForItemAt reward \(family)")
                let contentList = self.getContentInfoList(indexPath: indexPath)
                self.update(cell: cell, family: family, contentList: contentList)
            }
            
            cell.isPlaying = self.isPlaying
            cell.isReward = true
            cell.isPremium = false
            return cell
        }
        
        // Content
        //
        if collectionView == self.contentCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "content", for: indexPath) as! VLContentCell
            cell.containerView?.layer.borderColor = self.cellSelectedColor.cgColor
            cell.delegate = self
            cell.backgroundColor = self.cellBGColor
            cell.accessibilityIdentifier = "content_" + "\(indexPath.section)" + "\(indexPath.row)"
            cell.isAccessibilityElement = true
            
            if let family = self.getFamilyInfo(indexPath: indexPath) {
                print("??? cellForItemAt content \(family)")

                let contentList = self.getContentInfoList(indexPath: indexPath)
                self.update(cell: cell, family: family, contentList: contentList)
            }
            
            cell.isPlaying = self.isPlaying
            
            return cell
            
        } else {
            
            // Shortcut은 이미지로 표시한다.
            //
            if indexPath.row < self.shortcutList.count {
                
                let packageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "package_image", for: indexPath) as! VLPackageCell
                packageCell.imageView?.image = self.shortcutList[indexPath.row].icon().withRenderingMode(.alwaysTemplate)
                packageCell.accessibilityIdentifier = "content_category_" + self.shortcutList[indexPath.row].title()
                packageCell.isAccessibilityElement = true
                
                return packageCell
                
                // Package는 타이틀로 표시한다.
                //
            } else {
                
                let packageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "package_title", for: indexPath) as! VLPackageCell
                packageCell.titleLabel?.text = self.localizedPackageName(index: indexPath.row)
                packageCell.accessibilityIdentifier = "content_category_" + "\(indexPath.row - self.shortcutList.count)"
                packageCell.isAccessibilityElement = true
                
                return packageCell
            }
        }
    }
    
    /// Cell의 사이즈를 반환한다.
    ///
    /// - Parameters:
    ///   - collectionView:CollectionView - Package or Content
    ///   - collectionViewLayout: FlowLayout
    ///   - indexPath: IndexPath
    ///
    /// - Returns: Cell의 크기
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Content
        //
        if collectionView == self.contentCollectionView || collectionView == self.rewardCollectionView {
            
            if self.flowLayout.scrollDirection == .horizontal {
                
                // Row Count
                //
                let count = self.rowCount()
                
                // 셀의 정확한 크기
                //
                let cellHeight = min(self.cellHeight!, (collectionView.bounds.height - (CGFloat(count - 1) * self.flowLayout.minimumLineSpacing) - self.flowLayout.sectionInset.top - self.flowLayout.sectionInset.bottom) / CGFloat(count))
                
                // Return
                //
                return CGSize(width: cellHeight - self.cellDiffSize, height: cellHeight)
                
            } else {
                
                // Column Count
                //
                let count = self.columnCount()
                
                // 셀의 정확한 크기
                //
                let size = Int((collectionView.bounds.width - (CGFloat(count - 1) * self.flowLayout.minimumInteritemSpacing) - self.flowLayout.sectionInset.left - self.flowLayout.sectionInset.right) / CGFloat(count))
                
                // Return
                //
                return CGSize(width: CGFloat(size), height: self.cellHeight ?? CGFloat(size) + self.cellDiffSize)
            }
            
            // Package
            //
        } else {
            
            if indexPath.row < self.shortcutList.count {
                
                return CGSize(width: 40, height: 40)
                
            } else {
                
                // Package Name에 맞게 너비를 계산한다.
                //
                let localizedString = self.localizedPackageName(index: indexPath.row) as String
                let measureWidth = localizedString.size(withAttributes: self.packageTitleAttributes).width
                let margin: CGFloat = 30
                return CGSize(width: measureWidth + margin, height: 40)
            }
        }
    }
    
    /// Cell이 선택되면 호출된다.
    ///
    /// - Parameters:
    ///   - collectionView: CollectionView - Package or Content
    ///   - indexPath: IndexPath
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("??? VLContentSelectVL didselect \(indexPath.section) \(indexPath.row)")
        // Content 선택
        //
        if collectionView == self.contentCollectionView || collectionView == self.rewardCollectionView {
            // 실제 아이템
            print("??? collectionview == contentcollectionview")
            // ContentCell
            //
            let cell = collectionView.cellForItem(at: indexPath) as! VLContentCell
            
            // 변경된 Content를 전달한다.
            //
            self.selectedContent = self.getContentInfoList(indexPath: indexPath)[cell.index]
            self.selectedFamily = self.getFamilyInfo(indexPath: indexPath)
            self.selectedPackage = self.contentProvider.package(packageName: self.selectedFamily!.packName)
            
            // Delegate에 전달한다.
            //
            self.delegate?.contentSelectViewController(self, selected: self.selectedContent!)
            cell.next()
            
            // Package 선택
            //
        } else {
            // 여기가 탭부분
            print("??? collectionview == packageCollectionView")

            // Package 시작 부분으로 scroll 한다.
            //
            self.contentScroll(indexPath: IndexPath(row: 0, section: indexPath.row))
            
            // 보상형 광고 탭하면
            if VLDetectManager.sharedInstance.checkUserType() == .Free && indexPath.row == 0 {
                // 보상형만 보이게
                print("??? 보상형 click")
                self.contentCollectionView.isHidden = true
                self.rewardCollectionView.isHidden = false
                
            } else {
                self.contentCollectionView.isHidden = false
                self.rewardCollectionView.isHidden = true
            }
        }
    }
    
    /// Cell이 곧 화면에 등장한다.
    ///
    /// - Parameters:
    ///   - collectionView: CollectionView - Content
    ///   - cell: VLContentStickerCell
    ///   - indexPath: IndexPath
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let contentCell = cell as? VLContentCell else {
            return
        }
        contentCell.isPlaying = self.isPlaying
        
        if !self.isAnimating,
           self.packageCollectionView?.indexPathsForSelectedItems?.first != indexPath {
            
            self.packageCollectionView?.selectItem(at: IndexPath(row: indexPath.section, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    /// Cell이 곧 화면에서 사라진다.
    ///
    /// - Parameters:
    ///   - collectionView: CollectionView - Content
    ///   - cell: VLContentStickerCell
    ///   - indexPath: IndexPath
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let contentCell = cell as? VLContentCell else {
            return
        }
        contentCell.isPlaying = false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if scrollView != self.contentCollectionView {
            return
        }
        self.isScrolling = true
        self.isAnimating = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if scrollView != self.contentCollectionView {
            return
        }
        self.isScrolling = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if scrollView != self.contentCollectionView {
            return
        }
        
        if !decelerate {
            self.isScrolling = false
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        if scrollView != self.contentCollectionView {
            return
        }
        
        self.isAnimating = false
        self.isScrolling = false
    }
}

// MARK: - VLContentCellDelegate
extension VLContentSelectViewController: VLContentCellDelegate {

     /// Cell이 길게 눌리면 호출된다.
    ///
    /// - Parameter conentCell: Cell
    func contentCellLongPressed(_ contentCell: VLContentCell) {
        
        // ShortCut의 Index를 가져온다.
        //
        guard let shortcutIndex = self.section(shortcut: .bookmark),
              let indexPath = self.contentCollectionView.indexPath(for: contentCell),
              let family = self.getFamilyInfo(indexPath: indexPath) else {
            return
        }
        
        // 즐겨찾기가 추가/삭제 된 것을 알린다.
        //
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 애니메이션 방지
        //
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let content = self.getContentInfoList(indexPath: indexPath)[contentCell.index]
        
        // 북마크를 삭제한다.
        //
        if contentCell.isBookmarked {
            
            _ = self.contentProvider.removeBookmark(familyName: family.name)
            self.contentCollectionView.reloadSections(IndexSet(integer: shortcutIndex))
            contentCell.isBookmarked = false
            
            // Bookmark의 개수
            //
            let bookmarkCount = self.contentProvider.bookmarkCount()
            
            // 가로 스크롤
            //
            if self.flowLayout.scrollDirection == .horizontal {
                
                let rowCount = self.rowCount()
                
                // 줄 변경이 발생한 경우 스크롤 위치를 유지하기 위해서 ContentOffset을 조정한다.
                //
                if bookmarkCount % rowCount == 0 {
                    
                    let interSpacing = (bookmarkCount == 0) ? 0 : self.flowLayout.minimumInteritemSpacing
                    self.contentCollectionView.contentOffset = CGPoint(x: self.contentCollectionView.contentOffset.x - (contentCell.bounds.width + interSpacing), y: 0)
                }
                
                // 세로 스크롤
                //
            } else {
                
                let columnCount = self.columnCount()
                
                // 줄 변경이 발생한 경우 스크롤 위치를 유지하기 위해서 ContentOffset을 조정한다.
                //
                if bookmarkCount % columnCount == 0 {
                    
                    let lineScaping = (bookmarkCount == 0) ? 0 : self.flowLayout.minimumLineSpacing
                    self.contentCollectionView.contentOffset = CGPoint(x: 0, y: self.contentCollectionView.contentOffset.y - (contentCell.bounds.height + lineScaping))
                }
            }
            
            CATransaction.commit()
            
            // Delegate로 전달
            //
            self.delegate?.contentSelectViewController(self, removeBookmark: content)
            
            // Bookmark에 추가한다.
            //
        } else {
            
            _ = self.contentProvider.addBookmark(familyName: family.name)
            self.contentCollectionView.insertItems(at: [IndexPath(row: 0, section: shortcutIndex)])
            contentCell.isBookmarked = true
            
            // 현재 Bookmark의 개수
            //
            let bookmarkCount = self.contentProvider.bookmarkCount()
            
            // 가로 스크롤
            //
            if self.flowLayout.scrollDirection == .horizontal {
                
                let rowCount = self.rowCount()
                
                // 줄 변경이 발생한 경우 스크롤 위치를 유지하기 위해서 ContentOffset을 조정한다.
                //
                if rowCount <= 1 || bookmarkCount % rowCount == 1 {
                    
                    let interSpacing = (bookmarkCount == 1) ? 0 : self.flowLayout.minimumInteritemSpacing
                    self.contentCollectionView.contentOffset = CGPoint(x: self.contentCollectionView.contentOffset.x + (contentCell.bounds.width + interSpacing), y: 0)
                }
                
                // 세로 스크롤
                //
            } else {
                
                let columnCount = self.columnCount()
                
                // 줄 변경이 발생한 경우 스크롤 위치를 유지하기 위해서 ContentOffset을 조정한다.
                //
                if columnCount <= 1 || bookmarkCount % columnCount == 1 {
                    
                    let lineScaping = (bookmarkCount == 1) ? 0 : self.flowLayout.minimumLineSpacing
                    self.contentCollectionView.contentOffset = CGPoint(x: 0, y: self.contentCollectionView.contentOffset.y + (contentCell.bounds.height + lineScaping))
                }
            }
            
            CATransaction.commit()
            
            // Delegate에 전달한다.
            //
            self.delegate?.contentSelectViewController(self, addBookmark: content)
        }
        
        // Update bookmark
        //
        for cell in self.contentCollectionView.visibleCells as! [VLContentCell] {
            
            guard let indexPath = self.contentCollectionView.indexPath(for: cell),
                  let familyInfo = self.getFamilyInfo(indexPath: indexPath) else {
                continue
            }
            
            cell.isBookmarked = self.contentProvider.isBookmarked(familyName: familyInfo.name)
        }
    }
    
    /// Call when user pressed delete button
    ///
    /// - Parameter contentCell: Cell
    func contentCellDeletePressed(_ contentCell: VLContentCell) {
        
        let viewController = VLAlertViewController.title("My Filter Delete".localized(),
                                                         message: "Are you sure you want to delete the selected My Filter?".localized(),
                                                         others: ["Delete".localized(), "No".localized()],
                                                         delegate: nil)
        viewController.tag = 1
        viewController.data = contentCell
        viewController.modalPresentationStyle = .overFullScreen
        viewController.delegate = self
        self.present(viewController, animated: false, completion: nil)
    }
}

// MARK: - VLAlertViewControllerDelegate
extension VLContentSelectViewController: VLAlertViewControllerDelegate {
    
    /// Call when user select the index
    ///
    func alertViewController(_ viewController: VLAlertViewController, selected index: Int) {
        
        switch viewController.tag {
        case 0:
            
            // Clear all recents
            //
            if index == 0,
               let section = self.section(shortcut: .recents) {
              
                // Get recent count
                //
                let recentCount = self.contentCount(index: section)
                var indexPathList: [IndexPath] = []
                for i in 0..<recentCount {
                    indexPathList.append(IndexPath(row: i, section: section))
                }
                
                // Clear!
                //
                if self.contentProvider.clearRecents() {
                    self.contentCollectionView.deleteItems(at: indexPathList)
                }
            }
            
        case 1:
            
            guard index == 0,
                  let cell = viewController.data as? VLContentCell,
                  let indexPath = self.contentCollectionView.indexPath(for: cell) else {
                return
            }
            
            // 만약 선택되어 있는 상황이면 선택을 해제한다.
            //
            if cell.isSelected {
                self.contentCollectionView.deselectItem(at: indexPath, animated: false)
                self.delegate?.contentSelectViewController(self, deselected: cell.contentInfoList[cell.index])
            }
            
            _ = self.contentProvider.remove(famlyName: cell.familyInfo.name)
            self.contentCollectionView.deleteItems(at: [indexPath])
            
        default:
            break
        }
    }
}
