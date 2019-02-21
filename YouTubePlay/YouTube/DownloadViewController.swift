//
//  DownloadViewController.swift
//  YouTube
//
//  Created by Jonhory on 2019/2/18.
//  Copyright © 2019 jk. All rights reserved.
//

import UIKit
@_exported import SVProgressHUD

class DownloadViewController: BaseViewController {

    
    @IBOutlet weak var fileNameTF: UITextField!
    @IBOutlet weak var fileTypeTF: UITextField!
    
    @IBOutlet weak var urlTF: UITextField!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    
    @IBOutlet weak var musicGeting: UILabel!
    @IBOutlet weak var musicSaving: UILabel!
    @IBOutlet weak var musicSuccess: UILabel!
    
    lazy var downloadManager = JHDownloadManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        navigationController?.navigationBar.prefersLargeTitles = true
        
        config(leftStr: "第三方解析", leftHelpStr: nil, titleStr: "Download", rightHelpStr: nil, rightStr: "粘贴url")
        urlTF.text = "http://pgc.cdn.xiaodutv.com/1874370668_866941668_2018030212274320180605013211.mp4?Cache-Control=max-age%3D8640000&responseExpires=Thu%2C+13+Sep+2018+01%3A33%3A10+GMT&xcode=f1e7bc42b5fa7597b59705fed825b4f9d30a07c977a7f21a&time=1550742948&_=1550656554106"
        downloadManager.cachesDirName = "VideoCache"
    }
    
    override func leftBtnClicked(btn: UIButton) {
        if let u = URL(string: "https://www.tubeninja.net/") {
            UIApplication.shared.open(u, options: [:], completionHandler: nil)
        }
        
    }
    
    override func rightBtnClicked(btn: UIButton) {
        let paste = UIPasteboard.general
        urlTF.text = paste.string
    }

    @IBAction func downloadClicked(_ sender: UIButton) {
        if urlTF.text == nil || urlTF.text!.count == 0 {
            SVProgressHUD.showError(withStatus: "Please check url")
            return
        }
        if fileNameTF.text == nil || fileNameTF.text!.count == 0 {
            SVProgressHUD.showError(withStatus: "请输入文件名称")
            return
        }
        
        downloadManager.download(url: urlTF.text!, name: fileNameTF.text!, type: fileTypeTF.text!, isSupportBackground: true, progress: { (receivedSize, rxpectedSize, j_progress, speed) in
            self.speedLabel.isHidden = false
            self.speedLabel.text = speed + "/s"
            self.progress.isHidden = false
            self.progress.progress = j_progress
        }) { (state, error) in
            self.statusLabel.text = "下载状态：" + state.desc
        }
        
    }
}

