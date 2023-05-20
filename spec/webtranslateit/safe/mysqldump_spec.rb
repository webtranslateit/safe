require 'spec_helper'

describe WebTranslateIt::Safe::Mysqldump do

  def def_config(extra = {})
    {
      options: 'OPTS',
      user: 'User',
      password: 'pwd',
      host: 'localhost',
      port: 7777,
      socket: 'socket',
      skip_tables: [:bar, :baz]
    }.merge(extra)
  end

  def mysqldump(id = :foo, config = def_config)
    WebTranslateIt::Safe::Mysqldump.new(id, WebTranslateIt::Safe::Config::Node.new(nil, config))
  end

  before(:each) do
    stub(Time).now.stub!.strftime { 'NOW' }
  end

  after(:each) { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :backup do
    before(:each) do
      @mysql = mysqldump
      stub(@mysql).mysql_password_file { '/tmp/pwd' }
    end

    {
      id: 'foo',
      kind: 'mysqldump',
      extension: '.sql',
      filename: 'mysqldump-foo.NOW',
      command: 'mysqldump --defaults-extra-file=/tmp/pwd OPTS --ignore-table=foo.bar --ignore-table=foo.baz foo'
    }.each do |k, v|
      it "sets #{k} to #{v}" do
        @mysql.backup.send(k).should == v
      end
    end

  end

  describe :mysql_skip_tables do
    it 'returns nil if no skip_tables' do
      config = def_config.dup
      config.delete(:skip_tables)
      m = mysqldump(:foo, WebTranslateIt::Safe::Config::Node.new(nil, config))
      stub(m).timestamp { 'NOW' }
      m.send(:mysql_skip_tables).should be_nil
      m.backup.command.should_not match(/ignore-table/)
    end

    it "returns '' if skip_tables empty" do
      config = def_config.dup
      config[:skip_tables] = []
      m = mysqldump(:foo, WebTranslateIt::Safe::Config::Node.new(nil, config))
      stub(m).timestamp { 'NOW' }
      m.send(:mysql_skip_tables).should
      m.backup.command.should_not match(/ignore-table/)
    end

  end

  describe :mysql_password_file do
    it 'creates passwords file with quoted values' do
      m = mysqldump(:foo, def_config(password: '#qwe"asd\'zxc'))
      file = m.send(:mysql_password_file)
      File.exist?(file).should
      File.read(file).should == <<~PWD
        [mysqldump]
        user = "User"
        password = "#qwe\\"asd'zxc"
        socket = "socket"
        host = "localhost"
        port = 7777
      PWD
    end
  end
end
