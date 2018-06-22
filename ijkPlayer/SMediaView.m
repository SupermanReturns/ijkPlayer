//
//  SMediaView.m
//  ijkPlayer
//
//  Created by Superman on 2018/6/21.
//  Copyright © 2018年 Superman. All rights reserved.
//
#define ScreenScale ([UIScreen mainScreen].bounds.size.width / 414.f)


#import "SMediaView.h"
#import "Masonry.h"


@interface SMediaView()
/** 开始播放按钮 */
@property (nonatomic, strong) UIButton                *startBtn;
/** 当前播放时长label */
@property (nonatomic, strong) UILabel                 *currentTimeLabel;
/** 视频总时长label */
@property (nonatomic, strong) UILabel                 *totalTimeLabel;
/** 缓冲进度条 */
@property (nonatomic, strong) UIProgressView          *progressView;
/** 滑杆 */
@property (nonatomic, strong) UISlider                *videoSlider;
/** 全屏按钮 */
@property (nonatomic, strong) UIButton                *fullScreenBtn;

/** 系统菊花 */
@property (nonatomic, strong) UIActivityIndicatorView *activity;

/** 返回按钮*/
@property (nonatomic, strong) UIButton                *backBtn;

/** 标题label */
@property (nonatomic, strong) UILabel                 *titleLabel;

/** 重播按钮 */
@property (nonatomic, strong) UIButton                *repeatBtn;

/** 错误提示 */
@property (nonatomic, strong) UILabel                 *playErrorLable;

/** bottomView*/
@property (nonatomic, strong) UIImageView             *bottomImageView;

/** topView */
@property (nonatomic, strong) UIImageView             *topImageView;

@property (nonatomic, assign) BOOL isMediaSliderBeingDragged;

@property (nonatomic, assign) BOOL isCoverHiden;
@end


@implementation SMediaView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self addSubview:self.topImageView];
        [self.topImageView addSubview:self.titleLabel];
        [self.topImageView addSubview:self.backBtn];
        
        [self addSubview:self.bottomImageView];
        [self.bottomImageView addSubview:self.startBtn];
        [self.bottomImageView addSubview:self.currentTimeLabel];
        [self.bottomImageView addSubview:self.progressView];
        [self.bottomImageView addSubview:self.videoSlider];
        [self.bottomImageView addSubview:self.fullScreenBtn];
        [self.bottomImageView addSubview:self.totalTimeLabel];
        
        [self addSubview:self.activity];
        [self addSubview:self.repeatBtn];
        [self addSubview:self.playErrorLable];
        
        // 为控件设置frame
        [self makeSubViewsConstraints];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)playWithURL:(NSURL *)url title:(NSString *)title type:(int)type
{
    self.titleLabel.text = title;
    
    // 显示进度条相关
    if (type != 1) {
        _startBtn.hidden = NO;
        _progressView.hidden = NO;
        _videoSlider.hidden = NO;
        _currentTimeLabel.hidden = NO;
        _totalTimeLabel.hidden = NO;
    }
    
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    
    //    [options setFormatOptionIntValue:2000000 forKey:@"analyzeduration"];
    //    [options setFormatOptionValue:@"nobuffer" forKey:@"fflags"];
    //    [options setFormatOptionIntValue:4096 forKey:@"probsize"];
    //    [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
    
    //    NSURL *urls = [NSURL URLWithString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    if( self.player != nil ) {
        if([self.player isPlaying]){
            [self.player stop];
        }
        [self.player.view removeFromSuperview];
        self.player = nil;
    }
    NSString *str=[url absoluteString];
    
    //    if ([str containsString:@"https://ggfw.guoanshequ.top"]) {
    //        str=[str stringByReplacingOccurrencesOfString:@"https://ggfw.guoanshequ.top" withString:@"http://test.guoanshequ.top:8000"];
    ////        http://bjapi.guoanshequ.top:8080      http://test.guoanshequ.top:8000
    //    }
    
    
    url =[NSURL URLWithString:str];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = self.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    self.autoresizesSubviews = YES;
    [self addSubview:self.player.view];
    
    // 菊花开始转
    [self.activity startAnimating];
    
    // 初始化view
    [self initControlView];
    
    // 初始化定时器
    [self refreshMediaControl];
    
    // 添加通知
    [self installMovieNotificationObservers];
    
    // 准备播放
    [self.player prepareToPlay];
}


////////////////////////////////////////////////////////////////////////////////

// 点击屏幕
- (void)tapGesture:(UITapGestureRecognizer *)tap
{
    //    if ([self.player isKindOfClass:[IJKFFMoviePlayerController class]]) {
    //        IJKFFMoviePlayerController *player = self.player;
    //        player.shouldShowHudView = !_isCoverHiden;
    //    }
    
    // 隐藏
    if (_isCoverHiden) {
        
        [self showControlView];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
        
        [self refreshMediaControl];
        
        [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5.f];
    } else {
        
        [self hideControlView];
        
    }
}

