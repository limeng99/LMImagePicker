//
//  LMViewController.m
//  LMImagePicker
//
//  Created by LM on 09/04/2019.
//  Copyright (c) 2019 LM. All rights reserved.
//

#import "LMViewController.h"
#import "LMImagePicker.h"
#import "LMPreviewController.h"

@interface LMViewController ()<LMImagePickerDelegate>

@end

@implementation LMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *albumBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    albumBtn.center = CGPointMake(self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
    [albumBtn setTitle:@"相册" forState:UIControlStateNormal];
    [albumBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [albumBtn addTarget:self action:@selector(albumBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:albumBtn];
}

- (void)albumBtnAction {
    LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
    imagePicker.pickerDelegate = self;
    
//     imagePicker.maxImagesCount = 2;
//     imagePicker.pickerDelegate = self;
//     imagePicker.textColor = [UIColor whiteColor];
//     imagePicker.themeColor = [UIColor blackColor];
//     imagePicker.statusBarStyle = UIStatusBarStyleLightContent;
//     imagePicker.blurEffectStyle = UIBlurEffectStyleDark;
    
    [self.navigationController pushViewController:imagePicker.photoPicker animated:YES];
}

#pragma mark - LMImagePickerDelegate
- (void)imagePicker:(LMImagePicker *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    NSLog(@"---- %@", photos);
    LMPreviewController *previewVC = [[LMPreviewController alloc] init];
    previewVC.photos = photos;
    [self.navigationController pushViewController:previewVC animated:YES];
}


@end
