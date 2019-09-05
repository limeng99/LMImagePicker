//
//  LMPhotoPickerController.m
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import "LMPhotoPickerController.h"
#import "LMImagePicker.h"
#import "LMAssetCell.h"
#import "LMAssetModel.h"
#import "UIView+LMLayout.h"
#import "LMCommonTools.h"
#import "LMPhotoManager.h"
#import "LMAlbumPickerController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+LMImagePicker.h"
#import "NSBundle+LMImagePicker.h"
#import "UIButton+LMImagePicker.h"

@interface LMPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIAlertViewDelegate> {
    
    NSTimer     *_timer;
    UILabel     *_tipLabel;
    UIButton    *_settingBtn;
    
    UIView      *_HUDContainer;
    UILabel     *_HUDLabel;
    UIButton    *_progressHUD;
    UIActivityIndicatorView *_HUDIndicatorView;
    
    UIView      *_navBarView;
    UIButton    *_titleBtn;

    UIView      *_bottomToolBar;
    UIButton    *_doneButton;
    UIImageView *_numberImageView;
    UILabel     *_numberLabel;
    UIButton    *_originalPhotoButton;
    UILabel     *_originalPhotoLabel;
    UIView      *_divideLine;
    
}

@property CGRect previousPreheatRect;

@property (nonatomic, assign) BOOL          isSelectOriginalPhoto;
@property (nonatomic, assign) BOOL          showTakePhotoBtn;
@property (nonatomic, assign) BOOL          useCachedImage;
@property (nonatomic, assign) NSInteger     columnNumber;

@property (nonatomic, strong) LMAlbumPickerController   *albumPickerVc;
@property (nonatomic, strong) LMAlbumModel              *model;
@property (nonatomic, strong) NSMutableArray<LMAssetModel *> *models;

@property (nonatomic, strong) LMCollectionView           *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIImagePickerController    *imagePickerVc;


@end

static CGSize AssetGridThumbnailSize;
static CGFloat itemMargin = 5;

@implementation LMPhotoPickerController

- (void)dealloc {
     NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = 2.0;
    if ([UIScreen mainScreen].bounds.size.width > 600) {
        scale = 1.0;
    }
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (BOOL)prefersStatusBarHidden {
    return [LMImagePicker sharedImagePicker].statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [LMImagePicker sharedImagePicker].statusBarStyle;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    imagePicker.isSelectOriginalPhoto = _isSelectOriginalPhoto;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    _isSelectOriginalPhoto = imagePicker.isSelectOriginalPhoto;
    _columnNumber = imagePicker.columnNumber;
    _showTakePhotoBtn = imagePicker.allowTakePicture;
    
    self.view.backgroundColor = imagePicker.themeColor;
    [self albumAuthorizationDetection];
    [self setupNavBar];
}


#pragma mark - Authoruzation
- (void)albumAuthorizationDetection {
    
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (![[LMPhotoManager manager] authorizationStatusAuthorized]) {
        [self setupTipSetting];
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:NO];
        }
        
    } else {
        [self showProgressHUD];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[LMPhotoManager manager] getCameraRollAlbum:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage needFetchAssets:NO completion:^(LMAlbumModel *model) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD];
                    self.model = model;
                });
            }];
        });
    }
}

- (void)observeAuthrizationStatusChange {
    [_timer invalidate];
    _timer = nil;
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:NO];
    }
    
    if ([[LMPhotoManager manager] authorizationStatusAuthorized]) {
        [_tipLabel removeFromSuperview];
        [_settingBtn removeFromSuperview];
        LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
        [self showProgressHUD];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[LMPhotoManager manager] getCameraRollAlbum:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage needFetchAssets:NO completion:^(LMAlbumModel *model) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD];
                    self.model = model;
                });
            }];
        });
    }
}

