//
//  AVAudioManager.m
//  ksh3
//
//  Created by Jonhory on 2016/12/13.
//  Copyright © 2016年 jianminxian. All rights reserved.
//

#import "AVAudioManager.h"

static NSUInteger k_JH_AVAudioItemType = 1;

//电台状态
typedef NS_ENUM(NSUInteger, ZDDStationStatus) {
    ZDDStationStatusPlay = 1,
    ZDDStationStatusStop,
    ZDDStationStatusPause,
};

@interface AVAudioManager ()
{
    BOOL isPrePare;//是否准备好资源
}
@property (nonatomic ,strong) AVPlayer * player;/**< 播放器 */
@property (nonatomic ,strong) AVPlayerItem * item;/**< 当前播放的资源 */

@property (nonatomic ,assign) int totalTime;/**< 当前播放的音频总时长 */
@property (nonatomic ,assign) BOOL alreadyPlay;/**< 是否已经播放 */

@property (nonatomic ,strong) AVAudioSession * session;

@end

@implementation AVAudioManager

+ (instancetype)sharedManager{
    static AVAudioManager * manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AVAudioManager new];
    });
    return manager;
}

- (AVAudioSession *)session{
    if (!_session) {
        _session = [AVAudioSession sharedInstance];
    }
    return _session;
}

- (AVPlayer *)player{
    if (!_player) {
        _player = [[AVPlayer alloc]init];
        _player.volume = 1.0;
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(kAVAudioSessionInterruptionNotification:)
                                                     name: AVAudioSessionInterruptionNotification
                                                   object: self.session];
    }
    return _player;
}

- (void)playWithLocalPath:(NSString *)localPath totalTime:(int)totalTime currentID:(NSString *)currentID currentIconUrl:(NSString *)currentIconUrl{
    [self playWithPath:localPath isNetWork:NO totalTime:totalTime currentID:currentID currentIconUrl:currentIconUrl];
}

- (void)playWithURL:(NSString *)itemURL totalTime:(int)totalTime currentID:(NSString *)currentID currentIconUrl:(NSString *)currentIconUrl{
    [self playWithPath:itemURL isNetWork:YES totalTime:totalTime currentID:currentID currentIconUrl:currentIconUrl];
}

- (void)playWithPath:(NSString *)path isNetWork:(BOOL)isNetwork totalTime:(int)totalTime currentID:(NSString *)currentID currentIconUrl:(NSString *)currentIconUrl{
    @try {
        [self reset];
        self.totalTime = totalTime;
        self.currentID = currentID;
        self.currentIconUrl = currentIconUrl;
        
        if (path && ![path isEqualToString:@""]) {
            dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
                if (isNetwork) {
                    NSURL * url = [NSURL URLWithString:path];
                    self.item = [[AVPlayerItem alloc]initWithURL:url];
                }else{
                    NSURL *sourceMovieUrl = [NSURL fileURLWithPath:path];
                    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieUrl options:nil];
                    self.item = [AVPlayerItem playerItemWithAsset:movieAsset];
                }
                
                if (self.item) {
                    [self.player replaceCurrentItemWithPlayerItem:self.item];
            
                    [self.player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew) context:nil];
                    //监控网络加载情况属性
                    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
                }
            });
        }
    } @catch (NSException *exception) {
    } @finally {
    }
}

- (void)reset{
    if (self.player == nil || self.player.currentItem == nil || _item == nil) {
        return;
    }
    self.isPlaying = NO;
    
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _item = nil;
    
    _player = nil;
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    
    self.alreadyPlay = NO;
    NSLog(@"重置播放了!!!!!");
}

- (void)play{
    if (!isPrePare || self.isPlaying || self.player == nil || self.player.currentItem == nil) {
        return;
    }
    if (self.player.rate) {
        return;
    }else{
        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
//            AVAudioSession *session = [AVAudioSession sharedInstance];
//            
//            [session setCategory:AVAudioSessionCategoryPlayback
//                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
//                           error:nil];
            [self.player play];
            self.isPlaying = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(AVAudioManagerBeginPlay)]) {
                    NSLog(@"开始播放了！！！！！！！！");
                    [self.delegate AVAudioManagerBeginPlay];
                }
            });
        }
    }
}

- (BOOL)remoteControlPlay{
    if (k_JH_AVAudioItemType == AVAudioItemTypeRadio) {
        return NO;
    }
    [self play];
    return YES;
}

- (void)pause{
    if (!self.isPlaying || self.player == nil || self.player.currentItem == nil) {
        return;
    }
    if (!self.player.rate) {
        self.isPlaying = NO;
        return;
    }else{
        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"暂停播放了!!!!!");
            [_player pause];
            self.isPlaying = NO;
        }
    }
}

