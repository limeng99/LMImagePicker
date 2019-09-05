//
//  NSBundle+LMImagePicker.m
//  LMImagePicker
//
//  Created by LM on 2019/9/4.
//  Copyright © 2019 LM. All rights reserved.
//

#import "NSBundle+LMImagePicker.h"
#import "LMImagePicker.h"

@implementation NSBundle (LMImagePicker)

+ (NSBundle *)imagePickerBundle {
    Class cls = NSClassFromString(@"LMImagePicker");
    if(!cls) return [NSBundle mainBundle];
    NSBundle *bundle = [NSBundle bundleForClass:cls];
    NSURL *url = [bundle URLForResource:@"LMImagePicker" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    return bundle;
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    return [self localizedStringForKey:key value:@""];
}

+ (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [LMImagePicker sharedImagePicker].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}


@end
