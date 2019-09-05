//
//  LMCommonTools.m
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import "LMCommonTools.h"

@implementation LMCommonTools

+ (BOOL)lm_isIPhoneX {
    if (@available(iOS 11.0, *)) {
        CGFloat height = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom;
        return (height > 0);
    } else {
        return NO;
    }
}

+ (CGFloat)lm_statusBarHeight {
    return [self lm_isIPhoneX] ? 44 : 20;
}

+ (CGFloat)lm_statusBarHideHeight {
    return [self lm_isIPhoneX] ? 20 : 0;
}

+ (NSDictionary *)lm_getInfoDictionary {
    NSDictionary *infoDict = [NSBundle mainBundle].localizedInfoDictionary;
    if (!infoDict || !infoDict.count) {
        infoDict = [NSBundle mainBundle].infoDictionary;
    }
    if (!infoDict || !infoDict.count) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        infoDict = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return infoDict ? infoDict : @{};
}

@end
