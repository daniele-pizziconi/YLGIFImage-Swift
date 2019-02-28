Pod::Spec.new do |s|
  s.name             = "YLGIFImage-Swift"
  s.version          = "1.0"
  s.summary          = "Swift implementation of YLGIFImage."
  s.description      = <<-DESC
                       Swift implementation of YLGIFImage.
                       DESC
  s.homepage         = "https://github.com/daniele-pizziconi/YLGIFImage-Swift"
  s.license          = 'MIT'
  s.author           = { "Yong Li" => "liyong03@gmail.com" }
  s.source           = { :git => "https://github.com/daniele-pizziconi/YLGIFImage-Swift.git", :tag => s.version.to_s }

  s.swift_version = "4.2"

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files  = 'YLGIFImage-Swift/*.swift''
end