#pragma mark - Progress
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
        _HUDLabel.text = [LMImagePicker sharedImagePicker].processHintStr;
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([LMImagePicker sharedImagePicker].timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

#pragma mark - Model
- (void)setModel:(LMAlbumModel *)model {
    _model = model;
    NSString *title = !model.name ? @"Photos" : model.name;
    [_titleBtn setTitle:title forState:UIControlStateNormal];
    [_titleBtn lm_setButtonImagePosition:LMButtonImagePositionRight spacing:6];
    
    [[LMPhotoManager manager] getAssetsFromFetchResult:self.model.result completion:^(NSArray<LMAssetModel *> *models) {
        self.models = [NSMutableArray arrayWithArray:models];
        [self initSubviews];
    }];
    
}

- (void)checkSelectedModels {
    NSMutableArray *selectedAssets = [NSMutableArray array];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    for (LMAssetModel *model in imagePicker.selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (LMAssetModel *model in _models) {
        model.isSelected = NO;
        if ([selectedAssets containsObject:model.asset]) {
            model.isSelected = YES;
        }
    }
}

#pragma mark - Setup view
- (void)setupTipSetting {
    _tipLabel = [[UILabel alloc] init];
    _tipLabel.frame = CGRectMake(8, 120, self.view.lm_width - 16, 60);
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    _tipLabel.numberOfLines = 0;
    _tipLabel.font = [UIFont systemFontOfSize:16];
    _tipLabel.textColor = [LMImagePicker sharedImagePicker].textColor;
    
    NSDictionary *infoDict = [LMCommonTools lm_getInfoDictionary];
    NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
    if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
    NSString *tipText = [NSString stringWithFormat:[NSBundle localizedStringForKey:@"Allow %@ to access your album in \"Settings -> Privacy -> Photos\""],appName];
    _tipLabel.text = tipText;
    [self.view addSubview:_tipLabel];
    
    _settingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingBtn setTitle:[LMImagePicker sharedImagePicker].settingBtnTitleStr forState:UIControlStateNormal];
    _settingBtn.frame = CGRectMake(0, 180, self.view.lm_width, 44);
    _settingBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [_settingBtn addTarget:self action:@selector(settingBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_settingBtn];
}


- (void)setupNavBar {
    
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    
    CGFloat navBarHegight = [LMCommonTools lm_navBarHeight];
    
    _navBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.lm_width, navBarHegight)];
    _navBarView.backgroundColor = [imagePicker.themeColor colorWithAlphaComponent:0.6];
    [self.view addSubview:_navBarView];
    
    UIBlurEffect *barEffect = [UIBlurEffect effectWithStyle:imagePicker.blurEffectStyle];
    UIVisualEffectView *barEffectView = [[UIVisualEffectView alloc] initWithEffect:barEffect];
    barEffectView.frame = _navBarView.bounds;
    [_navBarView addSubview:barEffectView];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 30, 30)];
    backBtn.lm_bottom = navBarHegight - 7;
    [backBtn setImage:imagePicker.navBackImage forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_navBarView addSubview:backBtn];
    
    NSString *title = [NSBundle localizedStringForKey:@"Photos"];
    _titleBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.lm_width-180, 44)];
    _titleBtn.lm_bottom = navBarHegight;
    _titleBtn.lm_centerX = self.view.lm_width*0.5;
    _titleBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [_titleBtn setTitleColor:[LMImagePicker sharedImagePicker].textColor forState:UIControlStateNormal];
    [_titleBtn setTitle:title forState:UIControlStateNormal];
    [_titleBtn setImage:imagePicker.photoAlbumArrowImage forState:UIControlStateNormal];
    [_titleBtn lm_setButtonImagePosition:LMButtonImagePositionRight spacing:6];
    [_titleBtn addTarget:self action:@selector(albumBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_navBarView addSubview:_titleBtn];

}

