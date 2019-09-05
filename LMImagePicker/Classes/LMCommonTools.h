//
//  LMCommonTools.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMCommonTools : NSObject

+ (BOOL)lm_isIPhoneX;
+ (CGFloat)lm_statusBarHeight;
+ (CGFloat)lm_statusBarHideHeight;
+ (NSDictionary *)lm_getInfoDictionary;

@end

NS_ASSUME_NONNULL_END
