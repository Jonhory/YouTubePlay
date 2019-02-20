//
//  VideoViewController.swift
//  YouTube
//
//  Created by Jonhory on 2019/2/18.
//  Copyright © 2019 jk. All rights reserved.
//

import UIKit
import SVProgressHUD

class VideoViewController: BaseViewController {

    var videos: [VideoModel] = []
    lazy var optDict = [ AVURLAssetPreferPreciseDurationAndTimingKey : (false ? 1 : 0) ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadVideosCache()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        config(leftStr: nil, leftHelpStr: nil, titleStr: "Videos", rightHelpStr: nil, rightStr: "全部删除")
        loadUI()
    }
    
    override func rightBtnClicked(btn: UIButton) {
        downloadManager.deleteAllFiles()
        loadVideosCache()
        tableView.reloadData()
    }
    
    lazy var downloadManager = JHDownloadManager()
}

extension VideoViewController {
    
    func loadVideosCache() {
        videos.removeAll()
        downloadManager.cachesDirName = "VideoCache"
        let cachePath = downloadManager.cachesDirectory
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cachePath) {
            if let contentsOfPath = try? fileManager.contentsOfDirectory(atPath: cachePath) {
                print("输出::::>>>> ", contentsOfPath)
                for path in contentsOfPath {
                    if path.contains("jhFileHelper.plist") {
                        if let videoDic = NSMutableDictionary(contentsOfFile: cachePath+"/jhFileHelper.plist") {
                            print(videoDic)
                            var files: [[String: String]] = []
                            for (_, v) in videoDic {
                                files.append(v as! [String: String])
                            }
                            for f in files {
                                if let m = VideoModel.deserialize(from: f) {
                                    m.localPath = cachePath + "/" + m.md5 + "." + m.type
                                    if Int(m.length) ?? 0 > 0 {
                                        videos.append(m)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        tableView.reloadData()
    }
    
    func loadUI() {
        configTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: TabbarHeight(), right: 0)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(NavigationBarHeight())
        }
    }
    
}

extension VideoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = VideoCell.configWith(tableView)
        cell.model = videos[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension VideoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? VideoCell, let m = cell.model {
            let localPlayVC = DownLoadedVideoPlayerVC()
            localPlayVC.fileUrl = m.localPath
            localPlayVC.fileName = m.name
            navigationController?.pushViewController(localPlayVC, animated: true)
        }
    }
}

extension VideoViewController: VideoCellDelegate {
    
    func converAudio(_ model: VideoModel) {
        let u = URL(fileURLWithPath: model.localPath)
        let avSet = AVURLAsset(url: u, options: optDict)
        if VideoFace.getAudioForVideoAsset(avSet, name: model.name, cachePath: audioCachesDirectory()) {
            SVProgressHUD.showSuccess(withStatus: "转换完成")
        } else {
            SVProgressHUD.showError(withStatus: "转换失败")
        }
    }
}
