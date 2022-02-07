Main

//
//  MainViewController.swift
//  VLLO
//
//  Created by KYUNGHYUN LEE on 25/08/2019.
//  Copyright © 2019 Lee Kyunghyun. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseAnalytics

/// Extension NavigationController for orientation controlling
///
extension UINavigationController {
    
    override open var shouldAutorotate: Bool {
        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        if VLUtil.iPad() {
            return .all
            
        } else {
            return [.portrait, .portraitUpsideDown]
        }
    }
}

/// VLLO 시작 ViewController
///
class VLStartViewController: VLBaseViewController {
    
    private static let StickyHeaderHeight: CGFloat = 70
    // 선택화면에서 stickyHeader가 상단에 붙으며 collectionView의 contentInset 설정 필요. MyprojectHeight(70)-TopViewHeight(50) = 20
    private static let MinimumSelectCollectionViewSpacingFromTop: CGFloat = 20
    private static var BannerHeightInIPhone: CGFloat = 270
    private static var BannerHeightInIPad: CGFloat = 408
    
    var maxHeight: CGFloat = VLUtil.iPhone() ? BannerHeightInIPhone : BannerHeightInIPad
    let minHeight: CGFloat = StickyHeaderHeight
    
    private var currentSortingType: ProjectSort = .sortType(standard: .opened, direction: .desc)
    private var currentTagType: ProjectTag = .all
    
    // MARK: - Storyboard UI
    //
    @IBOutlet weak var topContainer: UIView!
    @IBOutlet weak var settingButton: VLButton!
    @IBOutlet weak var storeButton: VLButton!
    @IBOutlet weak var headerContainer: UIView!
    
    @IBOutlet weak var bannerMenu: UIView!
    @IBOutlet weak var bannerContainer: UIView!
    @IBOutlet weak var myProjectView: UIView!
    @IBOutlet weak var myProjectsButton: VLButton!
    @IBOutlet weak var projectImageScaleButton: VLButton!
    @IBOutlet weak var projectSortButton: VLButton!
    @IBOutlet weak var projectSelectButton: VLButton!
    
    @IBOutlet weak var createNewContainer: UIView!
    @IBOutlet weak var createNewButton: VLMenuButton!
    @IBOutlet weak var createNewButtonLable: UILabel!
    @IBOutlet weak var projectContainer: UIView!
    @IBOutlet weak var dimmedView: UIImageView!

    @IBOutlet weak var projectEditContainer: UIView!
    @IBOutlet weak var projectSelectAllButton: VLButton!
    @IBOutlet weak var projectDeleteButton: VLButton!
    @IBOutlet weak var projectSelectedProjectCountLabel: UILabel!
    
    @IBOutlet weak var startGuideView: UIView!
    
    
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint! {
        didSet {
            self.headerViewHeight.constant = maxHeight
        }
    }
    
    @IBOutlet weak var bannerPageControl: UIPageControl!
    
    public var inputTextView: VLInputTextView?

    /// State
    ///
    enum State {
        
        case normal
        case popup
        case edit
        case disappear
    }
    public var state: State = .normal
    
    /// ViewDidLoad
    ///
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Research
        //
        Research.launchApp()
        
        // Localized
        //
        self.myProjectsButton.setTitle("My Projects".localized(), for: .normal)
        self.projectSelectAllButton.setTitle("Select All".localized(), for: .normal)
        self.projectSelectAllButton.setTitle("Deselect All".localized(), for: .selected)
        self.projectSelectAllButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.projectDeleteButton.setTitle("Delete".localized(), for: .normal)
        self.projectDeleteButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.projectSelectButton.setTitle("Select".localized(), for: .normal)
        self.projectSelectButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.createNewButtonLable.text = "New Project".localized()
        

        // 여기서 미리 PHAsset을 로드한다.
        //
        PHPhotoHelper.sharedInstance.load { (complete) in }
        
        // Navigation Controller 속성
        //  -> Swipe로 화면 전환 방지
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.navigationBar.isUserInteractionEnabled = false
        self.createNewButton.layer.cornerRadius = 10
        
        // Top buttons
        //
        self.settingButton.imageView?.contentMode = .scaleAspectFit
        self.storeButton.imageView?.contentMode = .scaleAspectFit

        // Initial Banner Page
        self.bannerPageControl.numberOfPages = VLBannerViewController.bannerList.count
        self.bannerPageControl.currentPage = 0
        
        // When app became foreground, recalculate Sticky Header
        //
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground(_:)), name: NSNotification.Name(VLNotification.VLLO_Enter_Foreground.rawValue), object: nil)
        
        // Unlike the tag, sort type always need to save
        // When user restart app, app show recent sort type
        //
        if UserDefaults.standard.object(forKey: VLProjectManager.Key_Sort) == nil {
            // Key not exists
            // Set default sort type ["opened", "desc"]
            UserDefaults.standard.set(self.currentSortingType.toStringList(), forKey: VLProjectManager.Key_Sort)
        }
        
        // Get project image scale option user selected
        //
        if UserDefaults.standard.object(forKey: VLProjectManager.Key_ProjectScale) == nil {
            UserDefaults.standard.set(UIView.ContentMode.scaleAspectFill.rawValue, forKey: VLProjectManager.Key_ProjectScale)
        }
        
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//
//        switch segue.identifier {
//        case "project" :
//            self.projectSelectViewController = segue.destination as? VLProjectSelectViewController
//            self.projectSelectViewController.delegate = self
//        case "banner" :
//            self.bannerViewController = segue.destination as? VLBannerViewController
//            self.bannerViewController.delegate = self
//        default: break
//        }
//    }
    
    /// 화면에 곧 등장하기 직전에 불린다.
    ///
    /// - Parameter animated: 애니매이션 여부
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        print("??? start viewWillAppear")
        
        initCollectionView()

        // 모든 Resource를 해제한다.
        //
        VLAssetSourcePool.sharedInstance.clear()
        
        // Set tagType .all
        // When user return VLStartViewController, tag set default value (.all)
        //
        self.currentTagType = .all
        
        // Read and Set recent sort type
        let sort = UserDefaults.standard.array(forKey: VLProjectManager.Key_Sort) as? [String] ?? []
        self.currentSortingType = .sortType(standard: SortStandard(rawValue: sort[0]) ?? .opened, direction: SortDirection(rawValue: sort[1]) ?? .desc)
        
        // Set sort button's image
        self.updateProjectSortButton()
        
        // Get project image scale option user selected
        //
        if UserDefaults.standard.object(forKey: VLProjectManager.Key_ProjectScale) == nil {
            UserDefaults.standard.set(UIView.ContentMode.scaleAspectFill.rawValue, forKey: VLProjectManager.Key_ProjectScale)
        }
        // Read and Set recent project image scale type
        let imageScale = UIView.ContentMode.init(rawValue: UserDefaults.standard.integer(forKey: VLProjectManager.Key_ProjectScale)) ?? .scaleAspectFill
        self.projectSelectViewController.imageViewScale = imageScale
        // Set image scale button's image
        imageScale == .scaleAspectFit ? self.projectImageScaleButton.setImage(UIImage(named: "main_icon_fill"), for: .normal) : self.projectImageScaleButton.setImage(UIImage(named: "main_icon_fit"), for: .normal)
        
        // Reload
        //
