//
//  LMAssetCell.m
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import "LMAssetCell.h"
#import "LMImagePicker.h"
#import "LMAssetModel.h"
#import "UIView+LMLayout.h"
#import "UIImage+LMImagePicker.h"
#import "LMPhotoManager.h"
#import "LMProgressView.h"

@interface LMAssetCell ()
@property (weak, nonatomic) UIImageView *imageView;       // The photo / 照片
@property (weak, nonatomic) UIImageView *selectImageView;
@property (weak, nonatomic) UILabel *indexLabel;
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UILabel *timeLength;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic, weak) UIImageView *videoImgView;
@property (nonatomic, strong) LMProgressView *progressView;
@property (nonatomic, assign) int32_t bigImageRequestID;
@end

@implementation LMAssetCell

- (void)setModel:(LMAssetModel *)model {
    _model = model;
    self.representedAssetIdentifier = model.asset.localIdentifier;
    if (self.useCachedImage && model.cachedImage) {
        self.imageView.image = model.cachedImage;
    } else {
        self.model.cachedImage = nil;
        int32_t imageRequestID = [[LMPhotoManager manager] getPhotoWithAsset:model.asset photoWidth:self.lm_width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            // Set the cell's thumbnail image if it's still showing the same asset.
            if ([self.representedAssetIdentifier isEqualToString:model.asset.localIdentifier]) {
                self.imageView.image = photo;
                self.model.cachedImage = photo;
            } else {
                // NSLog(@"this cell is showing other asset");
                [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
            }
            if (!isDegraded) {
                [self hideProgressView];
                self.imageRequestID = 0;
            }
        } progressHandler:nil networkAccessAllowed:NO];
        if (imageRequestID && self.imageRequestID && imageRequestID != self.imageRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
            // NSLog(@"cancelImageRequest %d",self.imageRequestID);
        }
        self.imageRequestID = imageRequestID;
    }
    self.selectPhotoButton.selected = model.isSelected;
    self.selectImageView.image = self.selectPhotoButton.isSelected ? self.photoSelImage : self.photoDefImage;
    self.indexLabel.hidden = !self.selectPhotoButton.isSelected;
    
    self.type = (NSInteger)model.type;
    // 让宽度/高度小于 最小可选照片尺寸 的图片不能选中
    if (![[LMPhotoManager manager] isPhotoSelectableWithAsset:model.asset]) {
        if (_selectImageView.hidden == NO) {
            self.selectPhotoButton.hidden = YES;
            _selectImageView.hidden = YES;
        }
    }
    // 如果用户选中了该图片，提前获取一下大图
    if (model.isSelected) {
        [self requestBigImage];
    } else {
        [self cancelBigImageRequest];
    }
    if (model.needOscillatoryAnimation) {
        [UIView showOscillatoryAnimationWithLayer:self.selectImageView.layer type:LMOscillatoryAnimationToBigger];
    }
    model.needOscillatoryAnimation = NO;
    [self setNeedsLayout];
}

- (void)setIndex:(NSInteger)index {
    _index = index;
    self.indexLabel.text = [NSString stringWithFormat:@"%zd", index];
    [self.contentView bringSubviewToFront:self.indexLabel];
}

- (void)setShowSelectBtn:(BOOL)showSelectBtn {
    _showSelectBtn = showSelectBtn;
    BOOL selectable = [[LMPhotoManager manager] isPhotoSelectableWithAsset:self.model.asset];
    if (!self.selectPhotoButton.hidden) {
        self.selectPhotoButton.hidden = !showSelectBtn || !selectable;
    }
    if (!self.selectImageView.hidden) {
        self.selectImageView.hidden = !showSelectBtn || !selectable;
    }
}

