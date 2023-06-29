require 'spec_helper'

describe WebTranslateIt::Safe::Cloudfiles do

  def def_config
    {
      cloudfiles: {
        container: '_container',
        user:      '_user',
        api_key:   '_api_key'
      },
      keep: { cloudfiles: 2 }
    }
  end

  def def_backup(extra = {})
    {
      kind:      '_kind',
      filename:  '/backup/somewhere/_kind-_id.NOW.bar',
      extension: '.bar',
      id:        '_id',
      timestamp: 'NOW'
    }.merge(extra)
  end

  def cloudfiles(config = def_config, backup = def_backup)
    WebTranslateIt::Safe::Cloudfiles.new(
      WebTranslateIt::Safe::Config::Node.new.merge(config),
      WebTranslateIt::Safe::Backup.new(backup)
    )
  end

  describe :cleanup do

    before(:each) do
      @cloudfiles = cloudfiles

      @files = [4,1,3,2].map { |i| "aaaaa#{i}" }

      @container = 'container'

      stub(@container).objects(prefix: '_kind/_id/_kind-_id.') { @files }
      stub(@container).delete_object(anything)

      stub(CloudFiles::Connection).
        new('_user', '_api_key', true, false).stub!.
        container('_container') {@container}
    end

    it 'should check [:keep, :cloudfiles]' do
      @cloudfiles.config[:keep].data['cloudfiles'] = nil
      dont_allow(@cloudfiles.backup).filename
      @cloudfiles.send :cleanup
    end

    it 'should delete extra files' do
      mock(@container).delete_object('aaaaa1')
      mock(@container).delete_object('aaaaa2')
      @cloudfiles.send :cleanup
    end

  end

  describe :active do
    before(:each) do
      @cloudfiles = cloudfiles
    end

    it 'should be true when all params are set' do
      expect(@cloudfiles.active?).to be_truthy
    end

    it 'should be false if container is missing' do
      @cloudfiles.config[:cloudfiles].data['container'] = nil
      expect(@cloudfiles.active?).to be_falsy
    end

    it 'should be false if user is missing' do
      @cloudfiles.config[:cloudfiles].data['user'] = nil
      expect(@cloudfiles.active?).to be_falsy
    end

    it 'should be false if api_key is missing' do
      @cloudfiles.config[:cloudfiles].data['api_key'] = nil
      expect(@cloudfiles.active?).to be_falsy
    end
  end

  describe :path do
    before(:each) do
      @cloudfiles = cloudfiles
    end
    it 'should use cloudfiles/path 1st' do
      @cloudfiles.config[:cloudfiles].data['path'] = 'cloudfiles_path'
      @cloudfiles.config[:local] = {path: 'local_path'}
      @cloudfiles.send(:path).should == 'cloudfiles_path'
    end

    it 'should use local/path 2nd' do
      @cloudfiles.config.merge local: {path: 'local_path'}
      @cloudfiles.send(:path).should == 'local_path'
    end

    it 'should use constant 3rd' do
      @cloudfiles.send(:path).should == '_kind/_id'
    end

  end

  describe :save do
    def add_stubs(*stubs)
      stubs.each do |s|
        case s
        when :connection
          @connection = 'connection'
          stub(CloudFiles::Authentication).new
          stub(CloudFiles::Connection).
            new('_user', '_api_key', true, false) {@connection}
        when :file_size
          stub(@cloudfiles).get_file_size('foo') {123}
        when :create_container
          @container = 'container'
          stub(@container).create_object('_kind/_id/backup/somewhere/_kind-_id.NOW.bar.bar', true) {@object}
          stub(@connection).create_container {@container}
        when :file_open
          stub(File).open('foo')
        when :cloudfiles_store
          @object = 'object'
          stub(@object).write(nil) {true}
        end
      end
    end

    before(:each) do
      @cloudfiles = cloudfiles(def_config, def_backup(path: 'foo'))
      @full_path = '_kind/_id/backup/somewhere/_kind-_id.NOW.bar.bar'
    end

    it 'should fail if no backup.file is set' do
      @cloudfiles.backup.path = nil
      proc {@cloudfiles.send(:save)}.should raise_error(RuntimeError)
    end

    it 'should open local file' do
      add_stubs(:connection, :file_size, :create_container, :cloudfiles_store)
      mock(File).open('foo')
      @cloudfiles.send(:save)
    end

    it "should call write on the cloudfile object with files' descriptor" do
      add_stubs(:connection, :file_size, :create_container, :cloudfiles_store)
      stub(File).open('foo') {'qqq'}
      mock(@object).write('qqq') {true}
      @cloudfiles.send(:save)
    end

    it 'should upload file' do
      add_stubs(:connection, :file_size, :create_container, :file_open, :cloudfiles_store)
      @cloudfiles.send(:save)
    end

    it 'should fail on files bigger then 5G' do
      add_stubs(:connection)
      mock(File).stat('foo').stub!.size {5*1024*1024*1024+1}
      dont_allow(Benchmark).realtime
      @cloudfiles.send(:save)
    end
  end
end
