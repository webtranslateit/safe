require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'webtranslateit/safe/version'

Gem::Specification.new do |spec|
  spec.name          = 'webtranslateit-safe'
  spec.version       = WebTranslateIt::Safe::VERSION
  spec.authors       = ['Edouard Briere', 'Vitaly Kushner']
  spec.email         = ['support@webtranslateit.com']
  spec.required_ruby_version = '>= 3.2'
  spec.description = <<~DESC
    WebTranslateIt-Safe is a simple tool to backup databases (MySQL and PostgreSQL), Subversion repositories (with svndump) and just files.
    Backups can be stored locally or remotely and can be enctypted.
    Remote storage is supported on Amazon S3, Rackspace Cloud Files, or just plain FTP/SFTP.
  DESC
  spec.summary       = 'Backup filesystem and databases (MySQL and PostgreSQL) locally or to a remote server/service (with encryption)'
  spec.homepage      = 'https://github.com/webtranslateit/safe'
  spec.license       = 'MIT'

  spec.default_executable = 'webtranslateit-safe'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-s3'
  spec.add_dependency 'cloudfiles'
  spec.add_dependency 'net-sftp'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
