//
//  JHDownloadManager.swift
//  JHDownloadManager
//
//  Created by Jonhory on 2019/1/21.
//  Copyright © 2019 jdj. All rights reserved.
//

import Foundation
import UIKit
import Network

enum JHDownloadState: Int {
    
    case start
    case downloading
    case paused
    case completed
    case failed
}

extension JHDownloadState {
    
    var desc: String {
        switch self {
        case .start: return "开始"
        case .downloading: return "下载中"
        case .paused: return "暂停"
        case .completed: return "完成"
        case .failed: return "失败"
        }
    }
}

typealias JHReceivedSize = Int
typealias JHRxpectedSize = Int
typealias JHProgress = Float
typealias JHSpeed = String

class JHDownloadSessionModel {
    
    var resumeData: Data?
    
    var stream: OutputStream?
    lazy var url = ""
    lazy var totalLength: Int = 0
    
    var progressBlock: ((_ receivedSize: JHReceivedSize, _ expectedSize: JHRxpectedSize, _ progress: JHProgress, _ speed: JHSpeed) -> Void)?
    var stateBlock: ((_ state: JHDownloadState, _ error: Error?) -> Void)?
    
    var currentState: JHDownloadState = .start
    
    var bytesWritten: Int64 = 0 {
        didSet {
            totalBytesWritten += bytesWritten
            if date == nil {
                date = Date()
            }
        }
    }
    
    var speed: Double {
        let currentDate = Date()
        let time = currentDate.timeIntervalSince(date!)
        
        if time >= 1 {
            lastSpeed = Double(totalBytesWritten) / Double(time)
            date = currentDate
            totalBytesWritten = 0
        }
        return lastSpeed
    }
    
    var speedFormatter: String {
        if speed == 0 { return "0 kb"}
        return ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .file)
    }
    
    var type = "mp4"
    private var lastSpeed: Double = 0
    private var totalBytesWritten: Int64 = 0
    private var date: Date?
}

class JHDownloadManager: NSObject {
    
//    static let shared = JHDownloadManager()
//    private override init() { super.init() }
    
    typealias JHCompletionHandler = () -> Void
    
    /// 网络连接类
    var session: URLSession?
    /// 是否支持后台下载，默认是
//    var isSupportBackground: Bool = true
    /// 是否允许蜂窝网络下的数据请求
    var allowsCellularAccess: Bool = false
    /// 最大并发数
    var httpMaximumConnectionsPerHost: Int = 3
    /// 可适配文件夹名称 例如将视频文件放在 videoCache 音频文件放在 musicCache 图片文件放在 imageCache
    var cachesDirName: String = "JHDownloadCache"
    /// 缓存路径
    lazy var cachesDirectory: String = {
        let doc = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
        if doc != nil && doc != "" { return doc! + "/\(cachesDirName)" }
        return ""
    }()
    
    /// 用于存储downloadTask续传时用到的 resumeData
    lazy var resumeDataCachesDir: String = {
        return cachesDirectory + "/resumeData"
    }()
    
    /// 保存所有任务 资源地址md5值为key
    fileprivate lazy var tasks: [String: URLSessionTask] = [:]
    /// 保存所有下载相关信息
    fileprivate lazy var sessionModels: [Int: JHDownloadSessionModel] = [:]
    /// 回调存储
    fileprivate lazy var completionHandlerDict: [String: JHCompletionHandler] = [:]
    
    fileprivate let fileKey_length: String = "length"
    fileprivate let fileKey_name: String = "name"
    fileprivate let fileKey_type: String = "type"
    fileprivate let fileKey_url: String = "url"
    fileprivate let fileKey_md5: String = "md5"
    fileprivate let fileKey_time: String = "time"
    
    var resu: Data?
}

extension JHDownloadManager {
    
    /// 文件名
    fileprivate func fileName(with url: String) -> String {
        return url.jh_md5()
    }
    
