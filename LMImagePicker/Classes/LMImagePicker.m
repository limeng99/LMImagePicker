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

@interface LMImagePicker(){
    NSTimer *_timer;
    
    UIView *_HUDContainer;
    UIActivityIndicatorView *_HUDIndicatorView;
    UILabel *_HUDLabel;
    UIButton *_progressHUD;
}

@end

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
    self.takePictureImage = [UIImage imageNamedFromMyBundle:@"takePicture"];
    self.photoSelImage = [UIImage imageNamedFromMyBundle:@"photo_select_sel"];
    self.photoNorImage = [UIImage imageNamedFromMyBundle:@"photo_select_nor"];
    self.photoNumberIconImage = [UIImage createImageWithColor:nil size:CGSizeMake(24, 24) radius:12];
    self.photoOriginSelImage = [UIImage imageNamedFromMyBundle:@"preview_original_sel"];
    self.photoOriginNorImage = [UIImage imageNamedFromMyBundle:@"preview_original_nor"];
    self.photoAlbumArrowImage = [UIImage imageNamedFromMyBundle:@"album_arrow"];
}

- (LMPhotoPickerController *)photoPicker {
    if (!_photoPicker) {
        _photoPicker = [[LMPhotoPickerController alloc] init];
        _photoPicker.columnNumber = self.columnNumber;

        if (![[LMPhotoManager manager] authorizationStatusAuthorized]) {

            [_photoPicker showSetting];

            if ([PHPhotoLibrary authorizationStatus] == 0) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:NO];
            }
        } else {
            [[LMPhotoManager manager] getCameraRollAlbum:self.allowPickingVideo allowPickingImage:self.allowPickingImage needFetchAssets:NO completion:^(LMAlbumModel *model) {
                self->_photoPicker.model = model;
            }];
        }
        
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

- (void)observeAuthrizationStatusChange {
    [_timer invalidate];
    _timer = nil;
    if ([PHPhotoLibrary authorizationStatus] == 0) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:NO];
    }
    
    if ([[LMPhotoManager manager] authorizationStatusAuthorized]) {
        [self.photoPicker hideSetting];
        [[LMPhotoManager manager] getCameraRollAlbum:self.allowPickingVideo allowPickingImage:self.allowPickingImage needFetchAssets:NO completion:^(LMAlbumModel *model) {
            self.photoPicker.model = model;;
        }];
    }
}

- (UIAlertController *)showAlertWithTitle:(NSString *)title {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle localizedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:nil]];
    [[self photoPicker] presentViewController:alertController animated:YES completion:nil];
    return alertController;
}

- (void)hideAlertView:(UIAlertController *)alertView {
    [alertView dismissViewControllerAnimated:YES completion:nil];
    alertView = nil;
}

- (void)showProgressHUD {
    if (!_progressHUD) {
        
        CGFloat progressHUDY = 64;
        
        _progressHUD = [UIButton buttonWithType:UIButtonTypeCustom];
        _progressHUD.frame = CGRectMake(0, progressHUDY, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - progressHUDY);
        [_progressHUD setBackgroundColor:[UIColor clearColor]];
        
        _HUDContainer = [[UIView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 120) / 2, (_progressHUD.lm_height - 90 - progressHUDY) / 2, 120, 90)];
        _HUDContainer.layer.cornerRadius = 8;
        _HUDContainer.clipsToBounds = YES;
        _HUDContainer.backgroundColor = [UIColor darkGrayColor];
        _HUDContainer.alpha = 0.7;
        
        _HUDIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
        
        _HUDLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,40, 120, 50)];
        _HUDLabel.textAlignment = NSTextAlignmentCenter;
        _HUDLabel.text = self.processHintStr;
        _HUDLabel.font = [UIFont systemFontOfSize:15];
        _HUDLabel.textColor = [UIColor whiteColor];
        
        [_HUDContainer addSubview:_HUDLabel];
        [_HUDContainer addSubview:_HUDIndicatorView];
        [_progressHUD addSubview:_HUDContainer];
    }
    [_HUDIndicatorView startAnimating];
    UIWindow *applicationWindow;
    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)]) {
        applicationWindow = [[[UIApplication sharedApplication] delegate] window];
    } else {
        applicationWindow = [[UIApplication sharedApplication] keyWindow];
    }
    [applicationWindow addSubview:_progressHUD];
    
    // if over time, dismiss HUD automatic
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf hideProgressHUD];
    });
}

- (void)hideProgressHUD {
    if (_progressHUD) {
        [_HUDIndicatorView stopAnimating];
        [_progressHUD removeFromSuperview];
    }
}




@end
