//
//  LMPreviewController.m
//  LMImagePicker_Example
//
//  Created by LM on 2019/9/6.
//  Copyright © 2019 LM. All rights reserved.
//

#import "LMPreviewController.h"

@interface LMPreviewController ()

@end

@implementation LMPreviewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    CGRect navRect = self.navigationController.navigationBar.frame;
    CGFloat navHeight = statusRect.size.height+navRect.size.height;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, navHeight, screenWidth, screenHeight-navHeight)];
    scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(screenWidth*self.photos.count, screenHeight-navHeight);
    [self.view addSubview:scrollView];
    
    [self.photos enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(screenWidth*idx, 0, screenWidth, screenHeight-navHeight)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:imageView];
    }];
}


@end