- (void)initSubviews {
    if (!_collectionView) {
        [self configCollectionView];
        [self configBottomToolBar];
        [self.view bringSubviewToFront:self.albumPickerVc.view];
        [self.view bringSubviewToFront:self->_navBarView];
    } else {
        [self.collectionView reloadData];
    }
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWH = (self.view.lm_width - (self.columnNumber + 1) * itemMargin) / self.columnNumber;
    _layout.itemSize = CGSizeMake(itemWH, itemWH);
    _layout.minimumInteritemSpacing = itemMargin;
    _layout.minimumLineSpacing = itemMargin;;

    _collectionView = [[LMCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.frame = CGRectMake(0, 0, self.view.lm_width, self.view.lm_height);
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(itemMargin+_navBarView.lm_height, itemMargin, itemMargin, itemMargin);
    
    if (_showTakePhotoBtn) {
        _collectionView.contentSize = CGSizeMake(self.view.lm_width, ((_model.count + self.columnNumber) / self.columnNumber) * self.view.lm_width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.lm_width, ((_model.count + self.columnNumber - 1) / self.columnNumber) * self.view.lm_width);
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[LMAssetCell class] forCellWithReuseIdentifier:@"LMAssetCell"];
    [_collectionView registerClass:[LMAssetCameraCell class] forCellWithReuseIdentifier:@"LMAssetCameraCell"];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
}

- (void)configBottomToolBar {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (!imagePicker.showSelectBtn) return;
    
    CGFloat toolBarHeight = [LMCommonTools lm_isIPhoneX] ? 83 : 49;
    CGFloat toolBarTop = self.view.lm_height - toolBarHeight;
    
    _bottomToolBar = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomToolBar.frame = CGRectMake(0, toolBarTop, self.view.lm_width, toolBarHeight);
    _bottomToolBar.backgroundColor = [imagePicker.themeColor colorWithAlphaComponent:0.6];
    
    UIBlurEffect *barEffect = [UIBlurEffect effectWithStyle:imagePicker.blurEffectStyle];
    UIVisualEffectView *barEffectView = [[UIVisualEffectView alloc] initWithEffect:barEffect];
    barEffectView.frame = _bottomToolBar.bounds;
    [_bottomToolBar addSubview:barEffectView];

    if (imagePicker.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat fullImageWidth = [imagePicker.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(0, 0, fullImageWidth + 56, 49);
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:imagePicker.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePicker.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:imagePicker.textColor forState:UIControlStateSelected];
        [_originalPhotoButton setImage:imagePicker.photoOriginNorImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:imagePicker.photoOriginSelImage forState:UIControlStateSelected];
        _originalPhotoButton.imageView.clipsToBounds = YES;
        _originalPhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _originalPhotoButton.selected = _isSelectOriginalPhoto;
        _originalPhotoButton.enabled = imagePicker.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] initWithFrame:CGRectMake(fullImageWidth + 46, 0, 80, 49)];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:16];
        _originalPhotoLabel.textColor = imagePicker.textColor;
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:imagePicker.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitle:imagePicker.doneBtnTitleStr forState:UIControlStateDisabled];
    [_doneButton setTitleColor:imagePicker.btnTitleColorNormal forState:UIControlStateNormal];
    [_doneButton setTitleColor:imagePicker.btnTitleColorDisabled forState:UIControlStateDisabled];
    [_doneButton sizeToFit];
    _doneButton.frame = CGRectMake(self.view.lm_width - _doneButton.lm_width - 12, 0, _doneButton.lm_width, 50);
    _doneButton.enabled = imagePicker.selectedModels.count;
    
    _numberImageView = [[UIImageView alloc] initWithImage:imagePicker.photoNumberIconImage];
    _numberImageView.frame = CGRectMake(_doneButton.lm_left - 24 - 5, 13, 24, 24);
    _numberImageView.hidden = imagePicker.selectedModels.count <= 0;
    _numberImageView.clipsToBounds = YES;
    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.frame = _numberImageView.frame;
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",imagePicker.selectedModels.count];
    _numberLabel.hidden = imagePicker.selectedModels.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    
    _divideLine = [[UIView alloc] init];
    _divideLine.frame = CGRectMake(0, 0, self.view.lm_width, 1);
    CGFloat rgb2 = 222 / 255.0;
    _divideLine.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:0.7];
    
    [_bottomToolBar addSubview:_divideLine];
    [_bottomToolBar addSubview:_doneButton];
    [_bottomToolBar addSubview:_numberImageView];
    [_bottomToolBar addSubview:_numberLabel];
    [_bottomToolBar addSubview:_originalPhotoButton];
    [self.view addSubview:_bottomToolBar];
    [_originalPhotoButton addSubview:_originalPhotoLabel];
}



- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

#pragma mark - Album
- (LMAlbumPickerController *)albumPickerVc {
    if (!_albumPickerVc) {
        _albumPickerVc = [[LMAlbumPickerController alloc] init];
        _albumPickerVc.view.frame =CGRectMake(0, -self.view.lm_height, self.view.lm_width, self.view.lm_height-self->_navBarView.lm_height);
        [self.view addSubview:_albumPickerVc.view];
        [self addChildViewController:_albumPickerVc];
        
        __weak typeof(self) wself = self;
        [_albumPickerVc setAlbumPickerSelectedBlock:^(LMAlbumModel *model) {
            wself.model = model;
            [wself albumHide];
        }];
    }
    return _albumPickerVc;
}