    /// 文件完整路径
    fileprivate func fileFullPath(with url: String) -> String {
        return cachesDirectory + "/" + fileName(with:url)
    }
    
    /// 文件已下载长度
    fileprivate func downloadLength(with url: String) -> Int {
        do {
            let items = try FileManager.default.attributesOfItem(atPath: fileFullPath(with: url))
            if let size = items[FileAttributeKey.size] {
                if let s = size as? Int { return s }
            }
        } catch {
        }
        return 0
    }
    
    /// 存储文件内容的文件路径
    fileprivate func fileHelperFullPath() -> String {
        return cachesDirectory + "/jhFileHelper.plist"
    }
    
    /// 需要存储的文件内容key包括: length 资源大小 name 文件名 type 文件类型 url 资源路径
    fileprivate func setFile(values: [String], forKeys: [String], url: String) {
        if values.count != forKeys.count {
            JHLog("请检查keyValue匹配: values:\(values), keys: \(forKeys)")
            return
        }
        var mainDic = NSMutableDictionary(contentsOfFile: fileHelperFullPath())
        if mainDic == nil { mainDic = NSMutableDictionary() }
        var dic = mainDic![fileName(with: url)] as? NSMutableDictionary
        if dic == nil { dic = NSMutableDictionary() }
        for i in 0..<values.count {
            dic?.setValue(values[i], forKey: forKeys[i])
        }
        dic?.setValue(url, forKey: fileKey_url)
        mainDic?.setValue(dic!, forKey: fileName(with: url))
        mainDic?.write(toFile: fileHelperFullPath(), atomically: true)
    }
    
    fileprivate func getFile(forKey: String, url: String) -> String {
        if let mainDic = NSMutableDictionary(contentsOfFile: fileHelperFullPath()) {
            if let dic = mainDic[fileName(with: url)] as? NSMutableDictionary {
                return (dic[forKey] as? String) ?? ""
            }
        }
        return ""
    }
    
    /// 创建缓存文件夹
    fileprivate func createCacheDirectory() {
        if !FileManager.default.fileExists(atPath: cachesDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: cachesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                JHLog("创建缓存文件夹失败!!!!")
            }
        }
    }
    
    fileprivate func start(url: String) {
        if let task = getTask(url: url) {
            task.resume()
            JHLog("开始下载: \(url.components(separatedBy: ".com")[0])  index: \(url.last!)")
            sessionModels[task.taskIdentifier]?.stateBlock?(.downloading, nil)
            sessionModels[task.taskIdentifier]?.currentState = .downloading
        }
    }
    
    fileprivate func pause(url: String) {
        if let task = getTask(url: url) {
            sessionModels[task.taskIdentifier]?.stateBlock?(.paused, nil)
            sessionModels[task.taskIdentifier]?.currentState = .paused
            
            task.suspend()
            JHLog("暂停下载: \(url.components(separatedBy: ".com")[0])")
        }
    }
    
    fileprivate func getTask(url: String) -> URLSessionTask? {
        return tasks[fileName(with: url)]
    }
}

extension JHDownloadManager {
    
