//
//  ViewController.m
//  MaskAnimation
//
//  Created by Jake Hu on 2017/10/29.
//  Copyright © 2017年 Jake Hu. All rights reserved.
//

#import "ViewController.h"
#import "YJMaskAnimationView.h"

@interface ViewController ()
@property (nonatomic, strong) YJMaskAnimationView *maskView;
@property (weak, nonatomic) IBOutlet UILabel *startValueLabel;
@property (nonatomic, assign) CGFloat startValue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    YJMaskAnimationView *view = [[YJMaskAnimationView alloc] initWithFrame:CGRectMake(20, 250, self.view.frame.size.width - 40, 80) maskColor:nil];
    
    [self.view addSubview:view];
    [self.view addSubview:self.maskView];
}

- (IBAction)tapStartBtn:(id)sender {
    [self.maskView startAnimation];
}

- (IBAction)tapEndBtn:(id)sender {
    [self.maskView stopAnimation];
}

- (IBAction)tapPauseBtn:(id)sender {
    [self.maskView pauseAnimation];
}

- (IBAction)tapResumeBtn:(id)sender {
    [self.maskView resumeAnimation];
}

- (IBAction)tapLoginSuccess:(id)sender {
    [self.maskView verifySuccess];
}

- (IBAction)tapImportSuccess:(id)sender {
    [self.maskView importComplete];
}

- (IBAction)tapBackToDefault:(id)sender {
    self.maskView = nil;
    self.startValue = 0.0;
    [self.maskView removeFromSuperview];
    [self.view addSubview:self.maskView];
}

- (IBAction)valueChange:(UIButton *)sender {
    if (sender.tag == 100 && self.startValue < 1.0) {
        self.startValue += 0.1;
    } else if (sender.tag == 200 && self.startValue > 0.0){
        self.startValue -= 0.1;
    }
    self.maskView.startValue = self.startValue;
    self.startValueLabel.text = [NSString stringWithFormat:@"startValue：%.1f", self.startValue];
}

- (YJMaskAnimationView *)maskView {
    if (!_maskView) {
        _maskView = [[YJMaskAnimationView alloc] initWithFrame:CGRectMake(20, 250, self.view.frame.size.width - 40, 80) maskColor:[UIColor redColor]];
    }
    return _maskView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