- (void)setType:(LMAssetCellType)type {
    _type = type;
    if (type == LMAssetCellTypePhoto || type == LMAssetCellTypeLivePhoto || (type == LMAssetCellTypePhotoGif && !self.allowPickingGif) || self.allowPickingMultipleVideo) {
        _selectImageView.hidden = NO;
        _selectPhotoButton.hidden = NO;
        _bottomView.hidden = YES;
    } else { // Video of Gif
        _selectImageView.hidden = YES;
        _selectPhotoButton.hidden = YES;
    }
    
    if (type == LMAssetCellTypeVideo) {
        self.bottomView.hidden = NO;
        self.timeLength.text = _model.timeLength;
        self.videoImgView.hidden = NO;
        _timeLength.lm_left = self.videoImgView.lm_right;
        _timeLength.textAlignment = NSTextAlignmentRight;
    } else if (type == LMAssetCellTypePhotoGif && self.allowPickingGif) {
        self.bottomView.hidden = NO;
        self.timeLength.text = @"GIF";
        self.videoImgView.hidden = YES;
        _timeLength.lm_left = 5;
        _timeLength.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)setAllowPreview:(BOOL)allowPreview {
    _allowPreview = allowPreview;
    if (allowPreview) {
        _imageView.userInteractionEnabled = NO;
        _tapGesture.enabled = NO;
    } else {
        _imageView.userInteractionEnabled = YES;
        _tapGesture.enabled = YES;
    }
}

- (void)selectPhotoButtonClick:(UIButton *)sender {
    if (self.didSelectPhotoBlock) {
        self.didSelectPhotoBlock(sender.isSelected);
    }
    self.selectImageView.image = sender.isSelected ? self.photoSelImage : self.photoDefImage;
    if (sender.isSelected) {
        if (![LMImagePicker sharedImagePicker].showSelectedIndex && ![LMImagePicker sharedImagePicker].showPhotoCannotSelectLayer) {
            [UIView showOscillatoryAnimationWithLayer:_selectImageView.layer type:LMOscillatoryAnimationToBigger];
        }
        // 用户选中了该图片，提前获取一下大图
        [self requestBigImage];
    } else { // 取消选中，取消大图的获取
        [self cancelBigImageRequest];
    }
}

/// 只在单选状态且allowPreview为NO时会有该事件
- (void)didTapImageView {
    if (self.didSelectPhotoBlock) {
        self.didSelectPhotoBlock(NO);
    }
}

- (void)hideProgressView {
    if (_progressView) {
        self.progressView.hidden = YES;
        self.imageView.alpha = 1.0;
    }
}

- (void)requestBigImage {
    if (_bigImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_bigImageRequestID];
    }
    
    _bigImageRequestID = [[LMPhotoManager manager] requestImageDataForAsset:_model.asset completion:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        [self hideProgressView];
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        if (self.model.isSelected) {
            progress = progress > 0.02 ? progress : 0.02;;
            self.progressView.progress = progress;
            self.progressView.hidden = NO;
            self.imageView.alpha = 0.4;
            if (progress >= 1) {
                [self hideProgressView];
            }
        } else {
            *stop = YES;
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self cancelBigImageRequest];
        }
    }];
}

- (void)cancelBigImageRequest {
    if (_bigImageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:_bigImageRequestID];
    }
    [self hideProgressView];
}

#pragma mark - Lazy load

- (UIButton *)selectPhotoButton {
    if (_selectPhotoButton == nil) {
        UIButton *selectPhotoButton = [[UIButton alloc] init];
        [selectPhotoButton addTarget:self action:@selector(selectPhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:selectPhotoButton];
        _selectPhotoButton = selectPhotoButton;
    }
    return _selectPhotoButton;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [self.contentView addSubview:imageView];
        _imageView = imageView;
        
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImageView)];
        [_imageView addGestureRecognizer:_tapGesture];
    }
    return _imageView;
}

- (UIImageView *)selectImageView {
    if (_selectImageView == nil) {
        UIImageView *selectImageView = [[UIImageView alloc] init];
        selectImageView.contentMode = UIViewContentModeCenter;
        selectImageView.clipsToBounds = YES;
        [self.contentView addSubview:selectImageView];
        _selectImageView = selectImageView;
    }
    return _selectImageView;
}

- (UIView *)bottomView {
    if (_bottomView == nil) {
        UIView *bottomView = [[UIView alloc] init];
        static NSInteger rgb = 0;
        bottomView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.8];
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}

- (UIButton *)cannotSelectLayerButton {
    if (_cannotSelectLayerButton == nil) {
        UIButton *cannotSelectLayerButton = [[UIButton alloc] init];
        [self.contentView addSubview:cannotSelectLayerButton];
        _cannotSelectLayerButton = cannotSelectLayerButton;
    }
    return _cannotSelectLayerButton;
}

- (UIImageView *)videoImgView {
    if (_videoImgView == nil) {
        UIImageView *videoImgView = [[UIImageView alloc] init];
        [videoImgView setImage:[UIImage lm_imageNamedFromMyBundle:@"VideoSendIcon"]];
        [self.bottomView addSubview:videoImgView];
        _videoImgView = videoImgView;
    }
    return _videoImgView;
}

- (UILabel *)timeLength {
    if (_timeLength == nil) {
        UILabel *timeLength = [[UILabel alloc] init];
        timeLength.font = [UIFont boldSystemFontOfSize:11];
        timeLength.textColor = [UIColor whiteColor];
        timeLength.textAlignment = NSTextAlignmentRight;
        [self.bottomView addSubview:timeLength];
        _timeLength = timeLength;
    }
    return _timeLength;
}