- (void)albumShow {
    [UIView animateWithDuration:0.25 animations:^{
        self.albumPickerVc.view.frame = CGRectMake(0, self->_navBarView.lm_height, self.view.lm_width, self.view.lm_height-self->_navBarView.lm_height);
    } completion:nil];
}

- (void)albumHide {
    [UIView animateWithDuration:0.25 animations:^{
        self.albumPickerVc.view.frame =CGRectMake(0, -self.view.lm_height, self.view.lm_width, self.view.lm_height-self->_navBarView.lm_height);
    } completion:nil];
}

- (void)albumBtnClick:(UIButton *)albumBtn {
    albumBtn.selected = !albumBtn.selected;
    if (albumBtn.selected) {
        [self albumShow];
    } else {
        [self albumHide];
    }
}


#pragma mark - Alert
- (UIAlertController *)showAlertWithTitle:(NSString *)title {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle localizedStringForKey:@"OK"] style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
    return alertController;
}

- (void)hideAlertView:(UIAlertController *)alertView {
    [alertView dismissViewControllerAnimated:YES completion:nil];
    alertView = nil;
}

#pragma mark - Action
- (void)backBtnClick:(UIButton *)backBtn {
    [self.navigationController popViewControllerAnimated:YES];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    imagePicker.photoPicker = nil;
}

- (void)settingBtnClick {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self getSelectedPhotoBytes];
    }
}

#pragma mark - Click Event
- (void)doneButtonClick {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    // 1.6.8 判断是否满足最小必选张数的限制
    if (imagePicker.minImagesCount && imagePicker.selectedModels.count < imagePicker.minImagesCount) {
        NSString *title = [NSString stringWithFormat:[NSBundle localizedStringForKey:@"Select a minimum of %zd photos"], imagePicker.minImagesCount];
        [self showAlertWithTitle:title];
        return;
    }
    
    [self showProgressHUD];
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *photos;
    NSMutableArray *infoArr;
    if (imagePicker.onlyReturnAsset) { // not fetch image
        for (NSInteger i = 0; i < imagePicker.selectedModels.count; i++) {
            LMAssetModel *model = imagePicker.selectedModels[i];
            [assets addObject:model.asset];
        }
    } else { // fetch image
        photos = [NSMutableArray array];
        infoArr = [NSMutableArray array];
        for (NSInteger i = 0; i < imagePicker.selectedModels.count; i++) { [photos addObject:@1];[assets addObject:@1];[infoArr addObject:@1]; }
        
        __block BOOL havenotShowAlert = YES;
        __block UIAlertController *alertView;
        for (NSInteger i = 0; i < imagePicker.selectedModels.count; i++) {
            LMAssetModel *model = imagePicker.selectedModels[i];
            [[LMPhotoManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if (isDegraded) return;
                if (photo) {
                    if (!imagePicker.notScaleImage) {
                        photo = [[LMPhotoManager manager] scaleImage:photo toSize:CGSizeMake(imagePicker.photoWidth, (int)(imagePicker.photoWidth * photo.size.height / photo.size.width))];
                    }
                    [photos replaceObjectAtIndex:i withObject:photo];
                }
                if (info)  [infoArr replaceObjectAtIndex:i withObject:info];
                [assets replaceObjectAtIndex:i withObject:model.asset];
                
                for (id item in photos) { if ([item isKindOfClass:[NSNumber class]]) return; }
                
                if (havenotShowAlert) {
                    [self hideAlertView:alertView];
                    [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
                }
            } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                // 如果图片正在从iCloud同步中,提醒用户
                if (progress < 1 && havenotShowAlert && !alertView) {
                    [self hideProgressHUD];
                    alertView = [self showAlertWithTitle:[NSBundle localizedStringForKey:@"SyncLMonizing photos from iCloud"]];
                    havenotShowAlert = NO;
                    return;
                }
                if (progress >= 1) {
                    havenotShowAlert = YES;
                }
            } networkAccessAllowed:YES];
        }
    }
    if (imagePicker.selectedModels.count <= 0 || imagePicker.onlyReturnAsset) {
        [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
    }
}

- (void)didGetAllPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    [self hideProgressHUD];
    [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
}

- (void)callDelegateMethodWithPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (imagePicker.allowPickingVideo && imagePicker.maxImagesCount == 1) {
        if ([[LMPhotoManager manager] isVideo:[assets firstObject]]) {
            if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePicker:didFinishPickingVideo:sourceAssets:)]) {
                [imagePicker.pickerDelegate imagePicker:imagePicker didFinishPickingVideo:[photos firstObject] sourceAssets:[assets firstObject]];
            }
            return;
        }
    }
    
    if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePicker:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:)]) {
        [imagePicker.pickerDelegate imagePicker:imagePicker didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto];
    }
    if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePicker:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:)]) {
        [imagePicker.pickerDelegate imagePicker:imagePicker didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto infos:infoArr];
    }
}

