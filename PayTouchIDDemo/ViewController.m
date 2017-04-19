//
//  ViewController.m
//  PayTouchIDDemo
//
//  Created by pzj on 2017/4/18.
//  Copyright © 2017年 pzj. All rights reserved.
//

#import "ViewController.h"
#import <sys/utsname.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "SuccessViewController.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - lifeCycle                    - Method -
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark - privateMethods               - Method -
- (void)initViews
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn setTitle:@"点击进行指纹验证" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor brownColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13];
    btn.titleLabel.numberOfLines = 0;
    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [btn addTarget:self action:@selector(touchBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (BOOL)isSimulator{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceMachine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([deviceMachine isEqualToString:@"i386"]||[deviceMachine isEqualToString:@"x86_64"]) {//模拟器\
        return YES;
    }
    return NO;
}

#pragma mark - eventResponse                - Method -
- (void)touchBtn
{
    __weak typeof(self) weakSelf = self;
    if ([self isSimulator]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请用真机测试~" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    //iOS8及以上版本执行- (void)authenticateUser方法，方法自动判断设备是否支持和开启TouchID
    if (System_Version > 8.0) {
        NSLog(@"你的系统满足条件");
        LAContext *context = [[LAContext alloc] init];
        NSError *error = nil;
        
        //判断是否开启指纹验证功能
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            //验证指纹
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"解锁（支付）" reply:^(BOOL success, NSError * _Nullable error) {
                
                //验证成功
                if (success) {
                    NSLog(@"指纹验证成功");
                    //验证成功，主线程处理UI
                    SuccessViewController *vc = [[SuccessViewController alloc] init];
                    [self presentViewController:vc animated:YES completion:nil];
                }else{
                    NSLog(@"%@",error.localizedDescription);
                    
                    switch (error.code) {
                        case LAErrorAuthenticationFailed:
                            NSLog(@"验证信息出错，就是说指纹不对，错误三次");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSLog(@"弹出输入密码界面");
                            });
                            break;
                        case LAErrorUserFallback:
                            NSLog(@"验证失败点击输入密码按钮/弹出输入密码界面");
                            break;
                        case LAErrorUserCancel:
                        {
                            NSLog(@"验证失败点击了取消按钮");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"是否取消指纹验证" preferredStyle:UIAlertControllerStyleAlert];
                                
                                UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                                    
                                }];
                                [alert addAction:sureAction];
                                [weakSelf presentViewController:alert animated:YES completion:nil];
                            });
                        }
                            break;
                        case LAErrorSystemCancel:
                            NSLog(@"验证失败因为某种设备原因，比如按下home键");
                            break;
                        case LAErrorTouchIDLockout://iOS 9.0 后添加的枚举值
                            NSLog(@"指纹认证错误次数太傅哦，现在被锁住了");
                            NSLog(@"弹出输入面界面");
                            break;
                        case LAErrorAppCancel://iOS 9.0 后添加的枚举值
                            NSLog(@"在验证中被其他app中断，比如来电等");
                            break;
                        case LAErrorInvalidContext://iOS9.0 后添加的枚举值
                            NSLog(@"请求验证出错");
                            break;
                        default:
                            break;
                    }
                }

//                if (success) {//验证成功
//                    NSLog(@"验证成功");
//                    //验证成功，主线程处理UI
//                    SuccessViewController *vc = [[SuccessViewController alloc] init];
//                    [self presentViewController:vc animated:YES completion:nil];
//                }
//                if (error.code == -2) {
//                    NSLog(@"用户取消了操作：%@",error);
//                }
//                if (error.code != -2) {
//                    NSLog(@"验证失败：%@",error);
//                }
            }];

        }else{
//            NSLog(@"你的设备没有开启指纹验证功能");
            NSLog(@"%@",error.localizedDescription);
            
            switch (error.code) {
                case LAErrorTouchIDNotAvailable:
                {
                    NSLog(@"设备不支持 touch id");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"此设备不支持Touch ID" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"马上换手机" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.baidu.com"]];
                        }];
                        [alert addAction:cancelAction];
                        [alert addAction:sureAction];
                        [weakSelf presentViewController:alert animated:YES completion:nil];
                    });
                }
                    break;
                case LAErrorPasscodeNotSet:
                    NSLog(@"您没有设置Touch ID,请先设置Touch ID");
                    break;
                case LAErrorTouchIDNotEnrolled:
                    NSLog(@"您没有设置手指指纹，请先设置手指指纹");
                    break;
                case LAErrorTouchIDLockout://iOS 9.0 后添加的是枚举值
                    NSLog(@"指纹认证错误次数太多，现在被锁住了");
                    NSLog(@"切换至输入密码界面");
                    break;
                default:
                    break;
            }
            
        }
        
    }else{
        NSLog(@"你的系统不满足条件");
        
    }
    
}
#pragma mark - notification                 - Method -

#pragma mark - customDelegate               - Method -

#pragma mark - objective-cDelegate          - Method -

#pragma mark - getters and setters          - Method -



@end
