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
    NSMutableArray *_models;
    
    UIView *_bottomToolBar;
    UIButton *_previewButton;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    UIView *_divideLine;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
    
    CGFloat _offsetItemCount;
    
    UIView *_navBarView;
    UIButton *_titleBtn;
    
    UILabel *_tipLabel;
    UIButton *_settingBtn;
}
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) LMCollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (strong, nonatomic) CLLocation *location;
@property (assign, nonatomic) BOOL useCachedImage;

@property (nonatomic, strong) LMAlbumPickerController *albumPickerVc;

@end

static CGSize AssetGridThumbnailSize;
static CGFloat itemMargin = 5;

@implementation LMPhotoPickerController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
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

- (void)viewDidLoad {
    [super viewDidLoad];

    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    _isSelectOriginalPhoto = imagePicker.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;
    
    CGFloat hiddenStatusHeight = [LMCommonTools lm_statusBarHideHeight];
    
    self.view.backgroundColor = imagePicker.themeColor;;
    _navBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.lm_width, hiddenStatusHeight+50)];
    _navBarView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    [self.view addSubview:_navBarView];
    
    UIBlurEffect *barEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *barEffectView = [[UIVisualEffectView alloc] initWithEffect:barEffect];
    barEffectView.frame = _navBarView.bounds;
    [_navBarView addSubview:barEffectView];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, hiddenStatusHeight+10, 30, 30)];
    [backBtn setImage:[UIImage imageNamedFromMyBundle:@"nav_back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_navBarView addSubview:backBtn];
    
    NSString *title = @"Photos";
    _titleBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, hiddenStatusHeight, self.view.lm_width-180, 50)];
    _titleBtn.lm_centerX = self.view.lm_width*0.5;
    _titleBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [_titleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_titleBtn setTitle:title forState:UIControlStateNormal];
    [_titleBtn setImage:imagePicker.photoAlbumArrowImage forState:UIControlStateNormal];
    [_titleBtn lm_setButtonImagePosition:LMButtonImagePositionRight spacing:6];
    [_titleBtn addTarget:self action:@selector(albumBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_navBarView addSubview:_titleBtn];
    
}

- (void)setModel:(LMAlbumModel *)model {
    _model = model;
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    _showTakePhotoBtn = imagePicker.allowTakePicture;
    NSString *title = !model.name ? @"Photos" : model.name;
    [_titleBtn setTitle:title forState:UIControlStateNormal];
    [_titleBtn lm_setButtonImagePosition:LMButtonImagePositionRight spacing:6];
    [self fetchAssetModels];
    [self.albumPickerVc configTableView];
}

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

- (void)backBtnClick:(UIButton *)backBtn {
    [self.navigationController popViewControllerAnimated:YES];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    imagePicker.photoPicker = nil;
}

- (void)fetchAssetModels {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (!_model.models.count) {
        [imagePicker showProgressHUD];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!imagePicker.sortAscendingByModificationDate && self->_model.isCameraRoll) {
            [[LMPhotoManager manager] getCameraRollAlbum:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage needFetchAssets:YES completion:^(LMAlbumModel *model) {
                self->_model = model;
                self->_models = [NSMutableArray arrayWithArray:self->_model.models];
                [self initSubviews];
            }];
        } else {
            if (self->_showTakePhotoBtn ) {
                [[LMPhotoManager manager] getAssetsFromFetchResult:self->_model.result completion:^(NSArray<LMAssetModel *> *models) {
                    self->_models = [NSMutableArray arrayWithArray:models];
                    [self initSubviews];
                }];
            } else {
                self->_models = [NSMutableArray arrayWithArray:self->_model.models];
                [self initSubviews];
            }
        }
    });
}

