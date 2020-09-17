//
//  XQAppVersionManager.h
//  XQGvmEasily
//
//  Created by WXQ on 2020/8/21.
//  Copyright © 2020 WXQ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQAppVersionManager : NSObject

/// 查询App Store上的版本, 如有新版本，则会提示
/// @param appId APP id
/// @param comparisonVersion 是否要对比版本, 有更新才弹出
/// @param showAlert 是否显示去升级弹框, NO 就直接弹 App Store
+ (void)queryAppStoreAppInfoWithAppId:(NSString *)appId comparisonVersion:(BOOL)comparisonVersion showAlert:(BOOL)showAlert;

/// StoreKit 跳转到指定 appid
+ (void)presentProductWithAppId:(NSString *)appId;

/// 判断版本大小
/// 返回 1, v1 比 v2 大
/// 返回 0, v1 比 v2 小
/// 返回 2, 相等
/// 返回 3, 其他错误
+ (NSInteger)judgeVersionWithV1:(NSString *)v1 v2:(NSString *)v2;

@end

NS_ASSUME_NONNULL_END
