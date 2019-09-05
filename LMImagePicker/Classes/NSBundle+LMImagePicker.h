//
//  NSBundle+LMImagePicker.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (LMImagePicker)

+ (NSBundle *)imagePickerBundle;
+ (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)localizedStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
