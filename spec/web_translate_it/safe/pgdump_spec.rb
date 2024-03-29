describe WebTranslateIt::Safe::Pgdump do

  def def_config
    {
      options: 'OPTS',
      user: 'User',
      password: 'pwd',
      host: 'localhost',
      port: 7777,
      skip_tables: %i[bar baz]
    }
  end

  def pgdump(id = :foo, config = def_config)
    WebTranslateIt::Safe::Pgdump.new(id, WebTranslateIt::Safe::Config::Node.new(nil, config))
  end

  before do
    stub(Time).now.stub!.strftime { 'NOW' }
  end

  after { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :backup do
    before do
      @pg = pgdump
    end

    {
      id: 'foo',
      kind: 'pgdump',
      extension: '.sql',
      filename: 'pgdump-foo.NOW',
      command: "pg_dump OPTS --username='User' --host='localhost' --port='7777' foo"
    }.each do |k, v|
      it "sets #{k} to #{v}" do
        expect(@pg.backup.send(k)).to eq(v)
      end
    end

  end

end
