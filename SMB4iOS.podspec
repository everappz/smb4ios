Pod::Spec.new do |s|
  s.name         = "SMB4iOS"
  s.version      = "1.0.0"
  s.summary      = "smb4ios is a basic SMB implementation in native Objective C. It is by no means complete or stable, and no particular effort is made to make it a reusable library. However, it contains enough know-how to provide you with a start for understanding SMB and implementing your own tasks."
  s.homepage     = "https://sourceforge.net/projects/smb4ios/"
  s.license      = 'MIT'
  s.author       = { "Nikita Frolov" => "https://sourceforge.net/u/gnawer/profile/" }
  s.source       = { :git => "https://github.com/leshkoapps/smb4ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.source_files = 'Common/*.{h,m}', 'Lib/categories/*.{h,c}', 'SMB/*.{h,m}', 'SMB/DCERPC/*.{h,m}', 'SMB/NetBIOS/*.{h,m}', 'SMB/RAP/*.{h,m}'
  s.requires_arc = true
  s.frameworks = 'Foundation', 'CFNetwork'
end