    /// 开启任务下载资源
    ///
    /// - Parameters:
    ///   - url: 资源路径
    ///   - progress: 下载进度
    ///   - state: 下载状态
    func download(url: String, name: String = "", type: String = "", isSupportBackground: Bool = true, progress: @escaping ((_ receivedSize: JHReceivedSize, _ expectedSize: JHRxpectedSize, _ progress: JHProgress, _ speed: JHSpeed) -> Void), state:  @escaping ((_ state: JHDownloadState, _ error: Error?) -> Void)) {
        if url.isEmpty { return }
        if isCompletion(with: url) {
            progress(downloadLength(with: url), totalLengthSize(with: url), 1.0 ,"0 kb")
            state(.completed, nil)
            JHLog("该资源已下载完成 >>> \(url)")
            return
        }
        
        if let task = tasks[fileName(with: url)] {
            if task.state == .running {
                pause(url: url)
            } else {
                start(url: url)
            }
            return
        }
        
        createCacheDirectory()
        setFile(values: [name, type, fileName(with: url)], forKeys: [fileKey_name, fileKey_type, fileKey_md5], url: url)
        
        if session == nil {
            let sessionID = "com.jonhory.sessionID"
            
            var config: URLSessionConfiguration!
            if isSupportBackground {
                config = URLSessionConfiguration.background(withIdentifier: sessionID)
            } else {
                config = URLSessionConfiguration.ephemeral
            }
            config.timeoutIntervalForRequest = 5
            config.isDiscretionary = true
            config.allowsCellularAccess = allowsCellularAccess
            config.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
                
            session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        }
        var u = URL(string: url)
        if u == nil && url.urlEncode != nil {
            u = URL(string: url.urlEncode!)
        }
        if u == nil {
            JHLog("Error: 请检查URL是否正常:\(url)")
            return
        }
        if let stream = OutputStream(toFileAtPath: fileFullPath(with: url), append: true) {
            var request = URLRequest(url: u!)
            request.setValue(String(format: "bytes=%zd-", downloadLength(with: url)), forHTTPHeaderField: "Range")
            
            var task: URLSessionTask!
            if !isSupportBackground {
                task = session!.dataTask(with: request)
            } else {
                task = session!.downloadTask(with: request)
            }
            let taskID = Int(arc4random()%100000) + Int(Date().jh_milliStamp)
            task.setValue(taskID, forKey: "taskIdentifier")
            
            tasks[fileName(with: url)] = task
            
            let sessionModel = JHDownloadSessionModel()
            sessionModel.url = url
            sessionModel.progressBlock = progress
            sessionModel.stateBlock = state
            sessionModel.stream = stream
            sessionModel.type = type
            sessionModels[taskID] = sessionModel
            
            start(url: url)
        } else {
            JHLog("Error: 请检查URL是否正常:\(url)")
        }
        
    }
    
    /// 获取资源的下载进度
    ///
    /// - Parameter url: 资源路径
    /// - Returns: 下载进度值
    func progressSize(with url: String) -> Float {
        if totalLengthSize(with: url) > 0 {
            return Float(downloadLength(with: url)) / Float(totalLengthSize(with: url))
        }
        return 0
    }
    
    /// 获取资源总大小（bytes）
    ///
    /// - Parameter url: 资源路径
    /// - Returns: 资源总大小（bytes）
    func totalLengthSize(with url: String) -> Int {
        return Int(getFile(forKey: fileKey_length, url: url)) ?? 0
    }
    
    /// 判断资源是否完成
    ///
    /// - Parameter url: 资源路径
    /// - Returns: true 完成
    func isCompletion(with url: String) -> Bool {
        if totalLengthSize(with: url) > 0 && totalLengthSize(with: url) == downloadLength(with: url) {
            return true
        }
        return false
    }
    
    /// 删除本地资源
    ///
    /// - Parameter url: 资源路径
    func deleteFile(with url: String) {
        tasks.removeValue(forKey: fileName(with: url))
        if let task = getTask(url: url) {
            task.cancel()
            sessionModels.removeValue(forKey: task.taskIdentifier)
        }
        let manager = FileManager.default
        if manager.fileExists(atPath: fileFullPath(with: url)) {
            do {
                try manager.removeItem(atPath: fileFullPath(with: url))
            } catch {
                JHLog("删除资源失败：\(url)")
            }
        } else {
            JHLog("文件不存在:\(url)")
        }
        if manager.fileExists(atPath: fileHelperFullPath()) {
            if let dict = NSMutableDictionary(contentsOfFile: fileHelperFullPath()) {
                dict.removeObject(forKey: fileName(with: url))
                dict.write(toFile: fileHelperFullPath(), atomically: true)
            }
        }
    }
    