//        self.reloadProjectUI()
//        self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType))
//        self.projectSelectViewController.collectionView.contentOffset = .zero
        
        // 화면 꺼짐 방지 차단
        //
        UIApplication.shared.isIdleTimerDisabled = true
        
        // To change projectSelectViewController's collectionview's Y position, we will change contentInset value.
        // First, Y position is maxHeight...
        self.projectSelectViewController.collectionView.contentInset = UIEdgeInsets(top: maxHeight, left: 0, bottom: 0, right: 0)
        self.projectSelectViewController.collectionView.contentOffset.y = -maxHeight
    }
    
    /// 화면 등장
    ///
    /// - Parameter animated: 애니매이션 여부
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        self.state = .normal
        
        // Firebase에 Main 화면이 보임을 표시한다.
        //
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: "Main"])
        
        // If user hasn't purchased premium, show store attract view controller for purchashing
        //
        let showType = VLStoreAttractViewController.getShowType()
        switch showType {
        case .full:
            let storeAttractViewController = VLViewControllerManager.create(storyboard: "Store", identifier: "store_attract")
            let navController = UINavigationController(rootViewController: storeAttractViewController)
            navController.modalPresentationStyle = .overCurrentContext
            navController.setNavigationBarHidden(true, animated: false)
            VLViewControllerManager.present(navController, animated: true, completion: nil)
            
        case .one_page:
            let storeAttractViewController = VLViewControllerManager.create(storyboard: "Store", identifier: "store_attract2") as! VLStoreAttractViewController
            storeAttractViewController.isRandomDisplay = true
            let navController = UINavigationController(rootViewController: storeAttractViewController)
            navController.modalPresentationStyle = .overCurrentContext
            navController.setNavigationBarHidden(true, animated: false)
            VLViewControllerManager.present(navController, animated: true, completion: nil)
            
        case .store:
            let storeViewController = VLViewControllerManager.create(storyboard: "Store", identifier: "store") as! VLStoreViewController
            storeViewController.entryPoint = "main_auto_store"
            storeViewController.modalPresentationStyle = .overFullScreen
            self.navigationController?.present(storeViewController, animated: true) {
                VLStoreAttractViewController.saveHistory()
            }
            
        default:
            break
        }
    }
    
    /// 화면에서 곧 사라짐
    ///
    /// - Parameter animated: 애니매이션 여부
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        initCollectionView()
    }
    
    /// 화면에서 완전히 사라짐
    ///
    /// - Parameter animated: 애니매이션 여부
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.state = .disappear

        
        // Remove Observer
        //
        NotificationCenter.default.removeObserver(self)
        
        
        // delete all items
        deinitCollectionView()
    }
    
    /// Create a video button pressed
    ///
    @IBAction open func makeVideoButtonPressed(_ sender: Any) {
        
        // Create new project
        //
        self.project = VLProject()
        
        // Asset 선택 화면으로 진입한다.
        //
        self.selectAssets()
    }
    
    /// Project select  button pressed
    /// - Parameter sender: project Select Button
    @IBAction func projectSelectButtonPressed(_ sender: Any) {
        if self.state == .edit {
            // Enter Normal Mode
            self.state = .normal
            self.projectSelectButton.isSelected = false
            self.projectSelectViewController.showEditButton = true
            self.projectSelectViewController.showSelectButton = false
            self.projectSelectButton.setTitle("Select".localized(), for: .normal)

            self.myProjectsButton.isEnabled = true
            self.myProjectsButton.imageView?.isHidden = false

            UIView.animate(withDuration: 0.3) {
                
                self.topContainer.isHidden = false
                self.topContainer.alpha = 1
                self.bannerMenu.isHidden = false
                self.bannerMenu.alpha = 1
                
                // 배너뷰가 스크롤에 따라 사라짐에 따라 collectionView의 높이 조정이 필요
                //
                self.projectSelectViewController.collectionView.contentInset = UIEdgeInsets(top: self.maxHeight, left: 0, bottom: 0, right: 0)
                self.projectSelectViewController.collectionView.contentOffset.y = -self.maxHeight

                self.headerViewHeight.constant = self.maxHeight
                
                self.dimmedView.isHidden = false
                self.dimmedView.alpha = 1
                self.createNewContainer.isHidden = false
                self.createNewContainer.alpha = 1
                self.projectSortButton.isHidden = false
                self.projectSortButton.alpha = 1
                self.projectImageScaleButton.isHidden = false
                self.projectImageScaleButton.alpha = 1
                
                self.projectEditContainer.isHidden = true
                self.projectSelectViewController.state = .normal
            }
            
            // Deselect all
            //
            if let selectedItemIndexPath = self.projectSelectViewController.collectionView.indexPathsForSelectedItems {
                for indexPath in selectedItemIndexPath {
                    self.projectSelectViewController.collectionView.deselectItem(at: indexPath, animated: true)
                }
            }

            
        } else if self.state == .normal {
            // Enter Edit Mode
            self.state = .edit
            self.projectSelectButton.isSelected = true
            self.projectSelectButton.isSelected = true
            self.projectSelectButton.setTitle("Cancel".localized(), for: .normal)
            self.projectSelectedProjectCountLabel.text = "( 0 )"

            self.myProjectsButton.isEnabled = false
            self.myProjectsButton.imageView?.isHidden = true

            self.projectSelectViewController.showEditButton = false
            self.projectSelectViewController.showSelectButton = true
            self.projectSelectAllButton.isSelected = false
            self.projectDeleteButton.isEnabled = false
            self.projectDeleteButton.alpha = VLConfiguration.DimAlpha

            
            
            UIView.animate(withDuration: 0.3) {
                
                self.topContainer.isHidden = true
                self.topContainer.alpha = 0
                self.bannerMenu.isHidden = true
                self.bannerMenu.alpha = 0
                
                // 배너뷰가 스크롤되며 사라짐에 따라 collectionView의 높이 조정이 필요
                // Sticky Header Height - Top Container Height
                self.projectSelectViewController.collectionView.contentInset = UIEdgeInsets(top: Self.MinimumSelectCollectionViewSpacingFromTop, left: 0, bottom: 0, right: 0)

                self.projectSelectViewController.collectionView.contentOffset.y = -Self.MinimumSelectCollectionViewSpacingFromTop
                self.headerViewHeight.constant = self.minHeight

                self.dimmedView.isHidden = true
                self.dimmedView.alpha = 0
                self.createNewContainer.isHidden = true
                self.createNewContainer.alpha = 0
                self.projectSortButton.isHidden = true
                self.projectSortButton.alpha = 0
                self.projectImageScaleButton.isHidden = true
                self.projectImageScaleButton.alpha = 0
                
                self.projectEditContainer.isHidden = false
                self.projectSelectViewController.state = .select
            }
        }
    }
    
    /// Pressed myProjects Button
    /// show dropdown list by PopUpContent
    /// - Parameter sender: myProjects button
    @IBAction func myProjectsButtonPressed(_ sender: Any) {
        
        // Show popup to sort project option.
        //
        let popupViewController = VLViewControllerManager.create(storyboard: "PopUp", identifier: "popup") as! PopUpViewController
        popupViewController.modalPresentationStyle = .overFullScreen
        popupViewController.title = Self.PopUpKey_ProjectEntireOption
        
        // TagPopUp need runtime change, so can't set static array
        popupViewController.contentList = PopUpConfig().TagPopUp
        
        popupViewController.delegate = self
        
        self.state = .popup
        self.present(popupViewController, animated: false, completion: nil)
        
    }
    
    /// Select all projects
    ///
    /// - Parameter sender: Select all button
    @IBAction func selectAllButtonPressed(_ sender: Any) {
        
        if self.projectSelectAllButton.isSelected {
            
            if let indexPathList = self.projectSelectViewController.collectionView.indexPathsForSelectedItems {
                for indexPath in indexPathList {
                    self.projectSelectViewController.collectionView.deselectItem(at: indexPath, animated: true)
                }
            }
            
        } else {
            
            for i in 0..<VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType).count {
                self.projectSelectViewController.collectionView.selectItem(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            }
        }
        
        self.updateProjectEditButtons()
    }
    
    /// Delete Project
    ///
    /// - Parameter sender: Delete button
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        guard let items = self.projectSelectViewController.collectionView.indexPathsForSelectedItems else {
            return
        }
        
        let alertViewController = VLAlertViewController.title("Delete Project".localized(),
                                                              message: "Are you sure you want to delete the selected projects?".localized(),
                                                              others: ["Delete".localized(), "Cancel".localized()],
                                                              delegate: self)
        VLViewControllerManager.present(alertViewController, animated: false, completion: nil)
        
        self.indexPathList = items
    }
    
    /// Setting
    ///
    @IBAction open func settingButtonPressed(_ sender: Any) {
        
        let viewController = VLViewControllerManager.create(storyboard: "Setting", identifier: "setting") as! VLSettingViewController
        let navController = UINavigationController(rootViewController: viewController)
        navController.setNavigationBarHidden(true, animated: false)
        navController.modalPresentationStyle = .fullScreen
        VLViewControllerManager.present(navController, animated: true, completion: nil)
    }
    
    /// Store
    ///
    @IBAction open func storeButtonPressed(_ sender: Any) {
        
        let storeViewController = VLViewControllerManager.create(storyboard: "Store", identifier: "store") as! VLStoreViewController
        storeViewController.entryPoint = "main"
        storeViewController.modalPresentationStyle = .overFullScreen
        VLViewControllerManager.present(storeViewController, animated: true, completion: nil)
    }
    
    /// Pressed image scale button
    /// Switch Project's ImageView ScaleType between Aspect Fit and Aspect Fill
    /// - Parameter sender: Switch Image Scale Button
    @IBAction func switchProjectImageScaleButtonPressed(_ sender: Any) {
        
        let scale = UserDefaults.standard.integer(forKey: VLProjectManager.Key_ProjectScale)
        
        // 현재 저장된 image Scale에 따라서 scale 이미지 세팅 및 새로 저장
        switch scale {
        case UIView.ContentMode.scaleAspectFill.rawValue:
            self.projectImageScaleButton.setImage(UIImage(named: "main_icon_fill"), for: .normal)
            self.projectSelectViewController.imageViewScale = .scaleAspectFit
            // Save current sort type
            UserDefaults.standard.set(UIView.ContentMode.scaleAspectFit.rawValue, forKey: VLProjectManager.Key_ProjectScale)
        case UIView.ContentMode.scaleAspectFit.rawValue:
            self.projectImageScaleButton.setImage(UIImage(named: "main_icon_fit"), for: .normal)
            self.projectSelectViewController.imageViewScale = .scaleAspectFill
            // Save current sort type
            UserDefaults.standard.set(UIView.ContentMode.scaleAspectFill.rawValue, forKey: VLProjectManager.Key_ProjectScale)
        default: break
        }
        
        UserDefaults.standard.synchronize()
        self.projectImageScaleButton.isSelected.toggle()
    }
    
    /// Pressed sort button
    /// - Parameter sender: sort button
    @IBAction func sortButtonPressed(_ sender: Any) {
        
        // Show popup to sort project option.
        //
        let popupViewController = VLViewControllerManager.create(storyboard: "PopUp", identifier: "popup") as! PopUpViewController
        popupViewController.modalPresentationStyle = .overFullScreen
        popupViewController.title = Self.PopUpKey_ProjectSort
        popupViewController.contentList = PopUpConfig.SortPopUp
        
        popupViewController.popUpStyle = .selected(self.currentSortingType)
        popupViewController.delegate = self
        
        self.state = .popup
        self.present(popupViewController, animated: false, completion: nil)

    }
    
    /// Project를 다시 로드한다.
    ///
    public func reloadProjectList(projectList: [VLProject]) {
        
        self.projectSelectViewController.projectList = projectList
        
        // Layout 업데이트
        //  -> 편집 이후 다시 main으로 돌아 올때 화면 갱신이 바로 안되는 경우가 있음.
//        self.view.layoutIfNeeded()
        
        // Project 갱신
        //
        self.projectSelectViewController.collectionView.reloadData()
    }
    
    /// Project UI를 갱신한다.
    ///
    public func reloadProjectUI() {
        
        if VLProjectManager.sharedInstance.getActiveProjectCount() > 0 {
            
            self.projectContainer.isHidden = false
            self.startGuideView.isHidden = true
        } else {
            
            self.projectContainer.isHidden = true
            self.startGuideView.isHidden = false
        }
    }
    
    /// Project를 로드 한다.
    ///
    public func loadProject(_ project: VLProject) {
        
        // Clear projects imported in inbox folder.
        //
        VLFileHelper.sharedInstance.clearInboxFolder()
        
        // Load asset
        //
        let viewController = VLViewControllerManager.create(storyboard: "Asset", identifier: "load") as! VLAssetLoadViewController
        viewController.delegate = self
        viewController.savePath = project.assetPath
        self.navigationController?.pushViewController(viewController, animated: true)
        
        // Load the project
        //
        VLUtil.event(enabled: false)
        DispatchQueue.global(qos: .default).async {
            
            // Project가 heavy한 경우 멈추는 현상이 발생할 수 있음으로 background에서 로드한다.
            //
            let result = VLProjectManager.sharedInstance.load(project)
            DispatchQueue.main.async {
                
                VLUtil.event(enabled: true)
                
                if result {
                    
                    self.project = project
                    viewController.assetList = project.allAssetVisualList()
                    viewController.load()
                    
                } else {
                    
                    self.navigationController?.popViewController(animated: true)
                    
                    let viewController = VLAlertViewController.title("Not available".localized(),
                                                                     message: "This project doesn't support any more".localized(),
                                                                     others: [],
                                                                     delegate: nil)
                    viewController.modalPresentationStyle = .overFullScreen
                    VLViewControllerManager.present(viewController, animated: false, completion: nil)
                }
            }
        }
    }
    
    /// VisualClip을 구성한다.
    ///
    fileprivate func selectAssets() {
        
        let viewController = VLViewControllerManager.create(storyboard: "Asset", identifier: "select") as! VLAssetSelectViewController
        viewController.delegate = self
        viewController.canMultiSelect = true
        viewController.assetType = nil
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// 프로젝트를 구성한다.
    ///
    /// - Parameter assetList: AssetWrapper list
    fileprivate func projectSetting(assetList: [VLAssetWrapper]) {
        
        // Exception
        //
        guard let project = self.project,
              !assetList.isEmpty else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        self.assetList = assetList
        
        // 세부 프로젝트 설정하기 위한 화면으로 진입한다.
        //
        let viewController = VLViewControllerManager.create(storyboard: "Project", identifier: "project_setting") as! VLProjectSettingViewController
        viewController.projectTitle = self.project?.title
        viewController.showCreateNewButton = true
        viewController.delegate = self
        viewController.originalSceneSize = assetList[0].convertAssetVisual(assetPath: project.assetPath).first?.getSize() ?? .zero
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Project
    ///
    fileprivate weak var projectSelectViewController: VLProjectSelectViewController!
    fileprivate var project: VLProject?
    fileprivate var assetList: [VLAssetWrapper]?
    fileprivate var indexPathList: [IndexPath]?
    
    /// Premium controller
    ///
    fileprivate let premiumController = VLPremiumUIController(product: .Everything)
    
    /// Share a project with us
    ///
    fileprivate var sendToVimoServer = false
    
    /// PopUp Key
    ///
    static fileprivate let PopUpKey_ProjectEntireOption     = "project_entire_option"
    static fileprivate let PopUpKey_ProjectOption           = "project_option"
    static fileprivate let PopUpKey_ProjectSort             = "project_sort"
    
    /// Banner
    fileprivate weak var bannerViewController: VLBannerViewController!
    
    /// Update Project edit button UI
    ///
    fileprivate func updateProjectEditButtons() {
        
        if let items = self.projectSelectViewController.collectionView.indexPathsForSelectedItems,
           items.count > 0 {
            
            self.projectDeleteButton.isEnabled = true
            self.projectDeleteButton.alpha = 1
            self.projectSelectedProjectCountLabel.textColor = UIColor(named: "Text")
            self.projectSelectedProjectCountLabel.text = " ( \(items.count) )"
        } else {
            
            self.projectDeleteButton.isEnabled = false
            self.projectDeleteButton.alpha = VLConfiguration.DimAlpha
            self.projectSelectedProjectCountLabel.textColor = UIColor(named: "Text_Dark")
            self.projectSelectedProjectCountLabel.text = " ( 0 )"
        }
        
        if self.projectSelectViewController.collectionView.indexPathsForSelectedItems?.count == VLProjectManager.sharedInstance.getActiveProjectCount() {
            
            self.projectSelectAllButton.isSelected = true
        } else {
            
            self.projectSelectAllButton.isSelected = false
        }
    }
    
    /// Update Project Sort Button UI
    ///
    fileprivate func updateProjectSortButton() {
        switch self.currentSortingType {
        case .sortType(let standard, let direction):
            // change sortButton image depending on sort direction (align up or down)
            self.projectSortButton.setImage(direction == .desc ? UIImage(named: "main_icon_align_down") : UIImage(named: "main_icon_align_up"), for: .normal)

            // change projectCell's dateLabel depending on sort type
            self.projectSelectViewController.showCreatedDate = standard == .create ? true : false
        
        }
        // Save current sort type
        UserDefaults.standard.set(self.currentSortingType.toStringList(), forKey: VLProjectManager.Key_Sort)
        UserDefaults.standard.synchronize()
    }
    
    /// When app became foreground, recalculate Sticky Header
    /// - Parameter notification: VLNotification
    @objc func didEnterForeground(_ notification: Notification) {
        // Check App State whether edit or normal
        if self.state == .edit {
            // if self.state is edit, set Sticky Header to Top Position
            self.projectSelectViewController.collectionView.contentInset = UIEdgeInsets(top: Self.MinimumSelectCollectionViewSpacingFromTop, left: 0, bottom: 0, right: 0)

            self.projectSelectViewController.collectionView.contentOffset.y = -Self.MinimumSelectCollectionViewSpacingFromTop
            self.headerViewHeight.constant = self.minHeight
            
            // hide drop down image in edit mode
            self.myProjectsButton.imageView?.isHidden = true
        } else {
            // if self.state is NOT edit, set Sticky Header to MaxHeight
            self.projectSelectViewController.collectionView.contentInset = UIEdgeInsets(top: maxHeight, left: 0, bottom: 0, right: 0)
            self.projectSelectViewController.collectionView.contentOffset.y = -maxHeight
            self.myProjectsButton.imageView?.isHidden = false
        }
    }
    
    private func deinitCollectionView() {
        
        print("??? deinit collectionview")
        self.bannerViewController.willMove(toParent: nil)
        self.bannerViewController.bannerCollectionView.removeFromSuperview()
        
        self.projectSelectViewController.willMove(toParent: nil)
        self.projectSelectViewController.collectionView.removeFromSuperview()
        
        self.bannerViewController = nil
        self.projectSelectViewController = nil
        
    }
    
    private func initCollectionView() {
        print("??? init collectionview")
        let mainStoryboard = UIStoryboard(name: "Main", bundle: .main)
        bannerViewController = mainStoryboard.instantiateViewController(withIdentifier: "banner") as? VLBannerViewController
        // Add the view controller to the container.
        self.addChild(bannerViewController)
        self.bannerContainer.addSubview(bannerViewController.view)
        
        // Create and activate the constraints for the child’s view.
        NSLayoutConstraint.activate([
            
            bannerViewController.view.topAnchor.constraint(equalTo: self.bannerContainer.topAnchor),
            bannerViewController.view.bottomAnchor.constraint(equalTo: self.bannerContainer.bottomAnchor),
            bannerViewController.view.leadingAnchor.constraint(equalTo: self.bannerContainer.leadingAnchor),
            bannerViewController.view.trailingAnchor.constraint(equalTo: self.bannerContainer.trailingAnchor),
        ])
        
        // Notify the child view controller that the move is complete.
        bannerViewController.didMove(toParent: self)
        
        let selectStoryboard = UIStoryboard(name: "Select", bundle: .main)
        projectSelectViewController = selectStoryboard.instantiateViewController(withIdentifier: "project") as? VLProjectSelectViewController
        
        projectSelectViewController.projectList = VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType)
        
        print("??? \(projectSelectViewController.projectList)")
        
        self.addChild(projectSelectViewController)
        self.projectContainer.addSubview(projectSelectViewController.view)
        
        // Create and activate the constraints for the child’s view.
        NSLayoutConstraint.activate([
            
            projectSelectViewController.view.topAnchor.constraint(equalTo: self.projectContainer.topAnchor),
            projectSelectViewController.view.bottomAnchor.constraint(equalTo: self.projectContainer.bottomAnchor),
            projectSelectViewController.view.leadingAnchor.constraint(equalTo: self.projectContainer.leadingAnchor),
            projectSelectViewController.view.trailingAnchor.constraint(equalTo: self.projectContainer.trailingAnchor),
        ])
        
        // Notify the child view controller that the move is complete.
        projectSelectViewController.didMove(toParent: self)
    }
    
}

