describe WebTranslateIt::Safe::Mongodump do
  def def_config
    {
      host: 'prod.example.com',
      user: 'testuser',
      password: 'p4ssw0rd'
    }
  end

  def mongodump(id = :foo, config = def_config)
    WebTranslateIt::Safe::Mongodump.new(id, WebTranslateIt::Safe::Config::Node.new(nil, config))
  end

  before do
    stub(Time).now.stub!.strftime { 'NOW' }
    @output_folder = File.join(WebTranslateIt::Safe::TmpFile.tmproot, 'mongodump')
  end

  after { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :backup do
    before do
      @mongo = mongodump
    end

    {
      id: 'foo',
      kind: 'mongodump',
      extension: '.tar',
      filename: 'mongodump-foo.NOW'
    }.each do |k, v|
      it "sets #{k} to #{v}" do
        expect(@mongo.backup.send(k)).to eq(v)
      end
    end

    it 'sets the command' do
      expect(@mongo.backup.send(:command)).to eq("mongodump -q \"{xxxx : { \\$ne : 0 } }\" --db foo --host prod.example.com -u testuser -p p4ssw0rd --out #{@output_folder} && cd #{@output_folder} && tar cf - .")
    end

    {
      host: '--host ',
      user: '-u ',
      password: '-p '
    }.each do |key, v|
      it "does not add #{key} to command if it is not present" do
        @mongo = mongodump(:foo, def_config.reject! { |k, _v| k == key })
        expect(@mongo.backup.send(:command)).not_to match(/#{v}/)
      end
    end
  end
end