    /// 删除所有本地资源
    func deleteAllFiles() {
        for (_, task) in tasks {
            task.cancel()
        }
        tasks.removeAll()
        for (_, m) in sessionModels {
            m.stream?.close()
            m.stream = nil
        }
        sessionModels.removeAll()
        
        let manager = FileManager.default
        if manager.fileExists(atPath: cachesDirectory) {
            do {
                try manager.removeItem(atPath: cachesDirectory)
            } catch {
                JHLog("删除所有资源失败")
            }
        }
    }
    
    func addCompletionHandler(_ handler: @escaping () -> Void, identifier: String) {
        if completionHandlerDict[identifier] == nil {
            completionHandlerDict[identifier] = handler
            print("回调保存成功 addCompletionHandler: \(identifier)")
        }
    }
    
    func callCompletionHandlerForSession(_ identifier: String) {
        if let handle = completionHandlerDict[identifier] {
            completionHandlerDict.removeValue(forKey: identifier)
            print("调用callCompletionHandlerForSession处理下载完成以后需要更新处理的任务工作")
            handle()
            
//            guard let sessionModel = sessionModels[Int(identifier)] else {
//                return
//            }
//            if isCompletion(with: sessionModel.url) {
//                sessionModel.stateBlock?(.completed)
//            } else {
//                sessionModel.stateBlock?(.failed)
//            }
        }
//        DispatchQueue.main.async {
//            if let app = UIApplication.shared.delegate as? AppDelegate {
//                if let c = app.cc {
//                    c()
//                    app.cc = nil
//                }
//            }
//        }
    }
    
}

//MARK: - URLSessionTaskDelegate
extension JHDownloadManager: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("⚠️⚠️⚠️⚠️ : ", error?.localizedDescription ?? "")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if error != nil {
            print("用户杀掉应用，重启应用触发")
        }
        
        guard let sessionModel = sessionModels[task.taskIdentifier] else {
            return
        }

        if sessionModel.currentState == .paused {
            if let er = error as NSError?, er.code == -1001 || er.code == -999 {
                return
            }
        }

        JHLog("任务成功结束: \(sessionModel.url.components(separatedBy: ".com")[0])")

        if isCompletion(with: sessionModel.url) || sessionModel.currentState == .completed {
            sessionModel.stateBlock?(.completed, nil)
            let total = totalLengthSize(with: sessionModel.url)
            sessionModel.progressBlock?(total, total, 1.0, "0 kb")
        } else {
            sessionModel.stateBlock?(.failed, nil)
        }
        
        sessionModel.stream?.close()
        sessionModel.stream = nil

        tasks.removeValue(forKey: fileName(with: sessionModel.url))
        sessionModels.removeValue(forKey: task.taskIdentifier)

        if error != nil {
            print("任务下载完成 ❌: \(error!.localizedDescription)")
            sessionModel.stateBlock?(.failed, error)
        }
    }
}

//MARK: - URLSessionDataDelegate
extension JHDownloadManager: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let sessionModel = sessionModels[dataTask.taskIdentifier] {
            sessionModel.stream?.open()
            
            let totalLength = Int(response.expectedContentLength) + downloadLength(with: sessionModel.url)
            sessionModel.totalLength = totalLength

            setFile(values: ["\(totalLength)"], forKeys: [fileKey_length], url: sessionModel.url)
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let sessionModel = sessionModels[dataTask.taskIdentifier] {
            
            let bytes = [UInt8](data)
            sessionModel.stream?.write(UnsafePointer<UInt8>(bytes), maxLength: bytes.count)
            
            let receivedSize = downloadLength(with: sessionModel.url)
            let expectedSize = sessionModel.totalLength
            let progress = Float(receivedSize) / Float(expectedSize)
            
            sessionModel.bytesWritten = Int64(bytes.count)
            
            sessionModel.progressBlock?(receivedSize, expectedSize, progress, sessionModel.speedFormatter)
            
            if progress < 1.0 {
                sessionModel.stateBlock?(.downloading, nil)
            }
        }
    }
    
}

