
Pod::Spec.new do |s|
  s.name             = "LMImagePicker"
  s.version          = "0.1.3"
  s.summary          = "自定义相册"
  s.homepage         = "https://github.com/limeng99/LMImagePicker"
  s.license          = "MIT"
  s.author           = { "Limeng" => "LM" }
  s.source           = { :git => "https://github.com/limeng99/LMImagePicker", :tag => "0.1.3" }
  s.platform         = :ios
  s.requires_arc     = true
  s.ios.deployment_target = "8.0"
  s.source_files     = "LMImagePicker/Classes/*.{h,m}"
  s.resources        = "LMImagePicker/Classes/Resources/LMImagePicker.bundle"
  s.frameworks       = "Photos", "CoreServices"
#  header
#  s.public_header_files = "LMImagePicker/Classes/LMImagePicker.h"
#  sub folder
#  s.subspec 'xxx' do |ss|
#      ss.source_files = "LMImagePicker/Classes/xxx/*"
#  end
end
