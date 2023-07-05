require 'aws/s3'
require 'cloudfiles'
require 'net/sftp'
require 'net/scp'
require 'tmpdir'
require 'fileutils'
require 'benchmark'

require 'tempfile'

require 'web_translate_it/safe/tmp_file'

require 'web_translate_it/safe/config/node'
require 'web_translate_it/safe/config/builder'

require 'web_translate_it/safe/stream'

require 'web_translate_it/safe/backup'

require 'web_translate_it/safe/source'
require 'web_translate_it/safe/mysqldump'
require 'web_translate_it/safe/pgdump'
require 'web_translate_it/safe/archive'
require 'web_translate_it/safe/mongodump'

require 'web_translate_it/safe/pipe'
require 'web_translate_it/safe/gpg'
require 'web_translate_it/safe/gzip'

require 'web_translate_it/safe/sink'
require 'web_translate_it/safe/local'
require 'web_translate_it/safe/s3'
require 'web_translate_it/safe/cloudfiles'
require 'web_translate_it/safe/scp'
require 'web_translate_it/safe/sftp'
require 'web_translate_it/safe/ftp'

module WebTranslateIt

  module Safe

    ROOT = File.join(File.dirname(__FILE__), '..', '..')

    def safe(&)
      Config::Node.new(&)
    end

    def process(config)
      [[Mysqldump, %i[mysqldump databases]],
       [Pgdump,    %i[pgdump databases]],
       [Mongodump, %i[mongodump databases]],
       [Archive,   %i[tar archives]]].each do |klass, path|
        next unless collection = config[*path]

        collection.each do |name, c|
          klass.new(name, c).backup.run(c, :gpg, :gzip, :local, :s3, :cloudfiles, :scp, :sftp, :ftp)
        end
      end

      WebTranslateIt::Safe::TmpFile.cleanup
    end
    module_function :safe
    module_function :process

  end

end
