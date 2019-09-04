
Pod::Spec.new do |s|
  s.name             = 'LMImagePicker'
  s.version          = '0.0.1'
  s.summary          = '自定义相册'
  s.description      = <<-DESC
        自定义相册
                       DESC
  s.homepage         = 'https://github.com/limeng99/LMImagePicker'
  s.license          = 'MIT'
  s.author           = { 'Limeng' => '1805441570@qq.com' }
  s.source           = { :git => 'https://github.com/limeng99/LMImagePicker', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'

  s.source_files = 'LMImagePicker/Classes/**/*'

  s.resource_bundles = {
     'LMImagePicker' => ['LMImagePicker/Assets/*.png']
  }

end
