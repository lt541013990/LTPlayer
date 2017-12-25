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

@end

@implementation LTPlayerView

- (instancetype)init {
    if (self = [super init]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:self.playerLayer];
    
    [self addSubview:self.playOrPauseButton];
    [self addSubview:self.progressView];
}

- (void)layoutSubviews {
    self.playerLayer.frame = self.frame;
    
}

#pragma mark - lazy get

- (AVPlayer *)player {
    if (!_player) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"]];
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        
    }
    return _player;
}

- (UIButton *)playOrPauseButton {
    if (!_playOrPauseButton) {
        _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playOrPauseButton setTitle:@"play" forState:UIControlStateNormal];
        _playOrPauseButton.titleLabel.textColor = [UIColor blueColor];
        _playOrPauseButton.titleLabel.font = [UIFont systemFontOfSize:13];
    }
    return _playOrPauseButton;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor blueColor];
        _progressView.trackTintColor = [UIColor grayColor];
    }
    return _progressView;
}

@end
