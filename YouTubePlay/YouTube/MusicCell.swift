//
//  MusicCell.swift
//  YouTube
//
//  Created by Jonhory on 2019/2/20.
//  Copyright © 2019 jk. All rights reserved.
//

import UIKit

private let MusicCellID = "MusicCellID"

class MusicModel {
    
    var name: String = ""
    var localPath: String = ""
}

class MusicCell: UITableViewCell {

    class func configWith(_ table: UITableView) -> MusicCell {
        var cell = table.dequeueReusableCell(withIdentifier: MusicCellID)
        if cell == nil {
            cell = MusicCell(style: .default, reuseIdentifier: MusicCellID)
        }
        return cell as! MusicCell
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        loadUI()
    }
    
    var model: MusicModel? {
        didSet {
            titleL.text = model?.name
        }
    }
    var titleL: UILabel!
    func loadUI() {
        titleL = create(text: "music", color: .black, font: 18, superView: contentView)
        titleL.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.right.lessThanOrEqualTo(-24)
            make.top.equalToSuperview()
            make.height.equalTo(50)
            make.bottom.equalToSuperview().priority(750)
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
