#
# Be sure to run `pod lib lint RTHeadedColumnView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RTHeadedColumnView'
  s.version          = '0.1.8'
  s.summary          = 'A common headed column view.'
  s.description      = <<-DESC
                       The control is like Android's ViewPager, which has many columns of content to display and share a common header.
                       DESC

  s.homepage         = 'https://github.com/rickytan/RTHeadedColumnView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rickytan' => 'ricky.tan.xin@gmail.com' }
  s.source           = { :git => 'https://github.com/rickytan/RTHeadedColumnView.git', :tag => s.version.to_s }
  s.social_media_url = 'http://rickytan.cn'

  s.ios.deployment_target = '6.0'

  s.source_files = 'RTHeadedColumnView/Classes/**/*'

  # s.resource_bundles = {
  #   'RTHeadedColumnView' => ['RTHeadedColumnView/Assets/*.png']
  # }

  s.public_header_files = 'RTHeadedColumnView/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
