require './app'

IMGKit.configure do |config|
  config.wkhtmltoimage = (Pathname.new(settings.root).join('bin', 'wkhtmltoimage-amd64')).to_s if ENV['RACK_ENV'] == 'production'
end

if ENV['RACK_ENV'] == 'production'
  font_dir = File.join(Dir.home, ".fonts")
  Dir.mkdir(font_dir) unless Dir.exists?(font_dir)

  Dir.glob(Pathname.new(Dir.home).join("public","fonts","*")).each do |font|
    target = File.join(font_dir, File.basename(font))
    File.symlink(font, target) unless File.exists?(target)
  end
end

run Sinatra::Application