//
//  LTPlayerView.m
//  LTPlayer
//
//  Created by lt on 2017/12/25.
//  Copyright © 2017年 lt. All rights reserved.
//

#import "LTPlayerView.h"

CGFloat const gestureMinimumTranslation = 0.0;

@interface LTPlayerView ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIButton *playOrPauseButton;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UISlider *slider;

@property (nonatomic, assign) BOOL readyToPlay;
@property (nonatomic, assign) VideoMoveDirection direction;

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
    
    UISlider *slider = self.slider;
    //这里设置每秒执行一次
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current=CMTimeGetSeconds(time);
        NSLog(@"当前已经播放%.2fs.",current);
        if (current) {
            [slider setValue:(current) animated:YES];
        }
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause)];
    tapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self addGestureRecognizer:panGesture];
    
}

- (void)layoutSubviews {
    self.playerLayer.frame = self.bounds;
    
    self.playOrPauseButton.frame = CGRectMake(5, self.frame.size.height - 30, 30, 30);
    
    self.progressView.frame = CGRectMake(40, self.frame.size.height - 16, self.frame.size.width - 80, 1);
    self.slider.frame = CGRectMake(38, self.frame.size.height - 20, self.frame.size.width - 80 + 2, 10);
}

- (VideoMoveDirection)determineCameraDirectionIfNeeded:(CGPoint)translation {

    if (self.direction != ltVideoMoveDirectionNone)
        return self.direction;
    
    // determine if horizontal swipe only if you meet some minimum velocity
    if (fabs(translation.x) > gestureMinimumTranslation) {
        BOOL gestureHorizontal = NO;
        if (translation.y ==0.0)
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) >5.0);
        
        if (gestureHorizontal) {
            if (translation.x >0.0)
                return ltVideoMoveDirectionRight;
            else
                return ltVideoMoveDirectionLeft;
        }
    }
    // determine if vertical swipe only if you meet some minimum velocity
    else if (fabs(translation.y) > gestureMinimumTranslation) {
        BOOL gestureVertical = NO;
        if (translation.x ==0.0)
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) >5.0);
        
        if (gestureVertical) {
            if (translation.y >0.0)
                return ltVideoMoveDirectionDown;
            else
                return ltVideoMoveDirectionUp;
        }
    }
    
    return self.direction;
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
    }
}

#pragma mark - action

- (void)playOrPause {
    if (self.player.rate == 0) { // 暂停
        [self play];
    } else if (self.player.rate == 1) { // 播放
        [self pause];
    }
}

- (void)panAction:(UIPanGestureRecognizer *)pan {
    CGPoint translationPoint = [pan translationInView:pan.view];
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.direction = ltVideoMoveDirectionNone;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        if (self.direction == ltVideoMoveDirectionNone) {
            self.direction = [self determineCameraDirectionIfNeeded:translationPoint];
        }
        
        switch (self.direction) {
            case ltVideoMoveDirectionRight:
            case ltVideoMoveDirectionLeft:
            {   // 进度调整
                [self pause];
                break;
            }
            case ltVideoMoveDirectionUp:
            case ltVideoMoveDirectionDown:
                
                break;
            default:
                break;
        }
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        if (self.direction == ltVideoMoveDirectionRight || self.direction == ltVideoMoveDirectionLeft) {
            double distance = translationPoint.x;
            double nowTime = CMTimeGetSeconds(self.player.currentItem.currentTime);
            NSLog(@"%f",distance);
            CMTime time = CMTimeMake(nowTime + distance * 0.3, NSEC_PER_SEC);
            [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {}];
            [self play];
        }
    }
}

- (void)play {
    if (self.readyToPlay) {
        [self.playOrPauseButton setTitle:@"pause" forState:UIControlStateNormal];
        [self.player play];
    } else {
        NSLog(@"加载中.....");
    }
}

- (void)pause {
    [self.playOrPauseButton setTitle:@"play" forState:UIControlStateNormal];
    [self.player pause];
}

// 正在拖动
- (void)sliderDraging {
    [self pause];
    CMTime time = CMTimeMakeWithSeconds(self.slider.value, NSEC_PER_SEC);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {

    }];
}

// 拖动结束
- (void)sliderDragEnd {
    [self play];
}



- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

#pragma mark - lazy get

- (AVPlayer *)player {
    if (!_player) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"https://gslb.miaopai.com/stream/Wc6k9F3DE9KtS05SgnLeaQU-ifuqIpInvyZUGg__.mp4?yx=&refer=weibo_app&Expires=1514459398&ssig=pmfkvagrSS&KID=unistore,video"]];
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
        _slider.thumbTintColor = [UIColor redColor];
        [_slider addTarget:self action:@selector(sliderDraging) forControlEvents:UIControlEventValueChanged];
        [_slider addTarget:self action:@selector(sliderDragEnd) forControlEvents:UIControlEventTouchUpInside];
    }
    return _slider;
}

@end