- (void)initSubviews {
    dispatch_async(dispatch_get_main_queue(), ^{
        LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
        [imagePicker hideProgressHUD];
        
        [self checkSelectedModels];
        if (!self.collectionView) {
            [self configCollectionView];
            self->_collectionView.hidden = YES;
            [self configBottomToolBar];
            [self scrollCollectionViewToBottom];
            [self.view bringSubviewToFront:self.albumPickerVc.view];
            [self.view bringSubviewToFront:self->_navBarView];
            if (self->_settingBtn) {
                [self.view bringSubviewToFront:self->_tipLabel];
                [self.view bringSubviewToFront:self->_settingBtn];
            }
        } else {
            [self.collectionView reloadData];
        }
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    imagePicker.isSelectOriginalPhoto = _isSelectOriginalPhoto;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[LMCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
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
    
#pragma mark - add
    [self albumPickerVc];
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

- (void)showSetting {
    
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    
    _tipLabel = [[UILabel alloc] init];
    _tipLabel.frame = CGRectMake(8, 120, self.view.lm_width - 16, 60);
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    _tipLabel.numberOfLines = 0;
    _tipLabel.font = [UIFont systemFontOfSize:16];
    _tipLabel.textColor = [UIColor blackColor];
    
    NSDictionary *infoDict = [LMCommonTools lm_getInfoDictionary];
    NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
    if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
    NSString *tipText = [NSString stringWithFormat:[NSBundle localizedStringForKey:@"Allow %@ to access your album in \"Settings -> Privacy -> Photos\""],appName];
    _tipLabel.text = tipText;
    [self.view addSubview:_tipLabel];
    
    _settingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingBtn setTitle:imagePicker.settingBtnTitleStr forState:UIControlStateNormal];
    _settingBtn.frame = CGRectMake(0, 180, self.view.lm_width, 44);
    _settingBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [_settingBtn addTarget:self action:@selector(settingBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_settingBtn];
}

- (void)hideSetting {
    [_tipLabel removeFromSuperview];
    [_settingBtn removeFromSuperview];
}

- (void)settingBtnClick {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)configBottomToolBar {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (!imagePicker.showSelectBtn) return;
    
    _bottomToolBar = [[UIView alloc] initWithFrame:CGRectZero];
    //    CGFloat rgb = 253 / 255.0;
    _bottomToolBar.backgroundColor = imagePicker.themeColor;
    
    if (imagePicker.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:imagePicker.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePicker.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:imagePicker.photoOriginNorImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:imagePicker.photoOriginSelImage forState:UIControlStateSelected];
        _originalPhotoButton.imageView.clipsToBounds = YES;
        _originalPhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _originalPhotoButton.selected = _isSelectOriginalPhoto;
        _originalPhotoButton.enabled = imagePicker.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:16];
        _originalPhotoLabel.textColor = [UIColor blackColor];
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:imagePicker.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitle:imagePicker.doneBtnTitleStr forState:UIControlStateDisabled];
    [_doneButton setTitleColor:imagePicker.btnTitleColorNormal forState:UIControlStateNormal];
    [_doneButton setTitleColor:imagePicker.btnTitleColorDisabled forState:UIControlStateDisabled];
    _doneButton.enabled = imagePicker.selectedModels.count;
    
    _numberImageView = [[UIImageView alloc] initWithImage:imagePicker.photoNumberIconImage];
    _numberImageView.hidden = imagePicker.selectedModels.count <= 0;
    _numberImageView.clipsToBounds = YES;
    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",imagePicker.selectedModels.count];
    _numberLabel.hidden = imagePicker.selectedModels.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    
    _divideLine = [[UIView alloc] init];
    CGFloat rgb2 = 222 / 255.0;
    _divideLine.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:0.7];
    
    [_bottomToolBar addSubview:_divideLine];
    [_bottomToolBar addSubview:_previewButton];
    [_bottomToolBar addSubview:_doneButton];
    [_bottomToolBar addSubview:_numberImageView];
    [_bottomToolBar addSubview:_numberLabel];
    [_bottomToolBar addSubview:_originalPhotoButton];
    [self.view addSubview:_bottomToolBar];
    [_originalPhotoButton addSubview:_originalPhotoLabel];
    
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    
    _collectionView.frame = CGRectMake(0, 0, self.view.lm_width, self.view.lm_height);
    CGFloat itemWH = (self.view.lm_width - (self.columnNumber + 1) * itemMargin) / self.columnNumber;
    _layout.itemSize = CGSizeMake(itemWH, itemWH);
    _layout.minimumInteritemSpacing = itemMargin;
    _layout.minimumLineSpacing = itemMargin;
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetY = _offsetItemCount * (_layout.itemSize.height + _layout.minimumLineSpacing);
        [_collectionView setContentOffset:CGPointMake(0, offsetY)];
    }
    
    CGFloat toolBarHeight = [LMCommonTools lm_isIPhoneX] ? 50 + (83 - 49) : 50;
    CGFloat toolBarTop = self.view.lm_height - toolBarHeight;
    _bottomToolBar.frame = CGRectMake(0, toolBarTop, self.view.lm_width, toolBarHeight);

    if (imagePicker.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [imagePicker.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(CGRectGetMaxX(_previewButton.frame), 0, fullImageWidth + 56, 50);
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 46, 0, 80, 50);
    }
    [_doneButton sizeToFit];
    _doneButton.frame = CGRectMake(self.view.lm_width - _doneButton.lm_width - 12, 0, _doneButton.lm_width, 50);
    _numberImageView.frame = CGRectMake(_doneButton.lm_left - 24 - 5, 13, 24, 24);
    _numberLabel.frame = _numberImageView.frame;
    _divideLine.frame = CGRectMake(0, 0, self.view.lm_width, 1);
    
    [self.collectionView reloadData];
    
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.y / (_layout.itemSize.height + _layout.minimumLineSpacing);
}