- (void)headsetPause{
    if (!self.isPlaying || self.player == nil || self.player.currentItem == nil) {
        return;
    }
    if (self.player.status == AVPlayerItemStatusReadyToPlay) {
        NSLog(@"暂停播放了!!!!!");
        [_player pause];
        self.isPlaying = NO;
    }
}

- (BOOL)remoteControlPause{
    if (k_JH_AVAudioItemType == AVAudioItemTypeRadio) {
        return NO;
    }
    [self pause];
    return YES;
}

- (void)stop{
    if (!self.isPlaying) {
        return;
    }
    if (self.player == nil || self.player.currentItem == nil) {
        return;
    }
    if (!self.player.rate) {
        self.isPlaying = NO;
        return;
    }else{
        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
            [_player seekToTime:CMTimeMake(0, 1)];
            [_player pause];
            self.isPlaying = NO;
            
            [self.player.currentItem removeObserver:self forKeyPath:@"status"];
            [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
            [self.player replaceCurrentItemWithPlayerItem:nil];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self];

            _item = nil;

            _player = nil;
            [_player.currentItem cancelPendingSeeks];
            [_player.currentItem.asset cancelLoading];
            NSLog(@"停止播放了!!!!!");
            self.alreadyPlay = NO;
        }
    }
    
}

- (void)seekToSecond:(float)second{
    [self pause];
    if (self.player.currentItem != nil && self.player.currentItem.duration.timescale) {
        [self.player seekToTime:CMTimeMakeWithSeconds(second * self.totalTime, self.player.currentItem.duration.timescale) completionHandler:^(BOOL finished) {
            if (finished) {
                [self play];
            }
        }];   
    }
}

- (void)setCurrentItemType:(AVAudioItemType)type{
    k_JH_AVAudioItemType = type;
}

- (float)currentFloat{
    if (self.isPlaying) {
        NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
        return currentTime;
    }
    return 0.0;
}

- (void)returnCurrentFloat:(CGFloat)progress{
    if (self.delegate && [self.delegate respondsToSelector:@selector(AVAudioManagerIsBuffering:)]) {
        [self.delegate AVAudioManagerIsBuffering:progress];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        AVPlayerItem * playerItem = object;
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        
        
        CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;//总长度
//        NSLog(@"目前缓冲了%.2f ,总长度 = %f, 百分之%f ",totalBuffer,totalSecond,totalBuffer/totalSecond);
        [self returnCurrentFloat:totalBuffer/totalSecond];
        
    }else if ([keyPath isEqualToString:@"status"]){
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:{
                NSLog(@"\n ================= AVPlayerItemStatusReadyToPlay ======= \n ");
                isPrePare = YES;
                if (!self.alreadyPlay) {
                    [self play];
                    self.alreadyPlay = YES;
                }
                break;
            }
            case AVPlayerItemStatusFailed:{
                NSLog(@"\n ================= AVPlayerItemStatusFailed ======= \n ");
                [self reset];
                if (self.delegate && [self.delegate respondsToSelector:@selector(AVAudioManagerFailPlay)]) {
                    [self.delegate AVAudioManagerFailPlay];
                }
                break;
            }
            case AVPlayerItemStatusUnknown:{
                NSLog(@"\n ================= AVPlayerItemStatusUnknown ============== \n ");
                [self reset];
                if (self.delegate && [self.delegate respondsToSelector:@selector(AVAudioManagerFailPlay)]) {
                    [self.delegate AVAudioManagerFailPlay];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)kAVAudioSessionInterruptionNotification:(NSNotification *)noti{
    // 其他app播放音乐noti.userInfo = { AVAudioSessionInterruptionTypeKey = 1 }
    NSLog(@"\n\n kAVAudioSessionInterruptionNotification === %@ \n\n",noti.userInfo);
    NSDictionary * info = noti.userInfo;
    if ([[info objectForKey:AVAudioSessionInterruptionTypeKey] integerValue] == 1 || self.session.otherAudioPlaying) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(AVAudioManagerOtherPlaying)]) {
            [self.delegate AVAudioManagerOtherPlaying];
        }
        if (self.isPlaying) {
            [self setTPlayingIsStop:YES];
        }
    }
}

#pragma mark - 全局状态处理
- (void)setTPlayingIsStop:(BOOL)isStop{
    NSInteger status1 = isStop ? ZDDStationStatusStop : ZDDStationStatusPlay;
    NSString * stationStr1 = [NSString stringWithFormat:@"%ld",status1];
    [[NSUserDefaults standardUserDefaults] setValue:stationStr1 forKey:@"tPlaying"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc{
//    if (_item) {
//        [self.item removeObserver:self forKeyPath:@"status"];
//    }
}
@end
