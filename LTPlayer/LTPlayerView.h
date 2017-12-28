//
//  LTPlayerView.h
//  LTPlayer
//
//  Created by lt on 2017/12/25.
//  Copyright © 2017年 lt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum :NSInteger {
    ltVideoMoveDirectionNone,
    ltVideoMoveDirectionUp,
    ltVideoMoveDirectionDown,
    ltVideoMoveDirectionRight,
    ltVideoMoveDirectionLeft
} VideoMoveDirection;

@interface LTPlayerView : UIView

@end
