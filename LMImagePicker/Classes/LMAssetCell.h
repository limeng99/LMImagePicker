//
//  LMAssetCell.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef enum : NSUInteger {
    LMAssetCellTypePhoto = 0,
    LMAssetCellTypeLivePhoto,
    LMAssetCellTypePhotoGif,
    LMAssetCellTypeVideo,
    LMAssetCellTypeAudio,
} LMAssetCellType;

@class LMAssetModel;
@interface LMAssetCell : UICollectionViewCell
@property (weak, nonatomic) UIButton  *selectPhotoButton;
@property (weak, nonatomic) UIButton    *cannotSelectLayerButton;
@property (nonatomic, strong) LMAssetModel *model;
@property (assign, nonatomic) NSInteger index;
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL);
@property (nonatomic, assign) LMAssetCellType type;
@property (nonatomic, assign) BOOL allowPickingGif;
@property (nonatomic, assign) BOOL allowPickingMultipleVideo;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@property (nonatomic, assign) int32_t imageRequestID;

@property (nonatomic, strong) UIImage *photoSelImage;
@property (nonatomic, strong) UIImage *photoDefImage;

@property (nonatomic, assign) BOOL showSelectBtn;
@property (assign, nonatomic) BOOL allowPreview;
@property (assign, nonatomic) BOOL useCachedImage;

@end


@class LMAlbumModel;
@interface LMAlbumCell : UITableViewCell
@property (nonatomic, strong) UIColor       *textColor;
@property (nonatomic, strong) LMAlbumModel  *model;
@property (weak, nonatomic) UIButton        *selectedCountButton;

@end

@interface LMAssetCameraCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@end
