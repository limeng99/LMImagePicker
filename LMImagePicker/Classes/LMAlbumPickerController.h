//
//  LMAlbumPickerController.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LMAlbumModel;
@interface LMAlbumPickerController : UIViewController

@property (nonatomic, copy) void(^albumPickerSelectedBlock)(LMAlbumModel *model);
- (void)configTableView;

@end

NS_ASSUME_NONNULL_END
