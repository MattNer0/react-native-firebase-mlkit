require 'json'

packageJson = JSON.parse(File.read('package.json'))
version = packageJson["version"]
repository = packageJson["repository"]["url"]

Pod::Spec.new do |s|
	s.name           = "GoogleMlkit"
	s.version        = version
	s.description    = packageJson["description"]
	s.homepage       = packageJson["homepage"]
	s.summary        = packageJson["description"]
	s.license        = packageJson["license"]
	s.authors        = packageJson["author"]
	s.source         = { :git => repository, :tag => version }
	s.platforms      = { :ios => "11.0" }
	s.preserve_paths = 'README.md', 'package.json', '*.js'
	s.source_files   = "ios/**/*.{h,m,mm}"

	s.dependency "React-Core"
end
