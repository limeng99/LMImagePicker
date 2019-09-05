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

+ (UIImage *)imageNamedFromMyBundle:(NSString *)name;
+ (UIImage *)createImageWithColor:(nullable UIColor *)color size:(CGSize)size radius:(CGFloat)radius;


@end

NS_ASSUME_NONNULL_END
