//
//  YJMaskAnimationView.m
//
//
//  Created by Jake Hu on 2017/9/29.
//  Copyright © 2017年 Jakey. All rights reserved.
//

#import "YJMaskAnimationView.h"
#import "Masonry.h"

@interface YJMaskAnimationView()<CAAnimationDelegate>
@property (nonatomic, strong) UIImageView *firstImg;
@property (nonatomic, strong) UIImageView *secondImg;
@property (nonatomic, strong) UIImageView *thirdImg;

@property (nonatomic, strong) CALayer *maskLayer;
@property (nonatomic, strong) CALayer *originLayer;
@property (nonatomic, strong) UIColor *color;//遮罩的颜色

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat advancedFinishDuring;//提前完成时的动画时间

@property (nonatomic, assign) NSInteger currentTime;//当前时间
@property (nonatomic, assign) YJStage status;//当前状态
@property (nonatomic, assign) NSInteger loginSuccessTime;//登录成功的时间
@property (nonatomic, assign) CGPoint lastPresentPosition;//上一次动画的位置
@end

@implementation YJMaskAnimationView

#pragma mark - lifeCircle

- (instancetype)initWithFrame:(CGRect)frame maskColor:(UIColor *)color {
    if (!color) {
        self = [super initWithFrame:frame];
        self.backgroundColor = [UIColor clearColor];
    } else {
        self = [self initWithFrame:frame];
    }
    if (self) {
        self.color = color;
        [self createUI];
        [self initValue];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _maskLayer = [CALayer layer];
        _maskLayer.backgroundColor = [[UIColor whiteColor] CGColor]; //任何颜色，用到的只是alpha
        _maskLayer.anchorPoint = CGPointZero;
        _maskLayer.frame = CGRectOffset(self.frame, -CGRectGetWidth(self.frame), 0);
        _originLayer = self.layer.mask;
        self.layer.mask = _maskLayer;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)initValue
{
    _currentTime = 0;
    _advancedFinishDuring = kGeneralCacheCompleteTime;
    _status = Logining;
    _lastPresentPosition = CGPointMake(-CGRectGetWidth(self.frame), 0);
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkEvent)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _displayLink.paused = YES;
}

- (void)setStartValue:(CGFloat)startValue {
    [self stopAnimation];
    _startValue = startValue;
    _lastPresentPosition = CGPointMake(startValue * CGRectGetWidth(self.frame) - CGRectGetWidth(self.frame), 0);
    [self resumeLayer];
    [self startAnimation];
}

#pragma mark - Actions

- (void)pauseAnimation {
    [self pauseLayer];
    self.displayLink.paused = YES;
}

- (void)resumeAnimation {
    [self resumeLayer];
}

- (void)verifySuccess {
    [self resumeLayer];
    self.status = Importing;
    self.displayLink.paused = NO;
    if (!self.loginSuccessTime) {
        self.loginSuccessTime = self.currentTime;
    }
    self.advancedFinishDuring = ((-_lastPresentPosition.x) / CGRectGetWidth(self.frame)) * kGeneralCacheCompleteTime;
}

- (void)importComplete {
    [self resumeLayer];
    self.status = Complete;
    self.displayLink.paused = NO;
    //计算提前完成动画剩余需要的时间
    self.advancedFinishDuring = ((-_lastPresentPosition.x) / CGRectGetWidth(self.frame)) * kGeneralCacheCompleteTime;
    //触发提前完成动画
    [self animationAdvancedFinished];
}

- (void)waitForVerify {
    [self pauseLayer];
    self.displayLink.paused = YES;
}

- (void)waitForImport {
    [self pauseLayer];
    self.displayLink.paused = YES;
}

- (void)startAnimation {
    if (_displayLink.isPaused == NO) {
        return;
    }
    NSArray *values = @[[NSValue valueWithCGPoint:_lastPresentPosition],
                        [NSValue valueWithCGPoint:CGPointMake(0, 0)]];
    
    CGFloat duration = kGeneralLoginTime + kGeneralImportTime + 1;
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.values = values;
    animation.duration = duration;
    animation.delegate = self;
    //自然导入完成之后不保留mask层的位置信息，回归到初始位置
    animation.fillMode = kCAFillModeRemoved;
    animation.removedOnCompletion = YES;
    [_maskLayer addAnimation:animation forKey:@"MaskAnimation"];
    _displayLink.paused = NO;
}

- (void)stopAnimation {
    self.displayLink.paused = YES;
    [self pauseLayer];
    self.lastPresentPosition = CGPointMake(-CGRectGetWidth(self.frame), 0);
}

//  提前结束动画
- (void)animationAdvancedFinished
{
    [self resumeLayer];
    
    CGFloat duration = _advancedFinishDuring;
    NSArray *values = @[[NSValue valueWithCGPoint:_lastPresentPosition],
                        [NSValue valueWithCGPoint:CGPointMake(0, 0)]];
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.values = values;
    animation.duration = duration;
    animation.delegate = self;
    //提前结束动画完成之后保留mask层的位置信息，保持动画完成时的样式
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [_maskLayer addAnimation:animation forKey:@"AdvancedMaskAnimation"];
}

