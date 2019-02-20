//
//  BaseViewController.swift
//  JHWebview
//
//  Created by Jonhory on 2017/2/26.
//  Copyright © 2017年 jonhory. All rights reserved.
//

import UIKit
import MJRefresh

enum BaseNavType: Int {
    case Left = 950
    case LeftHelper
    case Center
    case RightHelper
    case Right
}

typealias BaseCallBack = (() -> Void)

class BaseViewController: UIViewController {
    
    /// 导航栏控件,想要修改属性请在viewDidLoad()之后
    var leftBtn: UIButton?
    var leftHelpBtn: UIButton?
    private var titleLabel: UILabel?
    var rightHelpBtn: UIButton?
    var rightBtn: UIButton?
    /// 初始化赋值请使用以下参数
    var leftStr: Any?//可以是String 或者 Image
    var leftHelpStr: Any?//可以是String 或者 Image
    var titleStr: String?
    var rightStr: Any?//可以是String 或者 Image
    var rightHelpStr: Any?//可以是String 或者 Image
    
    /// 方便父类使用
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .plain)
        table.tableFooterView = UIView()
        table.estimatedRowHeight = 50
        table.backgroundColor = .white
        table.separatorStyle = .none
        return table
    }()
    /// 方便父类使用
    func configTableView() {
        adjustiOS11(tableView)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: TabbarSafeBottomMargin(), right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(NavigationBarHeight())
        }
    }
    
    /// 方便父类使用
    lazy var baseScrollView = UIScrollView()
    lazy var scrollContent = UIView()
    /// 方便父类使用,生成scrollView，默认上下滑动
    func configScrollContents() {
        adjustiOS11(baseScrollView)
        baseScrollView.backgroundColor = .white
        view.addSubview(baseScrollView)
        baseScrollView.addSubview(scrollContent)
        
        baseScrollView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(NavigationBarHeight())
        }
        
        scrollContent.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalTo(SCREEN_WIDTH)
        }
    }
    
    var baseCallback: BaseCallBack?
    func baseCallback(_ block: BaseCallBack?) {
        self.baseCallback = block
    }
    
    func handleRefreshHeaderCustom( _ table: UITableView? = nil, _ header: MJRefreshComponentRefreshingBlock? = nil, footer: MJRefreshComponentRefreshingBlock? = nil) {
        var t = table
        if t == nil { t = tableView }
        if header != nil { t!.mj_header = MJRefreshNormalHeader(refreshingBlock: header) }
        if footer != nil {
            t!.mj_footer = MJRefreshBackNormalFooter(refreshingBlock: footer)
            t!.mj_footer.ignoredScrollViewContentInsetBottom = TabbarSafeBottomMargin() * 2
        }
    }
    
    func handleRefreshHeader(_ header: MJRefreshComponentRefreshingBlock? = nil, footer: MJRefreshComponentRefreshingBlock? = nil) {
        handleRefreshHeaderCustom(tableView, header, footer: footer)
    }
    
    //MARK: - 公共方法
    func config(leftStr: Any?, leftHelpStr: Any?, titleStr: String?, rightHelpStr:Any?, rightStr: Any?) {
        self.leftStr = leftStr
        self.leftHelpStr = leftHelpStr
        self.titleStr = titleStr
        self.rightHelpStr = rightHelpStr
        self.rightStr = rightStr
        loadNav()
    }
    
    //MARK: - 私有方法
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configBase()
        
        loadNav()
        addBaseNoti()
    }
    
    private func configBase() {
        view.backgroundColor = .white
        automaticallyAdjustsScrollViewInsets = false
    }
    
    private func addBaseNoti() {
        //        NotificationCenter.default.addObserver(self, selector: #selector(tokenError), name: NOTI_TOKEN_Fail_Base, object: nil)
    }
    
    var isTokenError = false
    @objc func tokenError() {
        if isTokenError { return }
        //        UserCenter.shared.logout()
        isTokenError = true
        _ = navigationController?.popToRootViewController(animated: false)
        // 这句代码会让登录的vc dismiss 待改进。加一个dispatch_after?
        dismiss(animated: false, completion: nil)
        // token失效第二步 发送退出通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68, execute: {
            //            NotificationCenter.default.post(name: NOTI_LOGOUT, object: nil)
        })
    }
    
    //MARK:所有按钮点击事件
    @objc func navBtnClicked(btn: UIButton) {
        
        let tag: BaseNavType = BaseNavType(rawValue: btn.tag)!
        switch tag {
        case .Left:
            leftBtnClicked(btn: btn)
            break
        case .LeftHelper:
            leftHelpBtnClicked(btn: btn)
            break
        case .RightHelper:
            rightHelpBtnClicked(btn: btn)
            break
        case .Right:
            rightBtnClicked(btn: btn)
            break
        default: break
            
        }
    }
    
    @objc func leftBtnClicked(btn: UIButton) {
        view.endEditing(true)
        if (self.navigationController?.viewControllers.count)! > 0 {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    func leftHelpBtnClicked(btn: UIButton) {
        
    }
    
    func rightHelpBtnClicked(btn: UIButton) {
        
    }
    
    func rightBtnClicked(btn: UIButton) {
        
    }
    
    func loadNav() {
        var leftBar: UIBarButtonItem? = nil
        var leftHelpBar: UIBarButtonItem? = nil
        var rightBar: UIBarButtonItem? = nil
        var rightHelpBar: UIBarButtonItem? = nil
        
        if leftStr != nil && (leftStr is String || leftStr is UIImage) {
            leftBtn = createBtn(tag: .Left)
            if leftStr is String {
                handleBtnWithString(btn: leftBtn!, str: leftStr as! String)
            }else{
                handleBtnWithImage(btn: leftBtn!, image: leftStr as! UIImage)
            }
            leftBar = UIBarButtonItem(customView: leftBtn!)
        }
        
        if leftHelpStr != nil && (leftHelpStr is String || leftHelpStr is UIImage) {
            leftHelpBtn = createBtn(tag: .LeftHelper)
            if leftHelpStr is String {
                handleBtnWithString(btn: leftHelpBtn!, str: leftHelpStr as! String)
            }else{
                handleBtnWithImage(btn: leftHelpBtn!, image: leftHelpStr as! UIImage)
            }
            leftHelpBar = UIBarButtonItem(customView: leftHelpBtn!)
        }
        
        if titleStr != nil {
            titleLabel = UILabel()
            titleLabel?.text = titleStr!
            titleLabel?.font = UIFont.systemFont(ofSize: 17)
            titleLabel?.textColor = .black
            titleLabel?.sizeToFit()
            self.navigationItem.titleView = titleLabel
        }
        
        if rightHelpStr != nil && (rightHelpStr is String || rightHelpStr is UIImage) {
            rightHelpBtn = createBtn(tag: .RightHelper)
            if rightHelpStr is String {
                handleBtnWithString(btn: rightHelpBtn!, str: rightHelpStr as! String)
            }else{
                handleBtnWithImage(btn: rightHelpBtn!, image: rightHelpStr as! UIImage)
            }
            rightHelpBar = UIBarButtonItem(customView: rightHelpBtn!)
        }
        
        if rightStr != nil && (rightStr is String || rightStr is UIImage) {
            rightBtn = createBtn(tag: .Right)
            if rightStr is String {
                handleBtnWithString(btn: rightBtn!, str: rightStr as! String)
            }else{
                handleBtnWithImage(btn: rightBtn!, image: rightStr as! UIImage)
            }
            rightBar = UIBarButtonItem(customView: rightBtn!)
        }
        
        
        if leftBar != nil && leftHelpBar != nil {
            self.navigationItem.leftBarButtonItems = [leftBar!, leftHelpBar!]
        } else if leftBar != nil {
            self.navigationItem.leftBarButtonItem = leftBar!
        } else if leftHelpBar != nil {
            self.navigationItem.leftBarButtonItem = leftHelpBar!
        }
        
        if rightBar != nil && rightHelpBar != nil {
            self.navigationItem.rightBarButtonItems = [rightBar!, rightHelpBar!]
        } else if rightBar != nil {
            self.navigationItem.rightBarButtonItem = rightBar!
        } else if rightHelpBar != nil {
            self.navigationItem.rightBarButtonItem = rightHelpBar!
        }
    }
    
    private func handleBtnWithString(btn: UIButton, str:String) {
        btn.setTitle(str, for: .normal)
        btn.setTitleColor(UIColor.darkGray, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: str.sizeWidth(btn: btn) + 10, height: 40)
    }
    
    private func handleBtnWithImage(btn: UIButton, image: UIImage) {
        btn.setBackgroundImage(image, for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    }
    
    private func createBtn(tag: BaseNavType) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        btn.tag = tag.rawValue
        btn.addTarget(self, action: #selector(navBtnClicked(btn:)), for: .touchUpInside)
        return btn
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc private func scrollContentClicked() {
        view.endEditing(true)
    }
    
    deinit {
        WLog("释放了 ➡️ \(self)")
    }
}

extension BaseViewController: UIGestureRecognizerDelegate {
    
}

extension BaseViewController {
    
    func pushVC(_ vc: BaseViewController) {
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func adjustiOS11(_ view: UIScrollView) {
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        extendedLayoutIncludesOpaqueBars = false
    }

}

extension String {
    
    func sizeWidth(btn: UIButton) -> Double {
        return Double(self.size(withAttributes: [NSAttributedString.Key.font:
            UIFont(name: (btn.titleLabel?.font.fontName)!, size: (btn.titleLabel?.font.pointSize)!)!]).width)
    }
    
}
