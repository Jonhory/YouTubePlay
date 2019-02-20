//
//  Tool.swift
//  YouTube
//
//  Created by Jonhory on 2019/2/20.
//  Copyright © 2019 jk. All rights reserved.
//

import Foundation

/// 屏幕宽度
let SCREEN_WIDTH = UIScreen.main.bounds.width
/// 屏幕高度
let SCREEN_HEIGHT = UIScreen.main.bounds.height
let kIS_SCREEN_PLUS : Bool = UIScreen.main.currentMode?.size.height == 2208 ? true : false

func iPhonePlusOrXROrXSMax() -> Bool {
    return SCREEN_WIDTH == 414.0
}

/// iPhoneX XR
func iPhoneX() -> Bool {
    return (SCREEN_WIDTH == 375.0 && SCREEN_HEIGHT == 812.0) || (SCREEN_WIDTH == 414.0 && SCREEN_HEIGHT == 896.0)
}

func iPhone5() -> Bool { return SCREEN_WIDTH < 375 }

/// 83 / 49
func TabbarHeight() -> CGFloat { return iPhoneX() ? (49.0 + TabbarSafeBottomMargin()) : 49.0 }

/// 34 / 0
func TabbarSafeBottomMargin() -> CGFloat { return iPhoneX() ? 34.0 : 0.0 }

/// 状态栏高度 44/20
func StatusBarHeight() -> CGFloat { return iPhoneX() ? 44 : 20 }

/// 导航栏高度 88/64
func NavigationBarHeight() -> CGFloat { return StatusBarHeight() + 44 }

var audioCachesDirName: String = "audioCaches"
/// 缓存路径
func audioCachesDirectory() -> String  {
    let doc = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
    if doc != nil && doc != "" { return doc! + "/\(audioCachesDirName)" }
    return ""
}

func deleteAudioFile(with url: String) -> (Bool, String) {
    let manager = FileManager.default
    if manager.fileExists(atPath: url) {
        do {
            try manager.removeItem(atPath: url)
            return (true, "删除音频资源成功")
        } catch {
            return (false, "删除音频资源失败")
        }
    } else {
        return (false, "删除所有音频资源失败，目录不存在")
    }
}

func deleteAudioAllFile() -> (Bool, String) {
    let manager = FileManager.default
    if manager.fileExists(atPath: audioCachesDirectory()) {
        do {
            try manager.removeItem(atPath: audioCachesDirectory())
            return (true, "删除所有音频资源成功")
        } catch {
            return (false, "删除所有音频资源失败")
        }
    } else {
        return (false, "删除所有音频资源失败，目录不存在")
    }
}

func WLog<T>(_ messsage: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("\(fileName):(\(lineNum))======>>>>>>\n\(messsage)")
    #endif
}

func create(text: String, color: UIColor, font: CGFloat, superView: UIView, numberOfLines: Int = 1) -> UILabel {
    let l = UILabel()
    l.text = text
    l.textColor = color
    l.font = UIFont.systemFont(ofSize: font)
    l.adjustsFontSizeToFitWidth = true
    l.numberOfLines = numberOfLines
    superView.addSubview(l)
    return l
}

func createLine(_ superView: UIView) -> UIView {
    let v = UIView()
    v.backgroundColor = .lightGray
    superView.addSubview(v)
    return v
}

func createBtn(_ text: String, textColor: UIColor, font: CGFloat, backColor: UIColor, superView: UIView) -> UIButton {
    let b = UIButton(type: .custom)
    superView.addSubview(b)
    b.setTitle(text, for: .normal)
    b.setTitleColor(textColor, for: .normal)
    b.backgroundColor = backColor
    b.titleLabel?.font = UIFont.systemFont(ofSize: font)
    b.titleLabel?.adjustsFontSizeToFitWidth = true
    return b
}

func createTF(_ placeholder: String?, textColor: UIColor, font: CGFloat, superView: UIView, backgroundColor: UIColor = .white, borderWidth: CGFloat = 0, borderColor: UIColor = .lightGray, leftMargin: CGFloat = 10, cornerRadius: CGFloat = 0) -> UITextField {
    let tf = UITextField()
    if borderWidth > 0 {
        tf.layer.borderWidth = borderWidth
        tf.layer.borderColor = borderColor.cgColor
    }
    if cornerRadius > 0 {
        tf.layer.cornerRadius = cornerRadius
    }
    tf.placeholder = placeholder
    tf.backgroundColor = backgroundColor
    if leftMargin > 0 {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: leftMargin, height: 1))
        tf.leftView = v
        tf.leftViewMode = .always
    }
    tf.clearButtonMode = .whileEditing
    tf.font = UIFont.systemFont(ofSize: font)
    
    superView.addSubview(tf)
    return tf
}
