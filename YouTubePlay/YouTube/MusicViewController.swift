//
//  ViewController.swift
//  YouTube
//
//  Created by Jonhory on 2019/2/13.
//  Copyright © 2019 jk. All rights reserved.
//

import UIKit
import AudioPlayer
import SVProgressHUD

class MusicViewController: BaseViewController {

    let downloadManager = JHDownloadManager()
    let tf = UITextField()
    var musicModels: [MusicModel] = []
    lazy var player = AVAudioManager.shared()!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCaches()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config(leftStr: "暂停", leftHelpStr: nil, titleStr: "Musics", rightHelpStr: nil, rightStr: "全部删除")
        
        loadUI()
    }
    
    override func leftBtnClicked(btn: UIButton) {
        if player.isPlaying {
            player.pause()
            btn.setTitle("播放", for: .normal)
        } else {
            player.play()
            btn.setTitle("暂停", for: .normal)
        }
    }
    
    override func rightBtnClicked(btn: UIButton) {
        let result = deleteAudioAllFile()
        if result.0 {
            SVProgressHUD.showSuccess(withStatus: result.1)
            musicModels.removeAll()
            tableView.reloadData()
        } else {
            SVProgressHUD.showError(withStatus: result.1)
        }
    }
    
    func loadCaches() {
        musicModels.removeAll()
        
        let cachePath = audioCachesDirectory()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cachePath) {
            if let contentsOfPath = try? fileManager.contentsOfDirectory(atPath: cachePath) {
                print("输出音频文件夹::::>>>> ", contentsOfPath)
                
                for path in contentsOfPath {
                    let m = MusicModel()
                    m.name = path
                    m.localPath = cachePath + "/\(path)"
                    musicModels.append(m)
                }
            }
        }
        tableView.reloadData()
    }

}

extension MusicViewController {
    
    func loadUI() {
        configTableView()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}


extension MusicViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MusicCell.configWith(tableView)
        cell.model = musicModels[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MusicCell, let m = cell.model {
//            do {
//                print("正在播放：", m.localPath)
//                let audioPlayer = try AudioPlayer(contentsOfPath: m.localPath)
//                audioPlayer.play()
//            } catch {
//                SVProgressHUD.showError(withStatus: "播放音频错误")
//            }
            AVAudioManager.shared()?.play(withLocalPath: m.localPath, totalTime: 66, currentID: "\(indexPath.row)", currentIconUrl: "")
            
        }
    }
}

extension MusicViewController: UITableViewDelegate {
    
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


