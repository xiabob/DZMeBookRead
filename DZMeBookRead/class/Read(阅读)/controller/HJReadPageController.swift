//
//  HJReadPageController.swift
//  HJProject
//
//  Created by 邓泽淼 on 16/8/15.
//  Copyright © 2016年 HanJue. All rights reserved.
//

import UIKit

//最上层的界面 HJReadPageController ->(持有add) DZMCoverController/UIPageViewController ->(包含) HJReadViewController(实际文字展示界面)
class HJReadPageController: HJViewController,UIPageViewControllerDelegate,UIPageViewControllerDataSource,DZMCoverControllerDelegate {
    
    // 阅读主对象
    var readModel:HJReadModel!
    
    /// 翻页控制器
    var pageViewController:UIPageViewController!
    var coverController:DZMCoverController!
    
    /// 阅读设置
    var readSetup:HJReadSetup! ///界面相关的设置
    var readConfigure:HJReadPageDataConfigure! ///阅读数据相关的配置
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化
        readConfigure = HJReadPageDataConfigure.setupWithReadController(self)
        readSetup = HJReadSetup.setupWithReadController(self)
        
        // 初始化翻页效果
        readSetup.setFlipEffect(HJReadConfigureManger.shareManager.flipEffect,chapterLookPageClear: false)
    }
    
    deinit {
        print("HJReadPageController deinit")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.default, animated: true)
        
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.fade)
        
        removeNotification()
    }
    
    // MARK: -- PageController
    
    func creatPageController(_ displayController:UIViewController) {
        
        if pageViewController != nil {
            
            pageViewController.view.removeFromSuperview()
            
            pageViewController.removeFromParentViewController()
        }
        
        if coverController != nil {
            
            coverController.view.removeFromSuperview()
            
            coverController.removeFromParentViewController()
        }
        
        if HJReadConfigureManger.shareManager.flipEffect == HJReadFlipEffect.simulation {
            
            let options = [UIPageViewControllerOptionSpineLocationKey:NSNumber(value: UIPageViewControllerSpineLocation.min.rawValue as Int)]
            
            pageViewController = UIPageViewController(transitionStyle:UIPageViewControllerTransitionStyle.pageCurl,navigationOrientation:UIPageViewControllerNavigationOrientation.horizontal,options: options)
            
            pageViewController.delegate = self
            
            pageViewController.dataSource = self
            
            view.insertSubview(pageViewController.view, at: 0)
            
            addChildViewController(pageViewController)
            
            pageViewController.setViewControllers([displayController], direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
            
        } else {
            
            coverController = DZMCoverController()
            
            coverController.delegate = self
            
            view.insertSubview(coverController.view, at: 0)
            
            addChildViewController(coverController)
            
            coverController.setController(displayController)
            
            if HJReadConfigureManger.shareManager.flipEffect == HJReadFlipEffect.none {
                
                coverController.openAnimate = false
                
            }else if (HJReadConfigureManger.shareManager.flipEffect == HJReadFlipEffect.upAndDown){
                
                coverController.openAnimate = false
                
                coverController.gestureRecognizerEnabled = false
            }
        }
    }
    
    // MARK: -- DZMCoverControllerDelegate
    
    func coverController(_ coverController: DZMCoverController, currentController: UIViewController?, finish isFinish: Bool) {
        
        if !isFinish {
            
            // 重置阅读记录
            synchronizationPageViewControllerData(currentController)
            
        }else{
            
            // 刷新阅读记录
            readConfigure.synchronizationChangeData()
        }
    }
    
    func coverController(_ coverController: DZMCoverController, getAboveControllerWithCurrentController currentController: UIViewController?) -> UIViewController? {
        
        return readConfigure.GetReadPreviousPage()
    }
    
    func coverController(_ coverController: DZMCoverController, getBelowControllerWithCurrentController currentController: UIViewController?) -> UIViewController? {
        
        return readConfigure.GetReadNextPage()
    }
    
    // MARK: -- UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if !completed {
            
            // 重置阅读记录
            synchronizationPageViewControllerData(previousViewControllers.first)
            
        }else{
            
            // 刷新阅读记录
            synchronizationPageViewControllerData(pageViewController.viewControllers?.first)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        // 刷新阅读记录
        synchronizationPageViewControllerData(pageViewController.viewControllers?.first)
    }
    
    
    // MARK: -- UIPageViewControllerDataSource
    
    /// 获取上一页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
        return readConfigure.GetReadPreviousPage()
    }
    
    /// 获取下一页
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        return readConfigure.GetReadNextPage()
    }
    
    /// 同步PageViewController 当前显示的控制器的内容
    func synchronizationPageViewControllerData(_ viewController: UIViewController?){
        
        if (viewController != nil) {
            
            let vc  = viewController as! HJReadViewController
            readConfigure.changeReadChapterListModel = vc.readRecord.readChapterListModel
            readConfigure.changeReadChapterModel = vc.readChapterModel
            readConfigure.changeLookPage = vc.readRecord.page.intValue
            readModel.readRecord.chapterIndex = vc.readRecord.chapterIndex
            title = vc.readChapterModel.chapterName
            
            // 刷新阅读记录
            readConfigure.synchronizationChangeData()
        }
    }
    
    // MARK: -- 设置导航栏
    
    override func initNavigationBarSubviews() {
        super.initNavigationBarSubviews()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.AppNavigationBarBackItemOne(UIEdgeInsetsMake(0, 0, 0, 0), target: self, action: #selector(clickBack))
    }
    
    override func clickBack() {
        super.clickBack()
        
        // 保存记录
        readConfigure.updateReadRecord()
        
        readSetup = nil
        readConfigure = nil
        if (pageViewController != nil) {
            pageViewController.removeFromParentViewController()
            pageViewController = nil
        }
        if (coverController != nil) {
            coverController.removeFromParentViewController()
            coverController = nil
        }
        for subView in view.subviews {
            subView.removeFromSuperview()
        }
    }
    
    
    // MARK: -- notification 
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidReceiveMemoryWarning), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationWillTerminate() {
        readConfigure.updateReadRecord()
    }
    
    func applicationDidEnterBackground() {
        readConfigure.updateReadRecord()
    }
    
    func applicationDidReceiveMemoryWarning() {
        readConfigure.updateReadRecord()
    }
    
}