- (UILabel *)indexLabel {
    if (_indexLabel == nil) {
        UILabel *indexLabel = [[UILabel alloc] init];
        indexLabel.font = [UIFont systemFontOfSize:14];
        indexLabel.textColor = [UIColor whiteColor];
        indexLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:indexLabel];
        _indexLabel = indexLabel;
    }
    return _indexLabel;
}

- (LMProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[LMProgressView alloc] init];
        _progressView.hidden = YES;
        [self addSubview:_progressView];
    }
    return _progressView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _cannotSelectLayerButton.frame = self.bounds;
    if (self.allowPreview) {
        _selectPhotoButton.frame = CGRectMake(self.lm_width - 44, 0, 44, 44);
    } else {
        _selectPhotoButton.frame = self.bounds;
    }
    _selectImageView.frame = CGRectMake(self.lm_width - 27, 3, 24, 24);
    if (_selectImageView.image.size.width <= 27) {
        _selectImageView.contentMode = UIViewContentModeCenter;
    } else {
        _selectImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    _indexLabel.frame = _selectImageView.frame;
    _imageView.frame = CGRectMake(0, 0, self.lm_width, self.lm_height);
    
    static CGFloat progressWH = 20;
    CGFloat progressXY = (self.lm_width - progressWH) / 2;
    _progressView.frame = CGRectMake(progressXY, progressXY, progressWH, progressWH);
    
    _bottomView.frame = CGRectMake(0, self.lm_height - 17, self.lm_width, 17);
    _videoImgView.frame = CGRectMake(8, 0, 17, 17);
    _timeLength.frame = CGRectMake(self.videoImgView.lm_right, 0, self.lm_width - self.videoImgView.lm_right - 5, 17);
    
    self.type = (NSInteger)self.model.type;
    self.showSelectBtn = self.showSelectBtn;
    
    [self.contentView bringSubviewToFront:_bottomView];
    [self.contentView bringSubviewToFront:_cannotSelectLayerButton];
    [self.contentView bringSubviewToFront:_selectPhotoButton];
    [self.contentView bringSubviewToFront:_selectImageView];
    [self.contentView bringSubviewToFront:_indexLabel];
}

@end

@interface LMAlbumCell ()
@property (weak, nonatomic) UIImageView *posterImageView;
@property (weak, nonatomic) UILabel *titleLabel;
@end

@implementation LMAlbumCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.backgroundColor = [UIColor clearColor];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return self;
}

- (void)setModel:(LMAlbumModel *)model {
    _model = model;
    
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:model.name attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:self.textColor}];
    NSAttributedString *countString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%zd)",model.count] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:self.textColor}];
    [nameString appendAttributedString:countString];
    self.titleLabel.attributedText = nameString;
    [[LMPhotoManager manager] getPostImageWithAlbumModel:model completion:^(UIImage *postImage) {
        self.posterImageView.image = postImage;
    }];
    if (model.selectedCount) {
        self.selectedCountButton.hidden = NO;
        [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%zd",model.selectedCount] forState:UIControlStateNormal];
    } else {
        self.selectedCountButton.hidden = YES;
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _selectedCountButton.frame = CGRectMake(self.contentView.lm_width - 24, 23, 24, 24);
    NSInteger titleHeight = ceil(self.titleLabel.font.lineHeight);
    self.titleLabel.frame = CGRectMake(80, (self.lm_height - titleHeight) / 2, self.lm_width - 80 - 50, titleHeight);
    self.posterImageView.frame = CGRectMake(0, 0, 70, 70);
    
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
}

#pragma mark - Lazy load

- (UIImageView *)posterImageView {
    if (_posterImageView == nil) {
        UIImageView *posterImageView = [[UIImageView alloc] init];
        posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        posterImageView.clipsToBounds = YES;
        [self.contentView addSubview:posterImageView];
        _posterImageView = posterImageView;
    }
    return _posterImageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont boldSystemFontOfSize:17];
        titleLabel.textColor = [LMImagePicker sharedImagePicker].textColor;
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:titleLabel];
        _titleLabel = titleLabel;
    }
    return _titleLabel;
}

- (UIButton *)selectedCountButton {
    if (_selectedCountButton == nil) {
        UIButton *selectedCountButton = [[UIButton alloc] init];
        selectedCountButton.layer.cornerRadius = 12;
        selectedCountButton.clipsToBounds = YES;
        selectedCountButton.backgroundColor = [UIColor redColor];
        [selectedCountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        selectedCountButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:selectedCountButton];
        _selectedCountButton = selectedCountButton;
    }
    return _selectedCountButton;
}

@end



@implementation LMAssetCameraCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

@end
