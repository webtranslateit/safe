require 'spec_helper'

require 'fileutils'
include FileUtils

describe 'tar backup' do
  before(:all) do
    # need both local and instance vars
    # instance variables are used in tests
    # local variables are used in the backup definition (instance vars can't be seen)
    @root = 'tmp/cleanup_example'

    # clean state
    rm_rf @root
    mkdir_p @root

    # create source tree
    @src = src = "#{@root}/src"
    mkdir_p src

    File.write(qwe = "#{@src}/qwe", 'qwe')

    @dst = dst = "#{@root}/backup"
    mkdir_p "#{@dst}/archive"

    @now = Time.now
    @timestamp = @now.strftime('%y%m%d-%H%M')

    stub(Time).now { @now } # Freeze

    cp qwe, "#{dst}/archive/archive-foo.000001.tar.gz"
    cp qwe, "#{dst}/archive/archive-foo.000002.tar.gz"
    cp qwe, "#{dst}/archive/archive-foobar.000001.tar.gz"
    cp qwe, "#{dst}/archive/archive-foobar.000002.tar.gz"

    config = WebTranslateIt::Safe.safe do
      local path: "#{dst}/:kind"
      tar do
        keep local: 1 # only leave the latest
        archive :foo do
          files src
        end
      end
    end
    WebTranslateIt::Safe.process config

    @backup = "#{dst}/archive/archive-foo.#{@timestamp}.tar.gz"
  end

  it 'creates backup file' do
    expect(File.exist?(@backup)).to be true
  end

  it 'removes old backups' do
    expect(Dir["#{@dst}/archive/archive-foo.*"]).to eq([@backup])
  end

  it 'does not remove backups with base having same prefix' do
    expect(Dir["#{@dst}/archive/archive-foobar.*"]).to eq(["#{@dst}/archive/archive-foobar.000001.tar.gz", "#{@dst}/archive/archive-foobar.000002.tar.gz"])
  end

end
