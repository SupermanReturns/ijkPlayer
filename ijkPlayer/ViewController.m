//
//  ViewController.m
//  ijkPlayer
//
//  Created by Superman on 2018/6/21.
//  Copyright © 2018年 Superman. All rights reserved.
//

// 屏幕的宽
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height

#import "ViewController.h"
#import "SMediaView.h"
#import "Masonry.h"
#import "MZObjectExt.h"

@interface ViewController ()

@property (nonatomic, strong) SMediaView *mediaPlayerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self addVideoPlayer];
    int i=1;

    NSString *path = [[NSBundle mainBundle] pathForResource:@"my_video" ofType:@"MP4"];

    [self.mediaPlayerView playWithURL:[NSURL URLWithString:path] title:@"视频播放" type:i];

    __weak id weakSelf = self;
    [self.mediaPlayerView setBackBlock:^(){
        [weakSelf popViewController];
    }];
    [self.mediaPlayerView.player play];

}
// 添加视频播放器
- (void)addVideoPlayer
{
    self.mediaPlayerView = [[SMediaView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenWidth / 16.f * 9.f)];
    [self.view addSubview:self.mediaPlayerView];
    [self.mediaPlayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(0);
        make.left.right.equalTo(self.view);
        // 注意此处，宽高比16：9优先级比1000低就行，在因为iPhone 4S宽高比不是16：9
        make.height.equalTo(self.mediaPlayerView.mas_width).multipliedBy(9.f /16.f).with.priority(750);
    }];
}
- (void)popViewController
{
    if (self.view.width > self.view.height) {
        
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationPortrait;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
        }
        return;
    }
    // 处理播放器移除通知
    [self.mediaPlayerView.player shutdown];
    [self.mediaPlayerView removeMovieNotificationObservers];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mediaPlayerView.player pause];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
