lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "apress/turbo_pages/version"

Gem::Specification.new do |spec|
  spec.metadata['allowed_push_host'] = 'https://gems.railsc.ru'

  spec.name          = 'apress-turbo_pages'
  spec.version       = Apress::TurboPages::VERSION
  spec.authors       = ['Aleksey Bukin']
  spec.email         = ['bukin242@yandex.ru']

  spec.summary       = %q{Turbo Pages}
  spec.description   = %q{Implements turbo pages}
  spec.homepage      = 'https://github.com/abak-press/apress-turbo_pages'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rails', '>= 4.0.13', '< 4.1'
  spec.add_runtime_dependency 'redis'
  spec.add_runtime_dependency 'resque-integration'
  spec.add_runtime_dependency 'sysloggable'
  spec.add_runtime_dependency 'apress-regions'
  spec.add_runtime_dependency 'apress-rubrics'
  spec.add_runtime_dependency 'apress-companies'
  spec.add_runtime_dependency 'apress-products'
  spec.add_runtime_dependency 'apress-packets'
  spec.add_runtime_dependency 'apress-trait_products'
  spec.add_runtime_dependency 'apress-company_abouts', '>= 1.4.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.7'
  spec.add_development_dependency 'rspec-rails', '>= 3.7'
  spec.add_development_dependency 'appraisal', '>= 1.0.2'
  spec.add_development_dependency 'combustion', '>= 0.9.1'
  spec.add_development_dependency 'factory_girl_rails'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'mock_redis'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'pry-byebug'
end
