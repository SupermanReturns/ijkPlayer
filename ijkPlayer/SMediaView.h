//
//  SMediaView.h
//  ijkPlayer
//
//  Created by Superman on 2018/6/21.
//  Copyright © 2018年 Superman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IJKMediaFramework/IJKMediaFramework.h>

typedef void(^backBtnActionBlock)();

@interface SMediaView : UIView
@property (nonatomic, copy) backBtnActionBlock backBlock;

@property(atomic, retain) id <IJKMediaPlayback> player;
- (instancetype)initWithFrame:(CGRect)frame;


- (void)playWithURL:(NSURL *)url title:(NSString *)title type:(int)type;

// 移除通知
- (void)removeMovieNotificationObservers;
@end
