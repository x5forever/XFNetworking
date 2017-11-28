Pod::Spec.new do |s|
  s.name             = 'XFNetworking'
  s.version          = '1.0.0'
  s.summary          = '基于 AFNetWorking 的二次封装'
  s.description      = <<-DESC
XFNetworking 是基于 AFNetWorking 的二次封装的基类,加解密逻辑，需要再包一层。
                       DESC

  s.homepage         = 'https://github.com/x5forever'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'x5' => 'x5forever@163.com' }
  s.source           = { :git => 'https://github.com/x5forever/XFNetworking.git', :tag => 'V'+s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.source_files = 'XFNetworking/XFNetworking/Classes/*.{h,m}'
  s.dependency 'AFNetworking', '~>3.1.0'

end