// MARK: - VLPortProjectViewControllerDelegate
extension VLStartViewController: VLPortProjectViewControllerDelegate {
    
    /// Complete export a project
    ///
    /// - Parameters:
    ///   - viewController: VLExportProjectViewController
    ///   - outputURL: Output URL
    func portProjectViewControllerExportDone(_ viewController: VLPortProjectViewController, outputURL: URL) {
        
        if self.sendToVimoServer {
            
            viewController.sendProjectToVimoServer(projectURL: outputURL)
            
        } else {
            VLViewControllerManager.dismiss(animated: false) {
                
                let activityViewController = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.height, width: 0, height: 0)
                activityViewController.popoverPresentationController?.permittedArrowDirections = .down
                VLViewControllerManager.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    /// Complete to import a project
    ///
    /// - Parameters:
    ///   - viewController: VLExportProjectViewController
    ///   - outputURL: Output URL
    func portProjectViewControllerImportDone(_ viewController: VLPortProjectViewController, inputURL: URL) {
        
    }
    
    /// Complete to send a project
    ///
    /// - Parameters:
    ///   - viewController: VLExportProjectViewController
    ///   - outputURL: Output URL
    func portProjectViewControllerSendDone(_ viewController: VLPortProjectViewController) {
        
        VLViewControllerManager.dismiss(animated: false, completion: nil)
    }
}

// MARK:- AssetSelectViewControllerDelegate
extension VLStartViewController: VLAssetSelectViewControllerDelegate {
    
    /// 최종적으로 선택된 VisualClipList를 전달한다.
    ///
    /// - Parameter sourceSelectViewController: AssetSelectViewController
    /// - Parameter selectedAssetList: 선택된 Source List
    func assetSelectViewController(_ assetSelectViewController: VLAssetSelectViewController, selectedAssetList: [VLAssetWrapper]) {
        
        // Exception
        //
        if self.navigationController?.viewControllers.last is VLAssetLoadViewController {
            return
        }
        
        // Project를 구성한다.
        //
        self.projectSetting(assetList: selectedAssetList)
    }
    
    /// 취소
    ///
    /// - Parameter assetSelectViewController: AssetSelectViewController
    func assetSelectViewControllerCanceled(_ assetSelectViewController: VLAssetSelectViewController) {
        
        // 프로젝트 해제
        //
        self.project = nil
        
        // 밖으로 나간다.
        //
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK:- ProjectSettingViewControllerDelegate
extension VLStartViewController: VLProjectSettingViewControllerDelegate {
    
    func projectSettingViewController(_ viewController: VLProjectSettingViewController, done: Bool) {
        
        guard done,
              let project = self.project,
              let assetList = self.assetList else {
                  
                  self.navigationController?.popViewController(animated: true)
                  return
              }
        
        var assetVisualList: [VLAssetVisual] = []
        for asset in assetList {
            assetVisualList.append(contentsOf: asset.convertAssetVisual(assetPath: project.assetPath))
        }
        
        project.title = viewController.projectTitle ?? ""
        
        // Asset을 로드한다.
        //
        let viewController = VLViewControllerManager.create(storyboard: "Asset", identifier: "load") as! VLAssetLoadViewController
        viewController.delegate = self
        viewController.assetList = assetVisualList
        viewController.savePath = project.assetPath
        self.navigationController?.pushViewController(viewController, animated: true)
        viewController.load()
    }
}

// MARK: - SourceLoadViewControllerDelegate
extension VLStartViewController: VLProgressViewControllerDelegate {
    
    /// VLProgressViewController의 로드가 완료되면 호출된다.
    ///
    /// - Parameters:
    ///   - viewController: VLProgressViewController
    ///   - completed: 로드 완료 여부
    func progressViewController(_ viewController: VLProgressViewController, completed: Bool) {
        
        // 연타 방지를 위한 연결 해제
        //
        viewController.delegate = nil
        
        // 로드에 실패한 경우 밖으로 나간다.
        //
        guard completed,
              let project = self.project else {
                  
                  self.navigationController?.popViewController(animated: true)
                  self.assetList = nil
                  return
              }
        
        // Project에 선택되었던 asset 추가
        //
        if let assetList = self.assetList {
            
            // AssetWrapper로 VisualClip을 생성한다.
            //
            for assetWrapper in assetList {
                
                if let insertedProject = assetWrapper.getProject() {
                    
                    // VisualClip은 반드시 복사해서 추가한다.
                    // 사용자가 프로젝트를 2번 이상 선택할 경우 동일한 VisualClip이 추가될 수 있기 때문이다.
                    var visualClipList = [VLVisualClip]()
                    for visualClip in insertedProject.getVisualClipList() {
                        
                        let duplicated = visualClip.duplicate() as! VLVisualClip
                        visualClipList.append(duplicated)
                    }
                    project.add(visualClipList: visualClipList, index: project.getVisualClipCount(), recompose: true)
                    
                    if let shiftTime = visualClipList.first?.displayTimeRange.start {
                        
                        for deco in insertedProject.getAllDecosInLayers() {
                            
                            let duplicated = deco.duplicate()
                            duplicated.displayTimeRange = CMTimeRange(start: duplicated.displayTimeRange.start + shiftTime, duration: duplicated.displayTimeRange.duration)
                            project.add(deco: duplicated)
                        }
                    }
                    
                } else if let visualAsset = assetWrapper.convertAssetVisual(assetPath: project.assetPath).first {
                    
                    let visualClip = VLVisualClip(asset: visualAsset)
                    visualClip.bgInfo = BGInfo(colorInfo: ColorInfo(rgb: 0))
                    project.applyContentMode(visualClipList: [visualClip], contentMode: VLProjectConfiguration.contentMode)
                    project.add(visualClipList: [visualClip], index: project.getVisualClipCount(), recompose: false)
                }
            }
            
            // VisualClip의 layout을 설정한다.
            //
            project.aspectRatioType = VLProjectConfiguration.aspectRatio
            
            // 초기화
            //
            self.assetList = nil
        }
        
        // 메인 편집기로 진입
        //
        let viewController = VLViewControllerManager.create(storyboard: "Edit", identifier: "video_edit") as! VLVideoEditViewController
        viewController.project = project
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - VLProjectSelectViewControllerDelegate
extension VLStartViewController: VLProjectSelectViewControllerDelegate {
    
    /// Called when user select the project to edit
    ///
    /// - Parameters:
    ///   - viewController: VLProjectSelectViewController
    ///   - project: Project
    func projectSelectViewController(_ viewController: VLProjectSelectViewController, cell: ProjectCollectionViewCell, selected project: VLProject, index: IndexPath) {
        switch viewController.state {
        case .normal:
            if self.state == .normal {
                self.loadProject(project)
            }
            
        case .select:
            if self.state == .edit {
                self.updateProjectEditButtons()
            }
        }
    }
    
    /// Called when user deselect the project to edit
    ///
    /// - Parameters:
    ///   - viewController: VLProjectSelectViewController
    ///   - cell: Project Cell
    ///   - project: Project
    ///   - index: Index path
    func projectSelectViewController(_ viewController: VLProjectSelectViewController, cell: ProjectCollectionViewCell, deselected project: VLProject, index: IndexPath) {
        
        self.updateProjectEditButtons()
    }
    
    /// Called when user select the project to edit
    ///
    /// - Parameters:
    ///   - viewController: VLProjectSelectViewController
    ///   - project: Project
    func projectSelectViewController(_ viewController: VLProjectSelectViewController, longpressed project: VLProject) {
        
        if self.state != .normal {
            return
        }
        
        let viewController = VLViewControllerManager.create(storyboard: "Main", identifier: "port_project") as! VLPortProjectViewController
        viewController.delegate = self
        self.sendToVimoServer = true
        VLViewControllerManager.present(viewController, animated: false) {
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
            let projectName = formatter.string(from: Date()) + "_" + project.title
            
            let url = URL(fileURLWithPath: NSTemporaryDirectory() + "\(projectName).\(VLProjectPorter.PATH_PROJECT_EXTENSION)")
            viewController.exportProject(project: project, outputURL: url)
        }
    }
    
    /// Called when user edit project proerty
    ///
    /// - Parameter viewController: VLProjectSelectViewController
    /// - Parameter project: Project edited
    /// - Parameter indexPath: IndexPath
    func projectSelectViewController(_ viewController: VLProjectSelectViewController, edit project: VLProject, indexPath: IndexPath) {
        
        if self.state != .normal {
            return
        }
        
        self.project = project
        self.indexPathList = [indexPath]
        
        // Show popup to select project option.
        //
        let popupViewController = VLViewControllerManager.create(storyboard: "PopUp", identifier: "popup") as! PopUpViewController
        popupViewController.modalPresentationStyle = .overFullScreen
        popupViewController.title = Self.PopUpKey_ProjectOption
    
        // Set PopUp Contents
        //
        popupViewController.tagList = PopUpConfig.ProjectCellTagPopUp
        popupViewController.contentList = PopUpConfig.ProjectCellPopUp
        popupViewController.delegate = self
        
        self.state = .popup
        self.present(popupViewController, animated: false, completion: { popupViewController.selectedTagButton(tag: project.tag) })
    }
    
    /// Called when user scroll collectionView vertically
    /// - Parameters:
    ///   - viewController: VLProjectSelectViewController
    ///   - scrollView: UIScrollView
    func projectSelectViewController(_ viewController: VLProjectSelectViewController, scrollView: UIScrollView) {
        // Set Vertical Scroll for Main Sticky Header (Hiding Banner)
        if scrollView.contentOffset.y < 0 {
            if self.state == .edit {
                // 선택 화면에서는 배너 없이 stickyheader 가 상단에 붙은 화면
                self.headerViewHeight.constant = Self.StickyHeaderHeight
                return
            }
            // 아래로 스크롤하면 배너가 점차 사라진다.
            self.headerViewHeight.constant = max(abs(scrollView.contentOffset.y), Self.StickyHeaderHeight)

        } else {
            self.headerViewHeight.constant = Self.StickyHeaderHeight
        }
            
        
    }
}

// MARK: - VLAlertViewControllerDelegate
extension VLStartViewController: VLAlertViewControllerDelegate {
    
    /// Call when user select the index
    ///
    func alertViewController(_ viewController: VLAlertViewController, selected index: Int) {
        
        // 프로젝트 삭제
        //
        if index == 0 {
            
            var projectList: [VLProject] = []
            for indexPath in self.indexPathList! {
                
                let project = self.projectSelectViewController.projectList[indexPath.row]
                projectList.append(project)
            }
            do {
                try VLProjectManager.sharedInstance.remove(projectList: projectList)
                self.projectSelectViewController.projectList = self.projectSelectViewController.projectList.filter({ project in
                    !projectList.contains(project)
                })
                self.projectSelectViewController.collectionView.deleteItems(at: self.indexPathList!)
                
            } catch {
                print(#function)
                print(error)
            }
            
            self.project = nil
            self.indexPathList = nil
            self.reloadProjectUI()
            
            // 해당 프로젝트가 삭제되면 PopUp을 내린다.
            //
            if let popupViewController = viewController.data as? PopUpViewController {
                popupViewController.dismiss()
            }
            
            // 선택 모드에서 모든 프로젝트가 삭제되면, 선택 모드에서 나온다.
            // If deleted all projects in select mode, exit it.
            if self.projectSelectButton.isSelected{
                if VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType).count <= 0 {
                    self.projectSelectButtonPressed(self.projectSelectButton as Any)
                }
            }
            
            // 특정 태그를 선택한 상황에서 프로젝트를 지웠는데, 해당 태그에 맞는 프로젝트가 더이상 없는 경우, 모든 프로젝트로 이동
            //
            if !VLProjectManager.sharedInstance.getSelectedTagList().contains(self.currentTagType.rawValue) {
                self.currentTagType = .all
                self.myProjectsButton.setTitle("My Projects".localized(), for: .normal)
                self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .all, sortType: self.currentSortingType))
            }
        }
    }
}

// MARK: - PopUpViewControllerDelegate
extension VLStartViewController: PopUpViewControllerDelegate {
    
    /// Call when user select tag icon in  ProjectCell's option
    /// - Parameters:
    ///   - viewController: PopUpViewController
    ///   - content: PopUpViewController.PopUpTagIcon
    func popUpViewController(_ viewController: PopUpViewController, selected content: PopUpViewController.PopUpTagIcon) {
        self.state = .normal
        
        guard let tagMenu = TagMenu(rawValue: content.identifier) else {
            return
        }
        
        guard let indexPath = self.indexPathList?.first else {return}
        guard let cell = self.projectSelectViewController.collectionView.cellForItem(at: indexPath) as? ProjectCollectionViewCell else { return }
        
        switch tagMenu {
        case .empty:
            cell.project?.tag = 0
            cell.tagImageView.tintColor = UIColor(named: "Text")
        case .red:
            cell.project?.tag = 1
            cell.tagImageView.tintColor = UIColor(named: "Tag_Red")
        case .yellow:
            cell.project?.tag = 2
            cell.tagImageView.tintColor = UIColor(named: "Tag_Yellow")
        case .green:
            cell.project?.tag = 3
            cell.tagImageView.tintColor = UIColor(named: "Tag_Green")
        case .blue:
            cell.project?.tag = 4
            cell.tagImageView.tintColor = UIColor(named: "Tag_Blue")
        case .purple:
            cell.project?.tag = 5
            cell.tagImageView.tintColor = UIColor(named: "Tag_Purple")
        }
        
        // Set changed Tag
        VLProjectManager.sharedInstance.changeTag(project: cell.project!)

        // This is needed when change tag of filtered project by tag
        self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType))

        viewController.dismiss()
    }
    
    
    /// Call when user select a popup
    ///
    /// - Parameters:
    ///   - viewController: PopUpViewController
    ///   - content: Selected Content
    func popUpViewController(_ viewController: PopUpViewController, selected content: PopUpViewController.PopUpContent) {
        
        self.state = .normal
        
        guard let popupMenu = PopupMenuInStart(rawValue: content.identifier) else {
            return
        }
        
        switch popupMenu {
        case .recycle_bin:
            
            viewController.dismiss() {
                
                let viewController = VLViewControllerManager.create(storyboard: "Project", identifier: "project_garbage") as! VLProjectGarbageViewController
                viewController.modalPresentationStyle = .fullScreen
                VLViewControllerManager.present(viewController, animated: true)
            }
            
        case .share_project:
            
            // If user has not purchared premium, go to the vllo store.
            //
            if !VLProductManager.sharedInstance.isAvailable(product: .Everything) {
                self.storeButtonPressed(self.storeButton as UIButton)
                return
            }
            
            guard let project = self.project else {
                return
            }
            
            let viewController = VLViewControllerManager.create(storyboard: "Main", identifier: "port_project") as! VLPortProjectViewController
            viewController.delegate = self
            self.sendToVimoServer = false
            VLViewControllerManager.present(viewController, animated: false) {
                
                let name = project.title.count > 0 ? project.title : "no_name"
                let url = URL(fileURLWithPath: NSTemporaryDirectory() + "\(name).\(VLProjectPorter.PATH_PROJECT_EXTENSION)")
                viewController.exportProject(project: project, outputURL: url)
            }
            
        case .rename:
            
            self.inputTextView = VLInputTextView.instanceFromNib()
            self.inputTextView?.delegate = self
            self.inputTextView?.startInputingText(superView: self.view, text: self.project?.title ?? "")
            
            viewController.dismiss()
            
        case .duplicate:
            
            guard let project = self.project else {
                return
            }
            
            // 프로젝트를 복사해서 제일 앞에 추가한다.
            //
            if let duplicatedProject = try? VLProjectManager.sharedInstance.duplicate(project: project) {
                
                self.projectSelectViewController.projectList.insert(duplicatedProject, at: 0)
                self.projectSelectViewController.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
            }
            
            viewController.dismiss()
            
        case .delete:
            
            let alertViewController = VLAlertViewController.title("Delete Project".localized(),
                                                                  message: "Are you sure you want to delete the selected projects?".localized(),
                                                                  others: ["Delete".localized(), "Cancel".localized()],
                                                                  delegate: self)
            VLViewControllerManager.present(alertViewController, animated: false, completion: nil)
            alertViewController.data = viewController
            
        case .all:
            self.myProjectsButton.setTitle("My Projects".localized(), for: .normal)
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .all, sortType: self.currentSortingType))
            self.currentTagType = .all
            viewController.dismiss()
        case .red:
            self.myProjectsButton.setTitle("Red".localized(), for: .normal)
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .red, sortType: self.currentSortingType))
            self.currentTagType = .red
            viewController.dismiss()
        case .yellow:
            self.myProjectsButton.setTitle("Yellow".localized(), for: .normal)
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .yellow, sortType: self.currentSortingType))
            self.currentTagType = .yellow
            viewController.dismiss()
        case .green:
            self.myProjectsButton.setTitle("Green".localized(), for: .normal)
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .green, sortType: self.currentSortingType))
            self.currentTagType = .green
            viewController.dismiss()
        case .blue:
            self.myProjectsButton.setTitle("Blue".localized(), for: .normal)
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .blue, sortType: self.currentSortingType))
            self.currentTagType = .blue
            viewController.dismiss()
        case .purple:
            self.myProjectsButton.setTitle("Purple".localized(), for: .normal)
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: .purple, sortType: self.currentSortingType))
            self.currentTagType = .purple
            viewController.dismiss()
            
        case .sort_name:
            switch self.currentSortingType {
            case .sortType(standard: .name, direction: .asc): self.currentSortingType = .sortType(standard: .name, direction: .desc)
            case .sortType(standard: .name, direction: .desc): self.currentSortingType = .sortType(standard: .name, direction: .asc)
            default: self.currentSortingType = .sortType(standard: .name, direction: .asc)
            }
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType))
            self.updateProjectSortButton()

            viewController.dismiss()
            
        case .sort_created:
            switch self.currentSortingType {
            case .sortType(standard: .create, direction: .asc): self.currentSortingType = .sortType(standard: .create, direction: .desc)
            case .sortType(standard: .create, direction: .desc): self.currentSortingType = .sortType(standard: .create, direction: .asc)
            default: self.currentSortingType = .sortType(standard: .create, direction: .desc)
            }
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType))
            self.updateProjectSortButton()

            viewController.dismiss()
            
        case .sort_lastOpen:
            switch self.currentSortingType {
            case .sortType(standard: .opened, direction: .asc): self.currentSortingType = .sortType(standard: .opened, direction: .desc)
            case .sortType(standard: .opened, direction: .desc): self.currentSortingType = .sortType(standard: .opened, direction: .asc)
            default: self.currentSortingType = .sortType(standard: .opened, direction: .desc)
            }
            self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType))
            self.updateProjectSortButton()

            viewController.dismiss()
        }
    }
    
    /// Call when user cancel
    ///
    /// - Parameter viewController: PopUpViewController
    func popUpViewControllerCanceled(_ viewController: PopUpViewController) {
  
        self.state = .normal
        viewController.dismiss()
        self.project = nil
        self.indexPathList = nil
    }
}


