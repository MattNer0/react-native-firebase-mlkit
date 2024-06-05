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

	# Use install_modules_dependencies helper to install the dependencies if React Native version >=0.71.0.
	# See https://github.com/facebook/react-native/blob/febf6b7f33fdb4904669f99d795eba4c0f95d7bf/scripts/cocoapods/new_architecture.rb#L79.
	if respond_to?(:install_modules_dependencies, true)
		install_modules_dependencies(s)
	else
		s.dependency "React-Core"
	end
end
