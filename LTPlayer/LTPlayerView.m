//
//  LTPlayerView.m
//  LTPlayer
//
//  Created by lt on 2017/12/25.
//  Copyright © 2017年 lt. All rights reserved.
//

#import "LTPlayerView.h"

@interface LTPlayerView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIButton *playOrPauseButton;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UISlider *slider;

@property (nonatomic, assign) BOOL readyToPlay;

@end

@implementation LTPlayerView

- (instancetype)init {
    if (self = [super init]) {
        [self initUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    
    [self addSubview:self.playOrPauseButton];
    [self addSubview:self.progressView];
    [self addSubview:self.slider];
    
    // 播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    // 监控播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监控网络加载情况属性
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
//    AVPlayerItem *playerItem=self.player.currentItem;
    UISlider *slider = self.slider;
    //这里设置每秒执行一次
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current=CMTimeGetSeconds(time);
        NSLog(@"当前已经播放%.2fs.",current);
        if (current) {
            [slider setValue:(current) animated:YES];
        }
    }];
}

- (void)layoutSubviews {
    self.playerLayer.frame = self.bounds;
    
    self.playOrPauseButton.frame = CGRectMake(5, self.frame.size.height - 30, 30, 30);
    
    self.progressView.frame = CGRectMake(40, self.frame.size.height - 16, self.frame.size.width - 80, 1);
    self.slider.frame = CGRectMake(39, self.frame.size.height - 20, self.frame.size.width - 80, 10);
}

#pragma mark - notification

- (void)playFinished:(NSNotification *)notification {
    NSLog(@"play finished");
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                // 开始播放
                self.slider.maximumValue = CMTimeGetSeconds(self.player.currentItem.duration);
                self.readyToPlay = YES;
                [self playOrPause];
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                self.readyToPlay = NO;
                NSLog(@"加载失败");
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                self.readyToPlay = NO;
                NSLog(@"未知资源");
            }
                break;
            default:
                break;
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSTimeInterval totalDuration = CMTimeGetSeconds([playerItem duration]);
        [self.progressView setProgress:totalBuffer/totalDuration animated:YES];
        NSLog(@"当前已经缓存 %f", totalBuffer);
    }
}

#pragma mark - action

- (void)playOrPause {
    if (self.player.rate == 0) { // 暂停
        if (self.readyToPlay) {
            [self.playOrPauseButton setTitle:@"pause" forState:UIControlStateNormal];
            [self.player play];
        } else {
            NSLog(@"加载中.....");
        }
        
    } else if (self.player.rate == 1) { // 播放
        [self.playOrPauseButton setTitle:@"play" forState:UIControlStateNormal];
        [self.player pause];
    }
}

- (void)sliderPress {
    [self.player pause];
    CMTime time = CMTimeMakeWithSeconds(self.slider.value, self.player.currentTime.timescale);
    [self.player seekToTime:time completionHandler:^(BOOL finished) {
        [self.player play];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

#pragma mark - lazy get

- (AVPlayer *)player {
    if (!_player) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://fus.cdn.krcom.cn/00407FcNlx07gMMOtn0k0104020jqJbr0k0e.mp4?label=mp4_1080p&template=27&Expires=1514296788&ssig=OsJ7qmRTh5&KID=unistore,video"]];
        _player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    return _player;
}

- (UIButton *)playOrPauseButton {
    if (!_playOrPauseButton) {
        _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playOrPauseButton setTitle:@"play" forState:UIControlStateNormal];
        [_playOrPauseButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _playOrPauseButton.backgroundColor = [UIColor grayColor];
        _playOrPauseButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_playOrPauseButton addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playOrPauseButton;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor grayColor];
        _progressView.trackTintColor = [UIColor whiteColor];
    }
    return _progressView;
}

- (UISlider *)slider {
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        _slider.minimumValue = 0;
        _slider.minimumTrackTintColor = [UIColor blueColor];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        _slider.thumbTintColor = [UIColor whiteColor];
        [_slider addTarget:self action:@selector(sliderPress) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

@end
