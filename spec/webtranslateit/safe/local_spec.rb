require 'spec_helper'

describe WebTranslateIt::Safe::Local do
  def def_config
    {
      local: {
        path: '/:kind~:id~:timestamp'
      },
      keep: {
        local: 2
      }
    }
  end

  def def_backup
    {
      kind: 'mysqldump',
      id: 'blog',
      timestamp: 'NoW',
      compressed: true,
      command: 'command',
      extension: '.foo.gz',
      filename: 'qweqwe'
    }
  end

  def local(config = def_config, backup = def_backup)
    WebTranslateIt::Safe::Local.new(
      @config = WebTranslateIt::Safe::Config::Node.new(nil, config),
      @backup = WebTranslateIt::Safe::Backup.new(backup)
    )
  end

  describe :active? do
    it 'is true' do
      expect(local.active?).to be_truthy
    end
  end

  describe :path do
    it 'raises RuntimeError when no path' do
      lambda {
        local({}).send :path
      }.should raise_error(RuntimeError, 'missing :local/:path')
    end

    it 'uses local/path' do
      local.send(:path).should == '/mysqldump~blog~NoW'
    end
  end

  describe :save do
    before do
      @local = local
      stub(@local).system
      stub(@local).full_path { 'file-path' }
      stub(FileUtils).mkdir_p
    end

    it 'calls system to save the file' do
      mock(@local).system('command>file-path')
      @local.send(:save)
    end

    it 'creates directory' do
      mock(FileUtils).mkdir_p('/mysqldump~blog~NoW')
      @local.send(:save)
    end

    it 'sets backup.path' do
      mock(@backup).path = 'file-path'
      @local.send(:save)
    end

    describe 'dry run' do
      before { @local.config[:dry_run] = true }

      it 'should not create directory'
      it 'should not call system'
      it 'sets backup.path' do
        mock(@backup).path = 'file-path'
        @local.send(:save)
      end
    end
  end

  describe :cleanup do
    before do
      @files = [4, 1, 3, 2].map { |i| "/mysqldump~blog~NoW/qweqwe.#{i}" }
      stub(File).file?(anything) { true }
      stub(File).size(anything) { 1 }
      stub(File).unlink
    end

    it 'checks [:keep, :local]' do
      @local = local(def_config.merge(keep: {}))
      dont_allow(Dir).[]
      @local.send :cleanup
    end

    it 'deletes extra files' do
      @local = local
      mock(Dir).[]('/mysqldump~blog~NoW/qweqwe.*') { @files }
      mock(File).unlink('/mysqldump~blog~NoW/qweqwe.1')
      mock(File).unlink('/mysqldump~blog~NoW/qweqwe.2')
      @local.send :cleanup
    end
  end
end
