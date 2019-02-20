//
//  AVAudioManager.h
//  ksh3
//
//  Created by Jonhory on 2016/12/13.
//  Copyright © 2016年 jianminxian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//控制器事件通知
static NSString * const kRemoteControlReceivedWithEventNoti = @"kRemoteControlReceivedWithEventNoti";
static NSString * const kRemoteControlEventKey = @"kRemoteControlEventKey";

typedef NS_ENUM(NSUInteger ,AVAudioItemType){
    AVAudioItemTypeStation    =  1,//普通音频
    AVAudioItemTypeRadio          ,//互动电台回放的音频 用于区分在某些特定场景不希望播放音频
};

@protocol AVAudioManagerDelegate <NSObject>
@optional
//开始播放
- (void)AVAudioManagerBeginPlay;
//播放失败
- (void)AVAudioManagerFailPlay;
//正在缓冲
- (void)AVAudioManagerIsBuffering:(CGFloat)currentFloat;
//其他app播放音频
- (void)AVAudioManagerOtherPlaying;

@end

@interface AVAudioManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic ,weak) id<AVAudioManagerDelegate>delegate;

@property (nonatomic ,assign) BOOL isPlaying;//是否真正播放
@property (nonatomic ,copy) NSString * currentID;//当前播放的ID
@property (nonatomic ,copy) NSString * currentIconUrl;//当前播放的图标


/**
 设置资源类型 默认是普通音频

 @param type
 */
- (void)setCurrentItemType:(AVAudioItemType)type;

/**
 获取当前播放音频秒数

 @return 当前播放音频秒数
 */
- (float)currentFloat;

/**
 重置,外部不允许使用 否则会因为重复removeObserver崩溃。 
 */
//- (void)reset;

/**
 播放本地资源

 @param localPath 资源路径
 @param totalTime 总秒数
 @param currentID 资源的id
 */
- (void)playWithLocalPath:(NSString *)localPath totalTime:(int)totalTime currentID:(NSString *)currentID currentIconUrl:(NSString *)currentIconUrl;

/**
 播放网络资源

 @param itemURL 链接
 @param totalTime 总秒数
 @param currentID 资源的id
 */
- (void)playWithURL:(NSString *)itemURL totalTime:(int)totalTime currentID:(NSString *)currentID currentIconUrl:(NSString *)currentIconUrl;

/**
 开始播放
 */
- (void)play;

/**
 系统控制器播放
 */
- (BOOL)remoteControlPlay;

/**
 暂停播放
 */
- (void)pause;

/**
 耳机拔出时暂停
 */
- (void)headsetPause;

/**
 系统控制器暂停
 */
- (BOOL)remoteControlPause;

/**
 停止播放
 */
- (void)stop;

/**
 滑动到指定百分比位置

 @param second 百分比
 */
- (void)seekToSecond:(float)second;


/**
 设置全局播放状态

 @param isStop 是否停止
 */
- (void)setTPlayingIsStop:(BOOL)isStop;

@end
