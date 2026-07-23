Pod::Spec.new do |s|
  s.name             = 'native_route_picker'
  s.version          = '0.0.1'
  s.summary          = 'Native audio output route picker (AVRoutePickerView).'
  s.description      = <<-DESC
Embeds AVRoutePickerView so users can pick an AirPlay / Bluetooth / wired
output for audio playback.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ProdigyTech Inc.' => 'alex@nimbleindustries.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
