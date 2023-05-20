# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'astrails/safe/version'

Gem::Specification.new do |spec|
  spec.name          = 'astrails-safe'
  spec.version       = Astrails::Safe::VERSION
  spec.authors       = ['Vitaly Kushner']
  spec.email         = ['we@astrails.com']
  spec.required_ruby_version = '>= 3.2'
  spec.description = <<-DESC
Astrails-Safe is a simple tool to backup databases (MySQL and PostgreSQL), Subversion repositories (with svndump) and just files.
Backups can be stored locally or remotely and can be enctypted.
Remote storage is supported on Amazon S3, Rackspace Cloud Files, or just plain FTP/SFTP.
DESC
  spec.summary       = 'Backup filesystem and databases (MySQL and PostgreSQL) locally or to a remote server/service (with encryption)'
  spec.homepage      = 'http://astrails.com/blog/astrails-safe'
  spec.license       = 'MIT'

  spec.default_executable = 'astrails-safe'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-s3'
  spec.add_dependency 'cloudfiles'
  spec.add_dependency 'net-sftp'

end
