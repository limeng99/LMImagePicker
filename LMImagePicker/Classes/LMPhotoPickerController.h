//
//  LMPhotoPickerController.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LMAlbumModel;
@interface LMPhotoPickerController : UIViewController

@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, strong) LMAlbumModel *model;

- (void)showSetting;
- (void)hideSetting;


@end


@interface LMCollectionView : UICollectionView

@end


NS_ASSUME_NONNULL_END
