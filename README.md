# LMImagePicker

## 项目介绍

一个支持多选、选原图的图片选择器，支持iOS8+.

## 集成方式

```ruby
pod 'LMImagePicker'~>0.1.0
```

## 集成要求
LMImagePicker使用了相机、相册，请添加下列属性到info.plist文件：        
`Privacy - Camera Usage Description`     
`Privacy - Photo Library Usage Description`

## 使用方法
```
LMImagePicker *imagePicker = [LMImagePicker sharedImagePicker];
imagePicker.pickerDelegate = self;
[self.navigationController pushViewController:imagePicker.photoPicker animated:YES];

#pragma mark - LMImagePickerDelegate
- (void)imagePicker:(LMImagePicker *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
NSLog(@"---- %@", photos);
}
```