#pragma mark - Click Event
- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self getSelectedPhotoBytes];
    }
}

- (void)doneButtonClick {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    // 1.6.8 判断是否满足最小必选张数的限制
    if (imagePicker.minImagesCount && imagePicker.selectedModels.count < imagePicker.minImagesCount) {
        NSString *title = [NSString stringWithFormat:[NSBundle localizedStringForKey:@"Select a minimum of %zd photos"], imagePicker.minImagesCount];
        [imagePicker showAlertWithTitle:title];
        return;
    }
    
    [imagePicker showProgressHUD];
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
                    [imagePicker hideAlertView:alertView];
                    [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
                }
            } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                // 如果图片正在从iCloud同步中,提醒用户
                if (progress < 1 && havenotShowAlert && !alertView) {
                    [imagePicker hideProgressHUD];
                    alertView = [imagePicker showAlertWithTitle:[NSBundle localizedStringForKey:@"SyncLMonizing photos from iCloud"]];
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
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    [imagePicker hideProgressHUD];
    
    [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
}

- (void)callDelegateMethodWithPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (imagePicker.allowPickingVideo && imagePicker.maxImagesCount == 1) {
        if ([[LMPhotoManager manager] isVideo:[assets firstObject]]) {

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
                [imagePicker showAlertWithTitle:title];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // [self updateCachedAssets];
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
    
    _previewButton.enabled = imagePicker.selectedModels.count > 0;
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

- (void)scrollCollectionViewToBottom {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    if (_shouldScrollToBottom && _models.count > 0) {
        NSInteger item = 0;
        if (imagePicker.sortAscendingByModificationDate) {
            item = _models.count - 1;
            if (_showTakePhotoBtn) {
                item += 1;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            self->_shouldScrollToBottom = NO;
            self->_collectionView.hidden = NO;
        });
    } else {
        _collectionView.hidden = NO;
    }
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
        LMImagePicker *imagePickerVc = [LMImagePicker sharedImagePicker];
        [imagePickerVc showProgressHUD];
        UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (photo) {
            [[LMPhotoManager manager] savePhotoWithImage:photo location:self.location completion:^(PHAsset *asset, NSError *error){
                if (!error) {
                    [self addPHAsset:asset];
                }
            }];
            self.location = nil;
        }
    } else if ([type isEqualToString:@"public.movie"]) {
        LMImagePicker *imagePickerVc = [LMImagePicker sharedImagePicker];
        [imagePickerVc showProgressHUD];
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            [[LMPhotoManager manager] saveVideoWithUrl:videoUrl location:self.location completion:^(PHAsset *asset, NSError *error) {
                if (!error) {
                    [self addPHAsset:asset];
                }
            }];
            self.location = nil;
        }
    }
}

- (void)addPHAsset:(PHAsset *)asset {
    LMAssetModel *assetModel = [[LMPhotoManager manager] createModelWithAsset:asset];
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    [imagePicker hideProgressHUD];
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
    
    _shouldScrollToBottom = YES;
    [self scrollCollectionViewToBottom];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    // NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
//    [[LMPhotoManager manager].cachingImageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [[LMPhotoManager manager].cachingImageManager startCachingImagesForAssets:assetsToStartCaching
                                                                       targetSize:AssetGridThumbnailSize
                                                                      contentMode:PHImageContentModeAspectFill
                                                                          options:nil];
        [[LMPhotoManager manager].cachingImageManager stopCachingImagesForAssets:assetsToStopCaching
                                                                      targetSize:AssetGridThumbnailSize
                                                                     contentMode:PHImageContentModeAspectFill
                                                                         options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < _models.count) {
            LMAssetModel *model = _models[indexPath.item];
            [assets addObject:model.asset];
        }
    }
    
    return assets;
}

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}
#pragma clang diagnostic pop

@end



@implementation LMCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end
