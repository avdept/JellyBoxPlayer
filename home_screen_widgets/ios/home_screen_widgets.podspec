Pod::Spec.new do |s|
  s.name             = 'home_screen_widgets'
  s.version          = '0.0.1'
  s.summary          = 'Shared storage and reloads for the home screen widgets.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ProdigyTech Inc.' => 'alex@nimbleindustries.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
