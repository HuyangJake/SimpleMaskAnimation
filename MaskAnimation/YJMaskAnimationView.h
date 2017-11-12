//
//  YJMaskAnimationView.h
//  
//
//  Created by Jake Hu on 2017/9/29.
//  Copyright © 2017年 Jakey. All rights reserved.
//

#import <UIKit/UIKit.h>

//以下业务展示相关参数，只是想了解动画实现可以忽略

typedef NS_ENUM(NSUInteger, YJStage) {
    Logining,
    Importing,
    Complete,
};

static const CGFloat kGeneralLoginTime = 20.0;
static const CGFloat kGeneralImportTime = 30.0;
static const CGFloat kGeneralCacheCompleteTime = 3.0;

//以上业务展示相关参数，只是想了解动画实现可以忽略

@interface YJMaskAnimationView : UIView
//开始的位置百分比(0~1), 在开始动画前赋值，用于动画进度的恢复
@property (nonatomic, assign) CGFloat startValue;

/**
 初始化视图
 
 @param frame frame大小
 @param color 蒙版颜色
 @return QLLoopStagementView对象
 */
- (instancetype)initWithFrame:(CGRect)frame maskColor:(UIColor *)color;

- (void)startAnimation;//开始动画

- (void)pauseAnimation;//暂停动画

- (void)resumeAnimation;//恢复动画

- (void)stopAnimation;//停止动画

- (void)reset;//重置并开始动画

//以下方法为业务相关方法，demo中对应开始导入，登录成功，导入成功这个几个节点做示例

- (void)waitForVerify; //等待验证（暂停动画）

- (void)waitForImport; //等待导入 (暂停动画)

- (void)verifySuccess;//登录验证成功 (恢复动画)

- (void)importComplete;//导入完成 (恢复动画，触发提前完成动画)

@end
