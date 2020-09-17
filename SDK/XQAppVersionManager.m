//
//  XQAppVersionManager.m
//  XQGvmEasily
//
//  Created by WXQ on 2020/8/21.
//  Copyright © 2020 WXQ. All rights reserved.
//

#import "XQAppVersionManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <StoreKit/StoreKit.h>
#import <XQAlert/XQSystemAlert.h>
#import "XQGetAppInfo.h"

#define XQAVMLocalizedString(key) NSLocalizedStringFromTableInBundle(key, @"XQAppVersionManagerStrings", [NSBundle bundleForClass:[XQAppVersionManager class]], nil)

@interface XQAppVersionManager () <SKStoreProductViewControllerDelegate>

@end

@implementation XQAppVersionManager

static XQAppVersionManager *appVersionCheck_ = nil;

+ (void)queryAppStoreAppInfoWithAppId:(NSString *)appId comparisonVersion:(BOOL)comparisonVersion showAlert:(BOOL)showAlert {
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    // app store显示的版本
    NSString *currentVersion = infoDic[@"CFBundleShortVersionString"];
    
    // 生产版本查询appstore更新
    if (appId.length == 0) {
        return;
    }
    
    [XQGetAppInfo getAppInfoWithAPPID:appId success:^(id responseObject) {
        
        if (!responseObject) {
            return;
        }
        
        NSInteger count = ((NSNumber *)responseObject[@"resultCount"]).integerValue;
        if (count == 0) {
            return ;
        }
        
        NSArray *dataArr = responseObject[@"results"];
        
        if (comparisonVersion) {
            if (!dataArr || ![dataArr isKindOfClass:[NSArray class]] || dataArr.count == 0) {
                return;
            }
            
            if (![dataArr.firstObject isKindOfClass:[NSDictionary class]]) {
                return;
            }
            
            NSString *version = dataArr.firstObject[@"version"];
            
            // 判断版本
            NSInteger result = [XQAppVersionManager judgeVersionWithV1:currentVersion v2:version];
            if (result != 0) {
                return;
            }
        }
        
        // 跳转更新
        if (showAlert) {
            [self presentAppStoreUpdateAppWithMessage:dataArr.firstObject[@"releaseNotes"] appID:appId];
        }else {
            [self presentProductWithAppId:appId];
        }
        
        
    } failure:nil];
}

/// 判断版本大小
/// 返回 1, v1 比 v2 大
/// 返回 0, v1 比 v2 小
/// 返回 2, 相等
/// 返回 3, 其他错误
+ (NSInteger)judgeVersionWithV1:(NSString *)v1 v2:(NSString *)v2 {
    
    if (!v1 || !v2 || v1.length == 0 || v2.length == 0) {
        return 3;
    }
    
    if ([v1 isEqualToString:v2]) {
        return 2;
    }
    
    NSArray *arr1 = [v1 componentsSeparatedByString:@"."];
    
    NSArray *arr2 = [v2 componentsSeparatedByString:@"."];
    
    for (int i = 0; i < arr1.count; i++) {
        
        if (i >= arr2.count) {
            // 超过最大了
            // 1 比 2 位数多
            return 1;
        }
        
        int version1 = [arr1[i] intValue];
        int version2 = [arr2[i] intValue];
        
        if (version1 > version2) {
            return 1;
        }else if (version1 < version2) {
            return 0;
        }
    }
    
    // 相同位数
    if (arr1.count == arr2.count) {
        return 2;
    }
    // 1 比 2 位数多
    if (arr1.count > arr2.count) {
        return 1;
    }
    // 1 比 2 位数少
    return 0;
}

+ (void)presentAppStoreUpdateAppWithMessage:(NSString *)message appID:(NSString *)appID {
    NSString *releaseNotes = message;
    if (!releaseNotes || releaseNotes.length == 0) {
        releaseNotes = XQAVMLocalizedString(@"newVersionNote");
    }
    
    
    [XQSystemAlert alertWithTitle:XQAVMLocalizedString(@"newVersionReminder") message:releaseNotes contentArr:@[XQAVMLocalizedString(@"upgrade")] cancelText:XQAVMLocalizedString(@"talkLater") vc:[UIApplication sharedApplication].keyWindow.rootViewController contentCallback:^(UIAlertController * _Nonnull alert, NSUInteger index) {
        
        if (!appID || appID.length == 0) {
            [SVProgressHUD showErrorWithStatus:XQAVMLocalizedString(@"openAppStoreError")];
            return;
        }
        
        [self presentProductWithAppId:appID];
        
//        if ([XQGetAppInfo openAPPStoreWithAppID:appID completionHandler:nil]) {
//            [SVProgressHUD showInfoWithStatus:NB_LS(@"打开应用商店失败")];
//        }
        
    } cancelCallback:nil];
}

+ (void)presentProductWithAppId:(NSString *)appId {
    if (appId.length == 0) {
        return;
    }
    
    if (appVersionCheck_) {
        NSLog(@"已存在对象, 需要释放");
        return;
    }
    
    appVersionCheck_ = [XQAppVersionManager new];
    
    // App内部打开AppStore 应用页面
    SKStoreProductViewController *storeProductVC =  [[SKStoreProductViewController alloc] init];
    storeProductVC.delegate = appVersionCheck_;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:@(appId.intValue) forKey:SKStoreProductParameterITunesItemIdentifier];
    [SVProgressHUD showWithStatus:nil];
    [storeProductVC loadProductWithParameters:dict completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            NSLog(@"跳转应用商店失败 error: %@", error);
            [SVProgressHUD showErrorWithStatus:XQAVMLocalizedString(@"openAppStoreError")];
        }else {
            [SVProgressHUD dismiss];
            NSLog(@"跳转应用商店成功");
        }
    }];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:storeProductVC animated:YES completion:nil];
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    NSLog(@"%s", __func__);
    appVersionCheck_ = nil;
}

@end
