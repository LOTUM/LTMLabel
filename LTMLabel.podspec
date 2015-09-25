Pod::Spec.new do |s|
  s.name                = "LTMLabel"
  s.version             = "1.0.2"
  s.summary             = "Label with capability to multiple stroke, multiple inner shadow, gradient and resizing. Supports attributed strings"
  s.description         = <<-DESC
                          LTMLabel draws attributed strings with all their options (Tabs, different fonts, colors, attachments) and adds the possibility to draw multiple strokes, multiple inner shadow and/or a gradient
                          DESC
  s.homepage            = "http://www.lotum.com"
  s.license             = 'MIT'
  s.authors             = { "LOTUM GmbH" => "github@lotum.de" }
  s.platform            = :ios, '7.0'
  s.source              = { :git => "https://github.com/LOTUM/LTMLabel.git", :tag => s.version }
  s.source_files        = 'LTMLabel/Files/**/*.{h,m}'
  s.frameworks          = 'UIKit'
  s.requires_arc        = true

end

