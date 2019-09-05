//
//  LMImagePicker.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LMImagePickerDelegate;
@class LMAssetModel, LMPhotoPickerController;
@interface LMImagePicker : NSObject

/// Initialize
+ (instancetype)sharedImagePicker;

/// Photo picker
@property (nonatomic, strong) LMPhotoPickerController *photoPicker;

/// Picker delegate
@property (nonatomic, weak) id<LMImagePickerDelegate> pickerDelegate;

/// Default is 1, max is 9
@property (nonatomic, assign) NSInteger maxImagesCount;

/// The minimum count photos user must pick, Default is 1
@property (nonatomic, assign) NSInteger minImagesCount;

/// Default is 3, max is 6
@property (nonatomic, assign) NSInteger columnNumber;

/// Sort photos ascending by modificationDate，Default is NO
@property (nonatomic, assign) BOOL sortAscendingByModificationDate;

/// The pixel width of output image, Default is 828px
@property (nonatomic, assign) CGFloat photoWidth;

/// Default is 600px
@property (nonatomic, assign) CGFloat photoPreviewMaxWidth;

/// Default is 15, While fetching photo, HUD will dismiss automatic if timeout;
@property (nonatomic, assign) NSInteger timeout;

/// Default is YES, if set NO, the original photo button will hide. user can't picking original photo.
@property (nonatomic, assign) BOOL allowPickingOriginalPhoto;

/// Default is NO
@property (nonatomic, assign) BOOL allowPickingVideo;
/// Default is NO
@property (nonatomic, assign) BOOL allowPickingMultipleVideo;

/// Default is YES, if set NO, user can't picking image.
@property (nonatomic, assign) BOOL allowPickingImage;

/// Default is YES, if set NO, user can't take picture.
@property (nonatomic, assign) BOOL allowTakePicture;

/// Only support zh-Hans、en
@property (copy, nonatomic) NSString *preferredLanguage;

/// Default is NO, if set YES, in the delegate method the photos and infos will be nil, only assets hava value.
@property (assign, nonatomic) BOOL onlyReturnAsset;

/// Default is NO, if set YES, will show the image's selected index.
@property (assign, nonatomic) BOOL showSelectedIndex;

/// Default is NO, if set YES, when selected photos's count up to maxImagesCount, other photo will show float layer what's color is cannotSelectLayerColor.
@property (assign, nonatomic) BOOL showPhotoCannotSelectLayer;
/// Default is white color with 0.8 alpha;
@property (strong, nonatomic) UIColor *cannotSelectLayerColor;

/// Default is No, if set YES, the result photo will not be scaled to photoWidth pixel width. The photoWidth default is 828px
@property (assign, nonatomic) BOOL notScaleImage;

/// The photos user have selected
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableArray<LMAssetModel *> *selectedModels;
@property (nonatomic, strong) NSMutableArray *selectedAssetIds;
- (void)addSelectedModel:(LMAssetModel *)model;
- (void)removeSelectedModel:(LMAssetModel *)model;

/// Minimum selectable photo width, Default is 0
@property (nonatomic, assign) NSInteger minPhotoWidthSelectable;
@property (nonatomic, assign) NSInteger minPhotoHeightSelectable;

/// Hide the photo what can not be selected, Default is NO
@property (nonatomic, assign) BOOL hideWhenCanNotSelect;

/// Single selection mode, valid when maxImagesCount = 1, Default is No
@property (nonatomic, assign) BOOL showSelectBtn;

/// Default is en ,local language
@property (nonatomic, copy) NSString   *localLanguage;

/// Language bundle
@property (nonatomic, strong) NSBundle *languageBundle;

#pragma mark -
- (UIAlertController *)showAlertWithTitle:(NSString *)title;
- (void)hideAlertView:(UIAlertController *)alertView;
- (void)showProgressHUD;
- (void)hideProgressHUD;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;

#pragma mark -
@property (nonatomic, strong) UIImage *takePictureImage;
@property (nonatomic, strong) UIImage *photoSelImage;
@property (nonatomic, strong) UIImage *photoNorImage;
@property (nonatomic, strong) UIImage *photoOriginSelImage;
@property (nonatomic, strong) UIImage *photoOriginNorImage;;
@property (nonatomic, strong) UIImage *photoNumberIconImage;
@property (nonatomic, strong) UIImage *photoAlbumArrowImage;

/// Appearance
@property (nonatomic, copy) NSString *doneBtnTitleStr;
@property (nonatomic, copy) NSString *cancelBtnTitleStr;
@property (nonatomic, copy) NSString *previewBtnTitleStr;
@property (nonatomic, copy) NSString *fullImageBtnTitleStr;
@property (nonatomic, copy) NSString *settingBtnTitleStr;
@property (nonatomic, copy) NSString *processHintStr;

/// Icon theme color, default is green color like wechat, the value is r:31 g:185 b:34. Currently only support image selection icon when showSelectedIndex is YES. If you need it, please set it as soon as possible
@property (strong, nonatomic) UIColor *iconThemeColor;
/// Default whiteColor
@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *btnTitleColorNormal;
@property (nonatomic, strong) UIColor *btnTitleColorDisabled;

@end


@protocol LMImagePickerDelegate <NSObject>
@optional
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[HRImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
- (void)imagePicker:(LMImagePicker *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto;
- (void)imagePicker:(LMImagePicker *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos;
- (void)imagePickerDidCancel:(LMImagePicker *)picker;

// Decide album show or not't
- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(PHFetchResult *)result;
// Decide asset show or not't
- (BOOL)isAssetCanSelect:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
