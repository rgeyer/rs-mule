Gem::Specification.new do |gem|
  gem.name = "rs-mule"
  gem.version = "0.0.1"
  gem.homepage = "https://github.com/rgeyer/rs-mule"
  gem.license = "MIT"
  gem.summary = %Q{It runs "stuff"}
  gem.description = gem.summary
  gem.email = "me@ryangeyer.com"
  gem.authors = ["Ryan J. Geyer"]
  gem.executables << "rs-mule"

  gem.add_dependency("right_api_client", "= 1.5.15")
  gem.add_dependency("thor", "~> 0.18.1")

  gem.files = Dir.glob("{lib,bin}/**/*") + ["LICENSE", "README.md"]
end
