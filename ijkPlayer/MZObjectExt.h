//
//  MZObjectExtensionUtil.h
//  MZSpeaker
//
//  Created by hysteria 路. on 16/1/29.
//  Copyright © 2016年 AndLi Software Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (MZUIColorExt)

+ (nonnull UIColor *)colorWithHexString:(nonnull NSString *)hexString;

- (nonnull UIImage*)createImageWithSize:(CGSize)size;

@end

@interface NSString (MZNSStringExt)

- (CGSize)sizeWithFontCategory:(nonnull UIFont *)font constrainedToSize:(CGSize)size;

@end

@interface UIView (MZUIViewExt)

@property (nonatomic, strong, readonly, nullable) UIViewController *viewController;

@property (nonatomic, strong, readonly, nullable) UIViewController *parentViewController;

- ( NSArray * _Nullable )allSubviews;

- (void)removeAllSubviews;

@end

CGPoint CGRectGetCenter(CGRect rect);
CGRect  CGRectMoveToCenter(CGRect rect, CGPoint center);

/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */
@interface UIView (ViewFrameGeometry)
@property CGPoint origin;
@property CGSize size;

@property (readonly) CGPoint bottomLeft;
@property (readonly) CGPoint bottomRight;
@property (readonly) CGPoint topRight;

@property CGFloat height;
@property CGFloat width;

@property CGFloat top;
@property CGFloat left;

@property CGFloat bottom;
@property CGFloat right;

- (void) moveBy: (CGPoint) delta;
- (void) scaleBy: (CGFloat) scaleFactor;
- (void) fitInSize: (CGSize) aSize;
@end

@interface MZObjectExt : NSObject

+ (NSString * _Nullable)getIPAddress;


@end
