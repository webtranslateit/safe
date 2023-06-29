require 'aws/s3'
require 'cloudfiles'
require 'net/sftp'
# require 'net/ftp'
require 'fileutils'
require 'benchmark'

require 'tempfile'
require 'extensions/mktmpdir'

require 'webtranslateit/safe/tmp_file'

require 'webtranslateit/safe/config/node'
require 'webtranslateit/safe/config/builder'

require 'webtranslateit/safe/stream'

require 'webtranslateit/safe/backup'

require 'webtranslateit/safe/source'
require 'webtranslateit/safe/mysqldump'
require 'webtranslateit/safe/pgdump'
require 'webtranslateit/safe/archive'
require 'webtranslateit/safe/svndump'
require 'webtranslateit/safe/mongodump'

require 'webtranslateit/safe/pipe'
require 'webtranslateit/safe/gpg'
require 'webtranslateit/safe/gzip'

require 'webtranslateit/safe/sink'
require 'webtranslateit/safe/local'
require 'webtranslateit/safe/s3'
require 'webtranslateit/safe/cloudfiles'
require 'webtranslateit/safe/sftp'
require 'webtranslateit/safe/ftp'

module WebTranslateIt
  module Safe
    ROOT = File.join(File.dirname(__FILE__), '..', '..')

    def safe(&block)
      Config::Node.new(&block)
    end

    def process(config)

      [[Mysqldump, %i[mysqldump databases]],
       [Pgdump,    %i[pgdump databases]],
       [Mongodump, %i[mongodump databases]],
       [Archive,   %i[tar archives]],
       [Svndump,   %i[svndump repos]]
      ].each do |klass, path|
        next unless collection = config[*path]

        collection.each do |name, c|
          klass.new(name, c).backup.run(c, :gpg, :gzip, :local, :s3, :cloudfiles, :sftp, :ftp)
        end
      end

      WebTranslateIt::Safe::TmpFile.cleanup
    end
    module_function :safe
    module_function :process
  end
end
