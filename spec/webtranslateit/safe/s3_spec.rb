require 'spec_helper'

describe WebTranslateIt::Safe::S3 do

  def def_config
    {
      s3: {
        bucket: '_bucket',
        key: '_key',
        secret: '_secret'
      },
      keep: {
        s3: 2
      }
    }
  end

  def def_backup(extra = {})
    {
      kind: '_kind',
      filename: '/backup/somewhere/_kind-_id.NOW.bar',
      extension: '.bar',
      id: '_id',
      timestamp: 'NOW'
    }.merge(extra)
  end

  def s3(config = def_config, backup = def_backup)
    WebTranslateIt::Safe::S3.new(
      WebTranslateIt::Safe::Config::Node.new.merge(config),
      WebTranslateIt::Safe::Backup.new(backup)
    )
  end

  describe :cleanup do

    before do
      @s3 = s3

      @files = [4,1,3,2].map do |i|
        stub(o = {}).key {"aaaaa#{i}"}
        o
      end

      stub(AWS::S3::Bucket).objects('_bucket', prefix: '_kind/_id/_kind-_id.', max_keys: 4) {@files}
      stub(AWS::S3::Bucket).objects('_bucket', prefix: anything).stub![0].stub!.delete
    end

    it 'checks [:keep, :s3]' do
      @s3.config[:keep].data['s3'] = nil
      dont_allow(@s3.backup).filename
      @s3.send :cleanup
    end

    it 'deletes extra files' do
      mock(AWS::S3::Bucket).objects('_bucket', prefix: 'aaaaa1').mock![0].mock!.delete
      mock(AWS::S3::Bucket).objects('_bucket', prefix: 'aaaaa2').mock![0].mock!.delete
      @s3.send :cleanup
    end

  end

  describe :active do
    before do
      @s3 = s3
    end

    it 'is true when all params are set' do
      expect(@s3.active?).to be_truthy
    end

    it 'is false if bucket is missing' do
      @s3.config[:s3].data['bucket'] = nil
      expect(@s3.active?).to be_falsy
    end

    it 'is false if key is missing' do
      @s3.config[:s3].data['key'] = nil
      expect(@s3.active?).to be_falsy
    end

    it 'is false if secret is missing' do
      @s3.config[:s3].data['secret'] = nil
      expect(@s3.active?).to be_falsy
    end
  end

  describe :path do
    before do
      @s3 = s3
    end
    it 'uses s3/path 1st' do
      @s3.config[:s3].data['path'] = 's3_path'
      @s3.config[:local] = {path: 'local_path'}
      @s3.send(:path).should == 's3_path'
    end

    it 'uses local/path 2nd' do
      @s3.config.merge local: {path: 'local_path'}
      @s3.send(:path).should == 'local_path'
    end

    it 'uses constant 3rd' do
      @s3.send(:path).should == '_kind/_id'
    end

  end

  describe :save do
    def add_stubs(*stubs)
      stubs.each do |s|
        case s
        when :connection
          stub(AWS::S3::Base).establish_connection!(access_key_id: '_key', secret_access_key: '_secret', use_ssl: true)
        when :stat
          stub(File).stat('foo').stub!.size {123}
        when :create_bucket
          stub(AWS::S3::Bucket).find('_bucket') { raise_error AWS::S3::NoSuchBucket }
          stub(AWS::S3::Bucket).create
        when :file_open
          stub(File).open('foo') {|f, block| block.call(:opened_file)}
        when :s3_store
          stub(AWS::S3::S3Object).store(@full_path, :opened_file, '_bucket')
        end
      end
    end

    before do
      @s3 = s3(def_config, def_backup(path: 'foo'))
      @full_path = '_kind/_id/backup/somewhere/_kind-_id.NOW.bar.bar'
    end

    it 'fails if no backup.file is set' do
      @s3.backup.path = nil
      proc {@s3.send(:save)}.should raise_error(RuntimeError)
    end

    it 'establishes s3 connection' do
      mock(AWS::S3::Base).establish_connection!(access_key_id: '_key', secret_access_key: '_secret', use_ssl: true)
      add_stubs(:stat, :create_bucket, :file_open, :s3_store)
      @s3.send(:save)
    end

    it 'opens local file' do
      add_stubs(:connection, :stat, :create_bucket)
      mock(File).open('foo')
      @s3.send(:save)
    end

    it 'uploads file' do
      add_stubs(:connection, :stat, :create_bucket, :file_open)
      mock(AWS::S3::S3Object).store(@full_path, :opened_file, '_bucket')
      @s3.send(:save)
    end

    it 'fails on files bigger then 5G' do
      add_stubs(:connection)
      mock(File).stat('foo').stub!.size {5*1024*1024*1024+1}
      dont_allow(Benchmark).realtime
      @s3.send(:save)
    end

    it 'does not create a bucket that already exists' do
      add_stubs(:connection, :stat, :file_open, :s3_store)
      stub(AWS::S3::Bucket).find('_bucket') { true }
      dont_allow(AWS::S3::Bucket).create
      @s3.send(:save)
    end
  end
end