//MARK: - URLSessionDownloadDelegate
extension JHDownloadManager: URLSessionDownloadDelegate {
    
    //使用任务的cancel(byProducingResumeData:)方法来取消下载。通过任务的downloadTask(withResumeData:)和downloadTask(withResumeData:completionHandler:)来开启一个新的下载任务继续下载，回到第一步。
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        guard let sessionModel = sessionModels[downloadTask.taskIdentifier] else {
            return
        }
        
        let receivedSize = Int(totalBytesWritten)
        let expectedSize = Int(totalBytesExpectedToWrite)
        let progress = Float(receivedSize) / Float(expectedSize)
        
        sessionModel.bytesWritten = bytesWritten
        
        sessionModel.progressBlock?(receivedSize, expectedSize, progress, sessionModel.speedFormatter)
        
        if progress < 1.0 {
            sessionModel.stateBlock?(.downloading, nil)
        }

        setFile(values: ["\(expectedSize)"], forKeys: [fileKey_length], url: sessionModel.url)
    }
    
    //方法中有一个文件临时存放的位置。我们需要在这里使用这些数据或者把数据保存到一个永久的位置。
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let sessionModel = sessionModels[downloadTask.taskIdentifier] else {
            return
        }
        do {
            try FileManager.default.moveItem(atPath: location.path, toPath: fileFullPath(with: sessionModel.url) + "." + sessionModel.type)
            var total = totalLengthSize(with: sessionModel.url)
            var isCallback = false
            if total <= 0 {
                if let att = try? FileManager.default.attributesOfFileSystem(forPath: fileFullPath(with: sessionModel.url)) {
                    total = att[FileAttributeKey.systemSize] as! Int
                    setFile(values: ["\(total)"], forKeys: [fileKey_length], url: sessionModel.url)
                    isCallback = true
                    sessionModel.currentState = .completed
                }
            }
            if isCompletion(with: sessionModel.url) || isCallback {
                sessionModel.progressBlock?(total, total, 1.0, "0 kb")
                sessionModel.stateBlock?(.completed, nil)
            } else {
                sessionModel.progressBlock?(downloadLength(with: sessionModel.url), total, progressSize(with: sessionModel.url), "0 kb")
                sessionModel.stateBlock?(.failed, nil)
            }
            session.finishTasksAndInvalidate()
            
            setFile(values: ["\(Date().jh_milliStamp)"], forKeys: [fileKey_time], url: sessionModel.url)
            JHLog("拷贝文件成功:\(fileFullPath(with: sessionModel.url))")
        } catch {
            JHLog("拷贝文件失败:\(location.path)    toPath: \(fileFullPath(with: sessionModel.url))")
        }
        
    }

    /// 后台下载完成以后，需要调用唤起下完成要处理的任务
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        JHLog("应用在后台，且后台所有task完成后，在所有其他URLSession和downloadTask委托方法执行完后回调。可在此方法下做下载数据管理和UI刷新。之后再调用1方法保存的completionHandler ")
        if let id = session.configuration.identifier {
            callCompletionHandlerForSession(id)
        }
    }

}

extension JHDownloadManager {
    
    fileprivate func JHLog<T>(_ messsage: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("\(fileName):(\(lineNum))======>>>>>>\n\(messsage)")
        #endif
    }
    
}

extension Date {
    
    /// 获取当前 毫秒级 时间戳 - 13位
    fileprivate var jh_milliStamp : Int {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return Int(millisecond)
    }
}

fileprivate
extension String {
    
    // md5加密
    func jh_md5() -> String {
        let str = self.cString(using: .utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
    
    // url encode
    var urlEncode:String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}