// MARK: - VLInputTextViewDelegate
extension VLStartViewController: VLInputTextViewDelegate {
    
    /// Call when text is inputting
    ///
    /// - Parameters:
    ///   - inputTextView: Input text view
    ///   - changedText:
    func inputTextViewInputting(_ inputTextView: VLInputTextView, text: String?) {
        
    }
    
    /// Call when text inputting is done.
    ///
    /// - Parameters:
    ///   - inputTextView: Input text view
    ///   - text: 입력된 최종 text
    func inputTextViewDone(_ inputTextView: VLInputTextView, text: String?) {
        
        guard let project = self.project,
              let indexPath = self.indexPathList?.first else {
            return
        }
        
        // Rename
        //
        project.title = text ?? ""
        VLProjectManager.sharedInstance.projectProvider.rename(project: project)
        self.projectSelectViewController.collectionView.reloadItems(at: [indexPath])
        self.reloadProjectList(projectList: VLProjectManager.sharedInstance.getTagSortedProjectList(tag: self.currentTagType, sortType: self.currentSortingType))
        
        // Done
        //
        self.project = nil
        self.indexPathList = nil
        inputTextView.finish()
    }
    
    /// Call when user canceled
    ///
    /// - Parameter inputTextView: Input text view
    func inputTextViewCanceled(_ inputTextView: VLInputTextView) {
        
        self.project = nil
        self.indexPathList = nil
        inputTextView.finish()
    }
}

