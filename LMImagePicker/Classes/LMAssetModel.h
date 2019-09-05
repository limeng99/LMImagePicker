//
//  LMAssetModel.h
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    LMAssetModelMediaTypePhoto = 0,
    LMAssetModelMediaTypeLivePhoto,
    LMAssetModelMediaTypePhotoGif,
    LMAssetModelMediaTypeVideo,
    LMAssetModelMediaTypeAudio
} LMAssetModelMediaType;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;
@interface LMAssetModel : NSObject

@property (nonatomic, strong) PHAsset   *asset;
@property (nonatomic, assign) BOOL      isSelected;
@property (assign, nonatomic) BOOL      needOscillatoryAnimation;
@property (nonatomic, assign) LMAssetModelMediaType type;
@property (nonatomic, copy) NSString    *timeLength;
@property (nonatomic, strong, nullable) UIImage *cachedImage;

+ (instancetype)modelWithAsset:(PHAsset *)asset type:(LMAssetModelMediaType)type;
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(LMAssetModelMediaType)type timeLength:(NSString *)timeLength;

@end

@class PHFetchResult;
@interface LMAlbumModel : NSObject

@property (nonatomic, strong) NSString      *name;
@property (nonatomic, assign) NSInteger     count;
@property (nonatomic, strong) PHFetchResult *result;

@property (nonatomic, strong) NSArray       *models;
@property (nonatomic, strong) NSArray       *selectedModels;
@property (nonatomic, assign) NSUInteger    selectedCount;
@property (nonatomic, assign) BOOL          isCameraRoll;

- (void)setResult:(PHFetchResult *)result needFetchAssets:(BOOL)needFetchAssets;

@end

NS_ASSUME_NONNULL_END
