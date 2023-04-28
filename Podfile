source 'https://github.com/CocoaPods/Specs.git'
# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
use_frameworks!

target 'chat-app-ios' do
  # Pods for chat-app-ios
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxDataSources'
  pod 'RxSwiftExt'
  pod 'RxSwiftUtilities'

  pod 'Then'

  pod 'SwiftPriorityQueue'
  pod 'Alamofire'
  pod 'SwiftyJSON'
  pod 'SDWebImage'
  pod 'KeychainAccess'

  # UI
  pod 'Toast-Swift'

  # sendbird
  pod 'SendbirdChatSDK'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
#      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