#pragma mark - UICollectionViewDataSource && Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_showTakePhotoBtn) {
        return _models.count + 1;
    }
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (((imagePicker.sortAscendingByModificationDate && indexPath.item >= _models.count) || (!imagePicker.sortAscendingByModificationDate && indexPath.item == 0)) && _showTakePhotoBtn) {
        LMAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LMAssetCameraCell" forIndexPath:indexPath];
        cell.imageView.image = imagePicker.takePictureImage;
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    LMAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LMAssetCell" forIndexPath:indexPath];
    cell.allowPickingMultipleVideo = imagePicker.allowPickingMultipleVideo;
    cell.photoDefImage = imagePicker.photoNorImage;
    cell.photoSelImage = imagePicker.photoSelImage;
    cell.useCachedImage = self.useCachedImage;
    LMAssetModel *model;
    if (imagePicker.sortAscendingByModificationDate || !_showTakePhotoBtn) {
        model = _models[indexPath.item];
    } else {
        model = _models[indexPath.item - 1];
    }
    cell.allowPickingGif = NO;
    cell.model = model;
    if (model.isSelected && imagePicker.showSelectedIndex) {
        cell.index = [imagePicker.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1;
    }
    cell.showSelectBtn = imagePicker.showSelectBtn;
    cell.allowPreview = NO;
    
    if (imagePicker.selectedModels.count >= imagePicker.maxImagesCount && imagePicker.showPhotoCannotSelectLayer && !model.isSelected) {
        cell.cannotSelectLayerButton.backgroundColor = imagePicker.cannotSelectLayerColor;
        cell.cannotSelectLayerButton.hidden = NO;
    } else {
        cell.cannotSelectLayerButton.hidden = YES;
    }
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        __strong typeof(weakCell) strongCell = weakCell;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakLayer) strongLayer = weakLayer;
        LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
        // 1. cancel select / 取消选择
        if (imagePicker.maxImagesCount == 1) {
            [imagePicker.selectedModels removeAllObjects];
        }
        if (isSelected) {
            strongCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:imagePicker.selectedModels];
            for (LMAssetModel *model_item in selectedModels) {
                if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                    [imagePicker removeSelectedModel:model_item];
                    break;
                }
            }
            [strongSelf refreshBottomToolBarStatus];
            if (imagePicker.showSelectedIndex || imagePicker.showPhotoCannotSelectLayer) {
                [strongSelf setUseCachedImageAndReloadData];
            }
            [UIView showOscillatoryAnimationWithLayer:strongLayer type:LMOscillatoryAnimationToSmaller];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (imagePicker.selectedModels.count < imagePicker.maxImagesCount) {
                if (imagePicker.maxImagesCount == 1 ) {
                    model.isSelected = YES;
                    [imagePicker addSelectedModel:model];
                    [strongSelf doneButtonClick];
                    return;
                }
                strongCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                if (imagePicker.showSelectedIndex || imagePicker.showPhotoCannotSelectLayer) {
                    model.needOscillatoryAnimation = YES;
                    [strongSelf setUseCachedImageAndReloadData];
                }
                [imagePicker addSelectedModel:model];
                [strongSelf refreshBottomToolBarStatus];
                [UIView showOscillatoryAnimationWithLayer:strongLayer type:LMOscillatoryAnimationToSmaller];
            } else {
                NSString *title = [NSString stringWithFormat:[NSBundle localizedStringForKey:@"Select a maximum of %zd photos"], imagePicker.maxImagesCount];
                [self showAlertWithTitle:title];
            }
        }
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (((imagePicker.sortAscendingByModificationDate && indexPath.item >= _models.count) || (!imagePicker.sortAscendingByModificationDate && indexPath.item == 0)) && _showTakePhotoBtn)  {
        [self takePhoto]; return;
    }
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.item;
    if (!imagePicker.sortAscendingByModificationDate && _showTakePhotoBtn) {
        index = indexPath.item - 1;
    }
