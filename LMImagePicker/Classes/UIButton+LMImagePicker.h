//
//  UIButton+LMImagePicker.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LMButtonImagePosition) {
    LMButtonImagePositionLeft,
    LMButtonImagePositionRight,
    LMButtonImagePositionTop,
    LMButtonImagePositionBottom
};

@interface UIButton (LMImagePicker)

- (void)lm_setButtonImagePosition:(LMButtonImagePosition)position spacing:(CGFloat)spacing;

@end


NS_ASSUME_NONNULL_END
