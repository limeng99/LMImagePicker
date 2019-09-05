//
//  LMAlbumPickerController.m
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import "LMAlbumPickerController.h"
#import "LMImagePicker.h"
#import "UIView+LMLayout.h"
#import "LMAssetCell.h"
#import "LMPhotoManager.h"

@interface LMAlbumPickerController ()<UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
}

@property (nonatomic, strong) NSMutableArray *albumArr;

@end

@implementation LMAlbumPickerController

- (void)dealloc {
    NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    self.view.backgroundColor = [imagePicker.themeColor colorWithAlphaComponent:0.6];
    
    UIBlurEffect *barEffect = [UIBlurEffect effectWithStyle:imagePicker.blurEffectStyle];
    UIVisualEffectView *barEffectView = [[UIVisualEffectView alloc] initWithEffect:barEffect];
    barEffectView.frame = self.view.bounds;
    [self.view addSubview:barEffectView];
    
    [self configTableView];
}

- (void)configTableView {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[LMPhotoManager manager] getAllAlbums:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage needFetchAssets:NO completion:^(NSArray<LMAlbumModel *> *models) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_albumArr = [NSMutableArray arrayWithArray:models];
                for (LMAlbumModel *albumModel in self->_albumArr) {
                    albumModel.selectedModels = imagePicker.selectedModels;
                }
                if (!self->_tableView) {
                    self->_tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
                    self->_tableView.frame = CGRectMake(0, 0, self.view.lm_width, self.view.lm_height);
                    self->_tableView.rowHeight = 70;
                    self->_tableView.backgroundColor = [UIColor clearColor];
                    self->_tableView.tableFooterView = [[UIView alloc] init];
                    self->_tableView.dataSource = self;
                    self->_tableView.delegate = self;
                    [self->_tableView registerClass:[LMAlbumCell class] forCellReuseIdentifier:@"LMAlbumCell"];
                    [self.view addSubview:self->_tableView];
                    self.edgesForExtendedLayout = UIRectEdgeNone;
#ifdef __IPHONE_11_0
                    if (@available(iOS 11.0, *)) {
                        self->_tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                    }
#endif
                } else {
                    [self->_tableView reloadData];
                }
            });
        }];
    });
}

#pragma mark - UITableViewDataSource && Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LMAlbumCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    cell.selectedCountButton.backgroundColor = imagePicker.iconThemeColor;
    cell.textColor = imagePicker.textColor;
    cell.model = _albumArr[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LMAlbumModel *model = _albumArr[indexPath.row];
    if (self.albumPickerSelectedBlock) {
        self.albumPickerSelectedBlock(model);
    }
}

@end
