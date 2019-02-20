//
//  VideoCell.swift
//  YouTube
//
//  Created by Jonhory on 2019/2/18.
//  Copyright © 2019 jk. All rights reserved.
//

import UIKit
import HandyJSON
@_exported import SnapKit

fileprivate let VideoCellID = "VideoCellID"

func thumbnailImage(for url: String) -> UIImage? {
    let videoURL = URL(fileURLWithPath: url)
    print(videoURL)
    let avAsset = AVAsset(url: videoURL)
    //生成视频截图
    let generator = AVAssetImageGenerator(asset: avAsset)
    generator.appliesPreferredTrackTransform = true
    let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 10)
    var actualTime:CMTime = CMTimeMake(value: 0,timescale: 0)
    do {
        let imageRef: CGImage = try generator.copyCGImage(at: time, actualTime: &actualTime)
        let frameImg = UIImage(cgImage: imageRef)
        return frameImg
    } catch {
        print("generator.copyCGImage error")
        return nil
    }
    
}

class VideoModel: HandyJSON {
    
    var md5: String = ""
    var type: String = ""
    var url: String = ""
    var name: String = ""
    var time: String = ""
    var length: String = ""
    
    var localPath: String = "" {
        didSet {
            self.image = thumbnailImage(for: localPath)
        }
    }
    
    var image: UIImage?
    
    required init() {}
    
}

protocol VideoCellDelegate: class {
    
    func converAudio(_ model: VideoModel)
}

class VideoCell: UITableViewCell {

    weak var delegate: VideoCellDelegate?
    
    class func configWith(_ table: UITableView) -> VideoCell {
        var cell = table.dequeueReusableCell(withIdentifier: VideoCellID)
        if cell == nil {
            cell = VideoCell(style: .default, reuseIdentifier: VideoCellID)
        }
        return cell as! VideoCell
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        loadUI()
    }
    
    var model: VideoModel? {
        didSet {
            nameL.text = model?.name
            videoIV.image = model?.image
        }
    }
    
    @objc func convertBtnClicked() {
        if model == nil { return }
        delegate?.converAudio(model!)
    }
    
    let videoIV = UIImageView()
    let nameL = UILabel()
    let convertBtn = UIButton()
    func loadUI() {
        nameL.text = "文件名"
        contentView.addSubview(nameL)
        convertBtn.setTitle("转换音频", for: .normal)
        convertBtn.setTitleColor(.black, for: .normal)
        convertBtn.backgroundColor = .lightGray
        convertBtn.addTarget(self, action: #selector(convertBtnClicked), for: .touchUpInside)
        contentView.addSubview(convertBtn)
        
        videoIV.backgroundColor = .black
        videoIV.contentMode = .scaleAspectFit
        contentView.addSubview(videoIV)
        
        videoIV.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.top.equalTo(12)
            make.width.equalTo(100)
            make.height.equalTo(62)
            make.bottom.equalTo(-12).priority(750)
        }
        
        nameL.snp.makeConstraints { (make) in
            make.left.equalTo(videoIV.snp.right).offset(12)
            make.right.lessThanOrEqualTo(convertBtn.snp.left).offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
        }
        
        convertBtn.snp.makeConstraints { (make) in
            make.right.equalTo(-24)
            make.centerY.equalToSuperview()
        }
        
        let line = createLine(contentView)
        line.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.right.equalTo(-24)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