//    LMAssetModel *model = _models[index];
}

#pragma mark - Private Method
- (void)setUseCachedImageAndReloadData {
    self.useCachedImage = YES;
    [self.collectionView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.useCachedImage = NO;
    });
}

/// 拍照按钮点击事件
- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)) {
        
        NSDictionary *infoDict = [LMCommonTools lm_getInfoDictionary];
        // 无权限 做一个友好的提示
        NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
        
        NSString *message = [NSString stringWithFormat:[NSBundle localizedStringForKey:@"Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\""],appName];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSBundle localizedStringForKey:@"Can not use camera"] message:message delegate:self cancelButtonTitle:[NSBundle localizedStringForKey:@"Cancel"] otherButtonTitles:[NSBundle localizedStringForKey:@"Setting"], nil];
        [alert show];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pushImagePickerController];
                });
            }
        }];
    } else {
        [self pushImagePickerController];
    }
}

// 调用相机
- (void)pushImagePickerController {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: sourceType]) {
        self.imagePickerVc.sourceType = sourceType;
        NSMutableArray *mediaTypes = [NSMutableArray array];
        if (imagePicker.allowTakePicture) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        self.imagePickerVc.mediaTypes= mediaTypes;
        [self presentViewController:_imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)refreshBottomToolBarStatus {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    
    _doneButton.enabled = imagePicker.selectedModels.count > 0;
    
    _numberImageView.hidden = imagePicker.selectedModels.count <= 0;
    _numberLabel.hidden = imagePicker.selectedModels.count <= 0;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",imagePicker.selectedModels.count];
    
    _originalPhotoButton.enabled = imagePicker.selectedModels.count > 0;
    _originalPhotoButton.selected = (_isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLabel.hidden = (!_originalPhotoButton.isSelected);
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)getSelectedPhotoBytes {
    LMImagePicker *imagePickerVc = [LMImagePicker sharedImagePicker];
    [[LMPhotoManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
        self->_originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        [self showProgressHUD];
        UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (photo) {
            [[LMPhotoManager manager] savePhotoWithImage:photo location:nil completion:^(PHAsset *asset, NSError *error){
                if (!error) {
                    [self addPHAsset:asset];
                }
            }];
        }
    } else if ([type isEqualToString:@"public.movie"]) {
        [self showProgressHUD];
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            [[LMPhotoManager manager] saveVideoWithUrl:videoUrl location:nil completion:^(PHAsset *asset, NSError *error) {
                if (!error) {
                    [self addPHAsset:asset];
                }
            }];
        }
    }
}

- (void)addPHAsset:(PHAsset *)asset {
    LMAssetModel *assetModel = [[LMPhotoManager manager] createModelWithAsset:asset];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    [self hideProgressHUD];
    if (imagePicker.sortAscendingByModificationDate) {
        [_models addObject:assetModel];
    } else {
        [_models insertObject:assetModel atIndex:0];
    }
    
    if (imagePicker.maxImagesCount <= 1) {
        [imagePicker addSelectedModel:assetModel];
        [self doneButtonClick];
        return;
    }
    
    if (imagePicker.selectedModels.count < imagePicker.maxImagesCount) {
        if (assetModel.type == LMAssetModelMediaTypeVideo && !imagePicker.allowPickingMultipleVideo) {
            // 不能多选视频的情况下，不选中拍摄的视频
        } else {
            assetModel.isSelected = YES;
            [imagePicker addSelectedModel:assetModel];
            [self refreshBottomToolBarStatus];
        }
    }
    _collectionView.hidden = YES;
    [_collectionView reloadData];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation LMCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end
