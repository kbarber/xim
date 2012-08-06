require 'rake/testtask'
require 'rubygems/package_task'

Rake::TestTask.new do |t|
  t.libs.push "test/lib"
  t.pattern = "test/**/*_test.rb"
end

spec = Gem::Specification.new do |spec|
  spec.name = 'xim'
  spec.version = '0.0.1'
  spec.summary = 'vim-clone text editor'
  spec.description = 'vim-clone text editor'

  spec.require_paths << 'lib'
  spec.bindir = 'bin'
  spec.executables << 'xim'

  spec.author = 'Ken Barber'
  spec.email = 'ken@bob.sh'
  spec.homepage = 'https://github.com/kbarber/xim'

  spec.files = Dir.glob("{bin,lib}/**/*") + %w(README.md)
end

Gem::PackageTask.new(spec) do |pkg|
end
