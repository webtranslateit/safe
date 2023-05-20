require 'spec_helper'

require 'fileutils'
include FileUtils

describe 'tar backup' do
  before(:all) do
    # need both local and instance vars
    # instance variables are used in tests
    # local variables are used in the backup definition (instance vars can't be seen)
    @root = root = 'tmp/archive_backup_example'

    # clean state
    rm_rf @root
    mkdir_p @root

    # create source tree
    @src = src = "#{@root}/src"
    mkdir_p "#{@src}/q/w/e"
    mkdir_p "#{@src}/a/s/d"

    File.open("#{@src}/qwe1", 'w') {|f| f.write('qwe') }
    File.open("#{@src}/q/qwe2", 'w') {|f| f.write('qwe'*2) }
    File.open("#{@src}/q/w/qwe3", 'w') {|f| f.write('qwe'*3) }
    File.open("#{@src}/q/w/e/qwe4", 'w') {|f| f.write('qwe'*4) }

    File.open("#{@src}/asd1", 'w') {|f| f.write('asd') }
    File.open("#{@src}/a/asd2", 'w') {|f| f.write('asd' * 2) }
    File.open("#{@src}/a/s/asd3", 'w') {|f| f.write('asd' * 3) }

    @dst = dst = "#{@root}/backup"
    mkdir_p @dst

    @now = Time.now
    @timestamp = @now.strftime('%y%m%d-%H%M')

    stub(Time).now {@now} # Freeze

    config = WebTranslateIt::Safe.safe do
      local :path => "#{dst}/:kind"
      tar do
        archive :test1 do
          files src
          exclude "#{src}/q/w"
          exclude "#{src}/q/w/e"
        end
      end
    end
    WebTranslateIt::Safe.process config

    @backup = "#{dst}/archive/archive-test1.#{@timestamp}.tar.gz"
  end

  it 'should create backup file' do
    File.exist?(@backup).should be true
  end

  describe 'after extracting' do
    before(:all) do
      # prepare target dir
      @target = "#{@root}/test"
      mkdir_p @target
      system "tar -zxvf #{@backup} -C #{@target}"

      @test = "#{@target}/#{@root}/src"
      puts @test
    end

    it 'should include asd1/2/3' do
      File.exist?("#{@test}/asd1").should be true
      File.exist?("#{@test}/a/asd2").should be true
      File.exist?("#{@test}/a/s/asd3").should be true
    end

    it 'should only include qwe 1 and 2 (no 3)' do
      File.exist?("#{@test}/qwe1").should be true
      File.exist?("#{@test}/q/qwe2").should be true
      File.exist?("#{@test}/q/w/qwe3").should be false
      File.exist?("#{@test}/q/w/e/qwe4").should be false
    end

    it 'should preserve file content' do
      File.read("#{@test}/qwe1").should == 'qwe'
      File.read("#{@test}/q/qwe2").should == 'qweqwe'
      File.read("#{@test}/a/s/asd3").should == 'asdasdasd'
    end
  end

end