- (void)reset {
    self.currentTime = 0;
    self.loginSuccessTime = 0;
    self.lastPresentPosition = CGPointMake(-CGRectGetWidth(self.frame), 0);
    self.displayLink.paused = YES;
    [self startAnimation];
}

/**业务逻辑处理
    登录(或者导入)时间超过平常所需要的时间之后 暂停动画 等待登录(导入)完成
    如此保证进度条展示的进度正确
 */
- (void)displayLinkEvent {
    _currentTime ++;
    if (_currentTime == kGeneralLoginTime * 60 && self.status == Logining) {
        [self waitForVerify];
        NSLog(@"登录超时 %ld", _currentTime / 60);
    } else if (_currentTime - _loginSuccessTime == kGeneralImportTime * 60 && self.status == Importing) {
        [self waitForImport];
        NSLog(@"导入超时 %ld", (_currentTime - _loginSuccessTime)/60);
    }
    _lastPresentPosition = _maskLayer.presentationLayer.position;
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim {
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
//    self.layer.mask = _originLayer;
}

#pragma mark - Layer 动画的暂停和开始

- (void)pauseLayer
{
    CFTimeInterval pausedTime = [_maskLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.layer.speed = 0.0;
    self.layer.timeOffset = pausedTime;
}

//继续layer上面的动画
- (void)resumeLayer
{
    CFTimeInterval pausedTime = [self.layer timeOffset];
    self.layer.speed = 1.0;
    self.layer.timeOffset = 0.0;
    self.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [_maskLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.layer.beginTime = timeSincePause;
}

#pragma mark - UI

- (void)createUI {
    UIColor *color = self.color ? self.color : [UIColor lightGrayColor];
    
    UILabel *firstLabel = [[UILabel alloc] init];
    firstLabel.text = @"验证登录";
    firstLabel.textColor = color;
    firstLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:firstLabel];
    [firstLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-10);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(18);
    }];
    
    [self addSubview:self.firstImg];
    [self.firstImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(30, 24));
        make.centerX.equalTo(firstLabel.mas_centerX);
        make.bottom.mas_equalTo(firstLabel.mas_top).mas_equalTo(-10);
    }];
    
    UILabel *secondLabel = [[UILabel alloc] init];
    secondLabel.text = @"导入账单";
    secondLabel.textColor = color;
    secondLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:secondLabel];
    [secondLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-10);
        make.centerX.mas_equalTo(0);
        make.height.mas_equalTo(18);
    }];
    
    [self addSubview:self.secondImg];
    [self.secondImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(secondLabel.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(30, 24));
        make.bottom.mas_equalTo(secondLabel.mas_top).mas_equalTo(-10);
    }];
    
    UILabel *thirdLabel = [[UILabel alloc] init];
    thirdLabel.text = @"导入完成";
    thirdLabel.textColor = color;
    thirdLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:thirdLabel];
    [thirdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-10);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(18);
    }];
    
    [self addSubview:self.thirdImg];
    [self.thirdImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(thirdLabel.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(30, 24));
        make.bottom.mas_equalTo(thirdLabel.mas_top).mas_equalTo(-10);
    }];
    
    UIView *firstLine = [[UIView alloc] init];
    firstLine.backgroundColor = color;
    [self addSubview:firstLine];
    [firstLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.firstImg.mas_centerY);
        make.left.mas_equalTo(self.firstImg.mas_right).mas_equalTo(5);
        make.right.mas_equalTo(self.secondImg.mas_left).mas_equalTo(-5);
        make.height.mas_equalTo(2);
    }];
    
    UIView *secondLine = [[UIView alloc] init];
    secondLine.backgroundColor = color;
    [self addSubview:secondLine];
    [secondLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.firstImg.mas_centerY);
        make.left.mas_equalTo(self.secondImg.mas_right).mas_equalTo(5);
        make.right.mas_equalTo(self.thirdImg.mas_left).mas_equalTo(-5);
        make.height.mas_equalTo(2);
    }];
}

- (UIImageView *)firstImg {
    if (!_firstImg) {
        NSString *imgName = nil;
        if (self.color) {
            imgName = @"网银";
        } else {
            imgName = @"网银灰";
        }
        _firstImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];\
        _firstImg.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _firstImg;
}

- (UIImageView *)secondImg{
    if (!_secondImg) {
        NSString *imgName = nil;
        if (self.color) {
            imgName = @"已导入账单";
        } else {
            imgName = @"导入账单";
        }
        _secondImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
        _secondImg.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _secondImg;
}

- (UIImageView *)thirdImg {
    if (!_thirdImg) {
        NSString *imgName = nil;
        if (self.color) {
            imgName = @"导入完成";
        } else {
            imgName = @"等待";
        }
        _thirdImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]];
        _thirdImg.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _thirdImg;
}


@end
