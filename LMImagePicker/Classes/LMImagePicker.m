//
//  LMImagePicker.m
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import "LMImagePicker.h"
#import "UIView+LMLayout.h"
#import "UIImage+LMImagePicker.h"
#import "NSBundle+LMImagePicker.h"
#import "LMPhotoPickerController.h"
#import "LMPhotoManager.h"

LMImagePicker *_imagePicker = nil;
@implementation LMImagePicker

+ (instancetype)sharedImagePicker {
    if (!_imagePicker) {
        _imagePicker = [[self alloc] init];
    }
    return _imagePicker;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _imagePicker = [super allocWithZone:zone];
    });
    return _imagePicker;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxImagesCount = 1;
        self.minImagesCount = 1;
        self.columnNumber = 3;
        self.sortAscendingByModificationDate = NO;
        self.allowPickingOriginalPhoto = YES;
        self.allowPickingImage = YES;
        self.allowTakePicture = YES;
        self.selectedAssets = [NSMutableArray array];
        
        self.timeout = 15;
        self.photoWidth = 828.0;
        self.photoPreviewMaxWidth = 600;
        self.notScaleImage = YES;
        self.blurEffectStyle = UIBlurEffectStyleLight;
        self.cannotSelectLayerColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
        
        if (!self.allowPickingImage) {
            self.allowTakePicture = NO;
        }
        
        self.btnTitleColorNormal   = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0];
        self.btnTitleColorDisabled = [UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:0.5];
        self.iconThemeColor = [UIColor colorWithRed:31 / 255.0 green:185 / 255.0 blue:34 / 255.0 alpha:1.0];
        self.textColor = [UIColor colorWithRed:72/255.0 green:72/255.0 blue:72/255.0 alpha:1.0];
        self.themeColor = [UIColor whiteColor];
        
        NSString *language = [NSLocale preferredLanguages].firstObject;
        if ([language rangeOfString:@"zh-Hans"].location != NSNotFound) {
            language = @"zh-Hans";
        } else {
            language = @"en";
        }
        self.localLanguage = language;
        self.languageBundle = [NSBundle bundleWithPath:[[NSBundle imagePickerBundle] pathForResource:self.localLanguage ofType:@"lproj"]];
    
        [self configDefaultBtnTitle];
        [self configDefaultImageName];
    }
    return self;
}

- (void)configDefaultBtnTitle {
    self.doneBtnTitleStr = [NSBundle localizedStringForKey:@"Done"];
    self.cancelBtnTitleStr = [NSBundle localizedStringForKey:@"Cancel"];
    self.previewBtnTitleStr = [NSBundle localizedStringForKey:@"Preview"];
    self.fullImageBtnTitleStr = [NSBundle localizedStringForKey:@"Full image"];
    self.settingBtnTitleStr = [NSBundle localizedStringForKey:@"Setting"];
    self.processHintStr = [NSBundle localizedStringForKey:@"Processing..."];
}

- (void)configDefaultImageName {
    self.navBackImage = [UIImage imageNamedFromMyBundle:@"nav_back"];
    self.photoAlbumArrowImage = [UIImage imageNamedFromMyBundle:@"album_arrow"];
    self.takePictureImage = [UIImage imageNamedFromMyBundle:@"takePicture"];
    self.photoSelImage = [UIImage imageNamedFromMyBundle:@"photo_select_sel"];
    self.photoNorImage = [UIImage imageNamedFromMyBundle:@"photo_select_nor"];
    self.photoNumberIconImage = [UIImage createImageWithColor:nil size:CGSizeMake(24, 24) radius:12];
    self.photoOriginSelImage = [UIImage imageNamedFromMyBundle:@"photo_original_sel"];
    self.photoOriginNorImage = [UIImage imageNamedFromMyBundle:@"photo_original_nor"];
}

- (LMPhotoPickerController *)photoPicker {
    if (!_photoPicker) {
        _photoPicker = [[LMPhotoPickerController alloc] init];
    }
    return _photoPicker;
}


- (void)setTimeout:(NSInteger)timeout {
    _timeout = timeout;
    if (timeout < 5) {
        _timeout = 5;
    } else if (_timeout > 60) {
        _timeout = 60;
    }
}

- (void)setPickerDelegate:(id<LMImagePickerDelegate>)pickerDelegate {
    _pickerDelegate = pickerDelegate;
    [LMPhotoManager manager].pickerDelegate = pickerDelegate;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.navBackImage = [[UIImage imageNamedFromMyBundle:@"nav_back"] imageWithTintColor:self.textColor];
    self.photoAlbumArrowImage = [[UIImage imageNamedFromMyBundle:@"album_arrow"] imageWithTintColor:self.textColor];
}

- (void)setColumnNumber:(NSInteger)columnNumber {
    _columnNumber = columnNumber;
    if (columnNumber <= 2) {
        _columnNumber = 2;
    } else if (columnNumber >= 6) {
        _columnNumber = 6;
    }
}

- (void)setMaxImagesCount:(NSInteger)maxImagesCount {
    _maxImagesCount = maxImagesCount;
    if (maxImagesCount > 1) {
        _showSelectBtn = YES;
    }
}

- (void)setShowSelectBtn:(BOOL)showSelectBtn {
    _showSelectBtn = showSelectBtn;
    if (!showSelectBtn && _maxImagesCount > 1) {
        _showSelectBtn = YES;
    }
}


- (void)setPhotoPreviewMaxWidth:(CGFloat)photoPreviewMaxWidth {
    _photoPreviewMaxWidth = photoPreviewMaxWidth;
    if (photoPreviewMaxWidth > 800) {
        _photoPreviewMaxWidth = 800;
    } else if (photoPreviewMaxWidth < 500) {
        _photoPreviewMaxWidth = 500;
    }
}

- (void)setSelectedAssets:(NSMutableArray *)selectedAssets {
    _selectedAssets = selectedAssets;
    _selectedModels = [NSMutableArray array];
    _selectedAssetIds = [NSMutableArray array];
    for (PHAsset *asset in selectedAssets) {
        LMAssetModel *model = [LMAssetModel modelWithAsset:asset type:[[LMPhotoManager manager] getAssetType:asset]];
        model.isSelected = YES;
        [self addSelectedModel:model];
    }
}

- (void)addSelectedModel:(LMAssetModel *)model {
    [_selectedModels addObject:model];
    [_selectedAssetIds addObject:model.asset.localIdentifier];
}

- (void)removeSelectedModel:(LMAssetModel *)model {
    [_selectedModels removeObject:model];
    [_selectedAssetIds removeObject:model.asset.localIdentifier];
}

@end
