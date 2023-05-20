require 'spec_helper'

describe WebTranslateIt::Safe::Archive do

  def def_config
    {
      options: 'OPTS',
      files: 'apples',
      exclude: 'oranges'
    }
  end

  def archive(id = :foo, config = def_config)
    WebTranslateIt::Safe::Archive.new(id, WebTranslateIt::Safe::Config::Node.new(nil, config))
  end

  after(:each) { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :backup do
    before(:each) do
      @archive = archive
      stub(@archive).timestamp { 'NOW' }
    end

    {
      id: 'foo',
      kind: 'archive',
      extension: '.tar',
      filename: 'archive-foo.NOW',
      command: 'tar -cf - OPTS --exclude=oranges apples'
    }.each do |k, v|
      it "sets #{k} to #{v}" do
        @archive.backup.send(k).should == v
      end
    end
  end

  describe :tar_exclude_files do
    it "returns '' when no excludes" do
      archive(:foo, {}).send(:tar_exclude_files).should == ''
    end

    it 'accepts single exclude as string' do
      archive(:foo, {exclude: 'bar'}).send(:tar_exclude_files).should == '--exclude=bar'
    end

    it 'accepts multiple exclude as array' do
      archive(:foo, {exclude: ['foo', 'bar']}).send(:tar_exclude_files).should == '--exclude=foo --exclude=bar'
    end
  end

  describe :tar_files do
    it 'raises RuntimeError when no files' do
      lambda {
        archive(:foo, {}).send(:tar_files)
      }.should raise_error(RuntimeError, 'missing files for tar')
    end

    it 'accepts single file as string' do
      archive(:foo, {files: 'foo'}).send(:tar_files).should == 'foo'
    end

    it 'accepts multiple files as array' do
      archive(:foo, {files: ['foo', 'bar']}).send(:tar_files).should == 'foo bar'
    end
  end
end