- (void)backBtnAction:(UIButton *)button
{
    if (self.backBlock) {
        self.backBlock();
    }
}

// 重播按钮点击
- (void)repeatBtnAction:(UIButton *)button
{
    self.repeatBtn.hidden = YES;
    [self.player play];
}

#pragma mark - 全屏按钮点击
- (void)fullScreenAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    UIDeviceOrientation orientation             = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
            
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"下");
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"右");
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"左");
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
            
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"右");
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
            
        }
            break;
            
        default: {
            
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
            
        }
            break;
    }
}

#pragma mark 屏幕转屏相关

/**
 *  强制屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    // arc下
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        // 从2开始是因为0 1 两个参数已经被selector和target占用
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}


#pragma mark - slider action
- (void)videoSliderTouchBegan:(UISlider *)slider
{
    _isMediaSliderBeingDragged = YES;
}

- (void)videoSliderTouchEnded:(UISlider *)slider
{
    self.player.currentPlaybackTime = slider.value;
    _isMediaSliderBeingDragged = NO;
}
- (void)videoSliderValueChanged:(UISlider *)slider
{
    _repeatBtn.hidden=YES;
    [self refreshMediaControl];
}

// 点击slider
- (void)tapSliderAction:(UITapGestureRecognizer *)tap
{
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point = [tap locationInView:slider];
        CGFloat length = slider.frame.size.width;
        // 视频跳转的value
        CGFloat tapValue = point.x / length;
        self.player.currentPlaybackTime = tapValue * self.player.duration;
    }
}

- (void)refreshMediaControl
{
    // duration
    NSTimeInterval duration = self.player.duration;
    NSInteger intDuration = duration + 0.5;
    if (intDuration > 0) {
        self.videoSlider.maximumValue = duration;
        self.totalTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
    } else {
        self.totalTimeLabel.text = @"00:00";
        self.videoSlider.maximumValue = 1.0f;
    }
    
    // position
    NSTimeInterval position;
    if (_isMediaSliderBeingDragged) {
        position = self.videoSlider.value;
    } else {
        position = self.player.currentPlaybackTime;
    }
    NSInteger intPosition = position + 0.5;
    if (intDuration > 0) {
        self.videoSlider.value = position;
    } else {
        self.videoSlider.value = 0.0f;
    }
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
    
    // status
    BOOL isPlaying = [self.player isPlaying];
    self.startBtn.selected = !isPlaying;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    
    if (!_isCoverHiden) {
        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    }
    
}


// 播放按钮点击
- (void)playAndPauseBtnClick:(UIButton *)button
{
    button.selected = !button.selected;
    if (button.selected) {
        
        [self.player pause];
    } else {
        [self.player play];
    }
}

// 初始化View
- (void)initControlView
{
    self.videoSlider.value      = 0;
    self.progressView.progress  = 0;
    self.currentTimeLabel.text  = @"00:00";
    self.totalTimeLabel.text    = @"00:00";
    self.repeatBtn.hidden       = YES;
    
    [self bringSubviewToFront:self.topImageView];
    [self bringSubviewToFront:self.bottomImageView];
    
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:5.f];
}

// 显示
- (void)showControlView
{
    self.topImageView.alpha    = 1;
    self.bottomImageView.alpha = 1;
    _isCoverHiden = NO;
}

// 隐藏
- (void)hideControlView
{
    self.topImageView.alpha    = 0;
    self.bottomImageView.alpha = 0;
    _isCoverHiden = YES;
}

- (void)makeSubViewsConstraints
{

    [self.topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(self);
        make.height.mas_equalTo(50);
    }];
    
    [self.bottomImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.height.mas_equalTo(50);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(5);
        make.width.height.mas_equalTo(40);
        make.top.mas_equalTo(0);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topImageView).offset(50 * ScreenScale);
        make.right.equalTo(self.topImageView).offset(-50 * ScreenScale);
        make.height.mas_equalTo(30);
        make.centerY.equalTo(self.backBtn);
    }];
    
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomImageView.mas_leading).offset(5);
        make.bottom.equalTo(self.bottomImageView.mas_bottom).offset(-5);
        make.width.height.mas_equalTo(30);
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.startBtn.mas_trailing).offset(-3);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(30);
        make.trailing.equalTo(self.bottomImageView.mas_trailing).offset(-5);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.fullScreenBtn.mas_leading).offset(3);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.currentTimeLabel.mas_centerY).offset(-1);
        make.height.mas_equalTo(30);
    }];
    

    
    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self.repeatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self.playErrorLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
}


- (UIImageView *)topImageView
{
    if (!_topImageView) {
        _topImageView                        = [[UIImageView alloc] init];
        _topImageView.userInteractionEnabled = YES;
        _topImageView.image                  = [UIImage imageNamed:@"ZFPlayer_top_shadow"];
    }
    return _topImageView;
}

- (UIImageView *)bottomImageView
{
    if (!_bottomImageView) {
        _bottomImageView                        = [[UIImageView alloc] init];
        _bottomImageView.userInteractionEnabled = YES;
        _bottomImageView.image                  = [UIImage imageNamed:@"ZFPlayer_bottom_shadow"];
    }
    return _bottomImageView;
}

- (UIButton *)startBtn
{
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setImage:[UIImage imageNamed:@"ZFPlayer_pause"] forState:UIControlStateNormal];
        [_startBtn setImage:[UIImage imageNamed:@"ZFPlayer_play"] forState:UIControlStateSelected];
        [_startBtn addTarget:self action:@selector(playAndPauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel               = [[UILabel alloc] init];
        _currentTimeLabel.textColor     = [UIColor whiteColor];
        _currentTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView                   = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

- (UISlider *)videoSlider
{
    if (!_videoSlider) {
        _videoSlider                       = [[UISlider alloc] init];
        // 设置slider
        [_videoSlider setThumbImage:[UIImage imageNamed:@"ZFPlayer_slider"] forState:UIControlStateNormal];
        _videoSlider.maximumValue          = 1;
        _videoSlider.minimumTrackTintColor = [UIColor whiteColor];
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        
        // slider开始滑动事件
        [_videoSlider addTarget:self action:@selector(videoSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        // slider滑动中事件
        [_videoSlider addTarget:self action:@selector(videoSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        // slider结束滑动事件
        [_videoSlider addTarget:self action:@selector(videoSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [_videoSlider addGestureRecognizer:sliderTap];
    }
    return _videoSlider;
}

- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel               = [[UILabel alloc] init];
        _totalTimeLabel.textColor     = [UIColor whiteColor];
        _totalTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenBtn
{
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_fullscreen"] forState:UIControlStateNormal];
        //        [_fullScreenBtn setImage:[UIImage imageNamed:(@"ZFPlayer_shrinkscreen")] forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenBtn;
}

- (UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"ZFPlayer_back_full"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:17 * ScreenScale];
        _titleLabel.textColor = [UIColor whiteColor];
//        _titleLabel.backgroundColor=[UIColor yellowColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)repeatBtn
{
    if (!_repeatBtn) {
        _repeatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_repeatBtn setImage:[UIImage imageNamed:@"ZFPlayer_repeat_video"] forState:UIControlStateNormal];
        [_repeatBtn addTarget:self action:@selector(repeatBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _repeatBtn;
}

- (UIActivityIndicatorView *)activity
{
    if (!_activity) {
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    return _activity;
}

- (UILabel *)playErrorLable
{
    if (!_playErrorLable) {
        _playErrorLable = [[UILabel alloc] init];
        _playErrorLable.text = @"播放失败";
        _playErrorLable.textColor = [UIColor whiteColor];
        _playErrorLable.font = [UIFont systemFontOfSize:16 * ScreenScale];
        [_playErrorLable sizeToFit];
//        _playErrorLable.hidden = YES;
    }
    return _playErrorLable;
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)loadStateDidChange:(NSNotification*)notification
{
    //    MPMovieLoadStateUnknown        = 0,
    //    MPMovieLoadStatePlayable       = 1 << 0,
    //    MPMovieLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    //    MPMovieLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification
{
    //    MPMovieFinishReasonPlaybackEnded,
    //    MPMovieFinishReasonPlaybackError,
    //    MPMovieFinishReasonUserExited
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason)
    {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            self.repeatBtn.hidden = NO;
            [self bringSubviewToFront:self.repeatBtn];
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            
            [self.activity stopAnimating];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AppNotification.showText" object:@"播放失败！"];
            //            self.playErrorLable.hidden = NO;
            //            [self bringSubviewToFront:self.playErrorLable];
            self.fullScreenBtn.hidden = YES;
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification
{
    //    MPMoviePlaybackStateStopped,
    //    MPMoviePlaybackStatePlaying,
    //    MPMoviePlaybackStatePaused,
    //    MPMoviePlaybackStateInterrupted,
    //    MPMoviePlaybackStateSeekingForward,
    //    MPMoviePlaybackStateSeekingBackward
    
    switch (_player.playbackState)
    {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            [self.activity stopAnimating];
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(OrientationDidChange:)name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)OrientationDidChange:(NSNotification *)note  {
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
    switch (o) {
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
            //            [self  rotation_icon:0.0];
            [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_fullscreen"] forState:UIControlStateNormal];
            break;
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            //            [self  rotation_icon:180.0];
            NSLog(@"向下");
            
            [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_fullscreen"] forState:UIControlStateNormal];
            break;
        case UIDeviceOrientationLandscapeLeft:      // Device oriented horizontally, home button on the right
            [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_shrinkscreen"] forState:UIControlStateNormal];
            NSLog(@"向左");
            
            //            [self  rotation_icon:90.0*3];
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_shrinkscreen"] forState:UIControlStateNormal];
            NSLog(@"向右");
            
            //            [self  rotation_icon:90.0];
            break;
        default:
            break;
    }
}


#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:_player];
    
}



@end
