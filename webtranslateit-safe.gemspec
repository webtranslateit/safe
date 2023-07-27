lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'webtranslateit-safe'
  spec.version       = '0.4.11'
  spec.authors       = ['Edouard Briere', 'Vitaly Kushner']
  spec.email         = ['support@webtranslateit.com']
  spec.required_ruby_version = '>= 3.2'
  spec.description = <<~DESC
    WebTranslateIt-Safe is a simple tool to backup databases (MySQL and PostgreSQL) and files.
    Backups can be stored locally or remotely and can be encrypted.
    Remote storage is supported on Amazon S3 or just plain SFTP/SCP.
  DESC
  spec.summary       = 'Backup filesystem and databases (MySQL and PostgreSQL) locally or to a remote server/service (with encryption)'
  spec.homepage      = 'http://github.com/webtranslateit/safe'
  spec.license       = 'MIT'

  spec.files         = Dir['CHANGELOG', 'LICENCE.txt', 'README.markdown', 'lib/**/*', 'bin/**/*']
  spec.executables   = 'webtranslateit-safe'
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-s3'
  spec.add_dependency 'net-scp'
  spec.add_dependency 'net-sftp'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