// MARK: - VLBannerViewControllerDelegate
/// When Banner Scrolled, Notify pageControl to change the page value
extension VLStartViewController: VLBannerViewControllerDelegate {
    
    /// Called when banner index changed by scrolling banner
    ///
    func scrollPageTo(index: Int) {
        self.bannerPageControl.currentPage = index % VLBannerViewController.bannerList.count
    }
    
    /// Called when user click Banner
    /// - Parameters:
    ///   - viewController: VLBannerViewController
    ///   - banner: clicked Banner Item
    func clickBanner(_ viewController: VLBannerViewController, banner: VLBanner) {
        let bannerViewController = VLViewControllerManager.create(storyboard: "Main", identifier: "whats_new")
        (bannerViewController as! VLWhatsNewViewController).banner = banner
        (bannerViewController as! VLWhatsNewViewController).delegate = self

        VLViewControllerManager.present(bannerViewController, animated: true, completion: nil)
        
        viewController.stopTimer()
    }
    
    /// Called when iPad Screen size changed
    /// - Parameters:
    ///   - viewController: VLBannerViewController
    ///   - size: changed Banner Size
    func bannerSizeChanged(_ viewController: VLBannerViewController, size: CGSize) {
        
        if size.width < UIScreen.main.bounds.width {
            
            if size.width < VLMainBannerFlowLayout.BannerWidthInIPad  {
                // split인데 iPhone처럼 보이기
                self.maxHeight = Self.BannerHeightInIPhone
            } else {

                // split인데 iPad처럼 보이기
                self.maxHeight = VLMainBannerFlowLayout.BannerHeightInIPad + Self.StickyHeaderHeight
            }
        } else {
            // 일반 iPad 크기 (landscape, portrait)
            self.maxHeight = Self.BannerHeightInIPad
        }
        
        // Set Sticky Header
        //
        self.headerViewHeight.constant = self.maxHeight
        self.projectSelectViewController.collectionView.contentInset = UIEdgeInsets(top: self.maxHeight, left: 0, bottom: 0, right: 0)
        self.projectSelectViewController.collectionView.contentOffset.y = -self.maxHeight
    }
}

// MARK: - VLWhatsNewDelegate
// When user close WhatsNew Banner, BannerViewController restart autoScroll
extension VLStartViewController: VLWhatsNewDelegate {
    
    /// User Leave WhatsNewViewController, Restart Auto Scroll in BannerViewController
    func startAutoScroll() {
        self.bannerViewController.startAutoScroll()
    }
}
