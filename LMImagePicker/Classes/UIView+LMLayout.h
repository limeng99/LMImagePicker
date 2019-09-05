//
//  UIView+LMLayout.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    LMOscillatoryAnimationToBigger,
    LMOscillatoryAnimationToSmaller,
} LMOscillatoryAnimationType;

NS_ASSUME_NONNULL_BEGIN

@interface UIView (LMLayout)

@property (nonatomic) CGFloat lm_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat lm_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat lm_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat lm_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat lm_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat lm_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat lm_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat lm_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint lm_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  lm_size;        ///< Shortcut for frame.size.

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(LMOscillatoryAnimationType)type;

@end

NS_ASSUME_NONNULL_END
