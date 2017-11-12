# SimpleMaskAnimation
一个简单的遮罩动画

### 需求
近期工作需求一个展示任务进度的动画，通过填充现有进度图的方式展示，并且有里程碑的节点需要配合数据进行暂停。好吧，文字讲得我自己都很难理解，来看一下效果吧。

![](http://ojam5z7vg.bkt.clouddn.com/coldreading/gif/animation.gif)

红色的填充为当前的进度，验证登录阶段到导入账单阶段（导入阶段到完成）是有一个里程碑的节点的，所以需要通过数据来控制进度，让红色的进度条暂停在某一个位置等待数据。
<!--more-->
### 方案思考
#### 1.动画部分
展示一下层次结构，一切一目了然

![](http://ojam5z7vg.bkt.clouddn.com/coldreading/jpg/%E9%81%AE%E7%BD%A9%E5%9B%BE%E5%B1%82.png)

简单的来讲：其实是有两个进度控制View，分别是灰色和红色，这里称红色的为maskView，灰色为bottomView。

在结构层次图中可以意识到只要让maskView有个位移动画就可以满足我们的需求。
__注意__：这个位移动画并不是`UIView`层面的动画，单纯移动整个maskView其实是会造成bottomView和maskView图标错位的现象，这并不是想要的效果。
正确的是对maskView`layer`的`maskLayer`层进行动画操作。

__实现思路__：让maskView的`maskLayer`初始位置在maskView的`frame`之外的左侧。动画开始之后让`maskLayer`慢慢向右移动，达到红色慢慢向右填充的效果。对`maskLayer`使用的动画可以是`CABasicAnimation` 或者`CAKeyframeAnimation`。此demo中使用关键帧动画 `CAKeyframeAnimation`

##### 关键代码示例：

``` objectivec
//初始化maksView的maskLayer位置
    CALayer *maskLayer; = [CALayer layer];
    maskLayer.backgroundColor = [[UIColor whiteColor] CGColor]; //任何颜色，用到的只是alpha
    maskLayer.anchorPoint = CGPointZero;
    maskLayer.frame = CGRectOffset(self.frame,-CGRectGetWidth(self.frame), 0);
    self.layer.mask = maskLayer;
```

``` objectivec
//开始动画
    NSArray *values = @[[NSValue valueWithCGPoint:CGPointMake(-CGRectGetWidth(self.frame), 0)],
                        [NSValue valueWithCGPoint:CGPointMake(0, 0)]];
    
    CGFloat duration = 4.0;
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.values = values;
    animation.duration = duration;
    animation.delegate = self;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [maskLayer addAnimation:animation forKey:@"MaskAnimation"];
```

#### 2.进度控制部分

*如果只需要本文刚开始的贴图那样的效果，第一部分已经足够了。*

第一部分只是解决了生成动画的问题，使用`CAKeyframeAnimation`对`maskLayer`进行关键帧动画是比较常见的做法，如果对`CAKeyframeAnimation`或者`CABasicAnimation`使用不熟悉可以参阅[《iOS核心动画》缓冲](https://zsisme.gitbooks.io/ios-/content/chapter10/easing.html)

接下来要完成的是根据数据状态来控制动画，简单梳理了下我们要完成的目标：

|状态|动画描述|
|:-:|:-:|
|登录中|红色maskLayer开始向右移动|
|登录超时|红色maskLayer移动暂停在1，2两个图标之间的进度条间|
|登录成功|红色maskLayer继续向右移动|
|导入中|红色maskLayer继续向右移动到2至3部分|
|导入超时|红色maskLayer移动暂停在2，3两个图标之间的进度条间|
|导入完成|红色maskLayer继续完成剩下的动画|
|提前完成|直接从当前的百分比位置快速完成剩下的动画|
|恢复进度|从任意进度恢复动画|

抛开是数据，我们要完成的是以下五点：

1. 设定超时机制
2. 暂停动画
3. 恢复动画
4. 从任意进度值初始化动画
5. 从当前进度值快速完成动画

---
##### 2.1 设定超时机制

这一步其实比较简单

先设定默认的登录超时时间和导入超时时间

``` objectivec
static const CGFloat kGeneralLoginTime = 20.0;
static const CGFloat kGeneralImportTime = 30.0;
```

在视图中创建一个定时器，从动画开始计算经过的时间，与默认的时间判断是否在该状态已经超时。

``` objectivec
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
```

---
##### 2.2 暂停动画

``` objectivec
//暂停动画
- (void)pauseLayer {
    CFTimeInterval pausedTime = [_maskLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.layer.speed = 0.0;
    self.layer.timeOffset = pausedTime;
} 
```


---
##### 2.3 恢复动画

``` objectivec
//恢复动画
- (void)resumeLayer {
    CFTimeInterval pausedTime = [self.layer timeOffset];
    self.layer.speed = 1.0;
    self.layer.timeOffset = 0.0;
    self.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [_maskLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.layer.beginTime = timeSincePause;
}
``` 

---
##### 2.4 从任意进度值初始化

``` objectivec
//设置一个startVlaue的初始化值
- (void)setStartValue:(CGFloat)startValue {
    [self stopAnimation];
    _startValue = startValue;
    //_lastPresentPosition为maskLayer上一次展示position属性
    _lastPresentPosition = CGPointMake(startValue * CGRectGetWidth(self.frame) - CGRectGetWidth(self.frame), 0);
    [self resumeLayer];
    [self startAnimation];
}
```

``` objectivec
//从上一次动画
- (void)startAnimation {
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
```

##### 2.5 从当前进度值快速完成动画

``` objectivec
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
```

上面代码片段中的`_advancedFinishDuring`动画时间，是根据触发快速完成动画时的进度值百分比 乘以 快速完成动画所需要的总时间计算出来的。下面是计算的一个例子：

``` objectivec
- (void)verifySuccess {
    [self resumeLayer];
    self.status = Importing;
    self.displayLink.paused = NO;
    if (!self.loginSuccessTime) {
        self.loginSuccessTime = self.currentTime;
    }
    self.advancedFinishDuring = ((-_lastPresentPosition.x) / CGRectGetWidth(self.frame)) * kGeneralCacheCompleteTime;
}
```

 __至此进度控制就可以的需求就可以使用以上的关键方法完成了__, 查看完成的逻辑可以下载demo查看
  [Demo地址](https://github.com/HuyangJake/SimpleMaskAnimation)
 ![demo](http://ojam5z7vg.bkt.clouddn.com/coldreading/jpg/maskAnimation.png-blog)

### 不足
* 进度控制部分的超时跟maskLayer位置的对应关系比较生硬


*个人对动画理解还不深，代码笨拙。还请朋友多批评指教！*






