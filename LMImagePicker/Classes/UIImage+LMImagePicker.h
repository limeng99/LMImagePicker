//
//  UIImage+LMImagePicker.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (LMImagePicker)

+ (UIImage *)lm_imageNamedFromMyBundle:(NSString *)name;
+ (UIImage *)lm_createImageWithColor:(nullable UIColor *)color size:(CGSize)size radius:(CGFloat)radius;
- (UIImage *)lm_imageWithTintColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
