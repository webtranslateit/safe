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

  after { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :backup do
    before do
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
        expect(@archive.backup.send(k)).to eq(v)
      end
    end
  end

  describe :tar_exclude_files do
    it "returns '' when no excludes" do
      expect(archive(:foo, {}).send(:tar_exclude_files)).to eq('')
    end

    it 'accepts single exclude as string' do
      expect(archive(:foo, {exclude: 'bar'}).send(:tar_exclude_files)).to eq('--exclude=bar')
    end

    it 'accepts multiple exclude as array' do
      expect(archive(:foo, {exclude: %w[foo bar]}).send(:tar_exclude_files)).to eq('--exclude=foo --exclude=bar')
    end
  end

  describe :tar_files do
    it 'raises RuntimeError when no files' do
      expect do
        archive(:foo, {}).send(:tar_files)
      end.to raise_error(RuntimeError, 'missing files for tar')
    end

    it 'accepts single file as string' do
      expect(archive(:foo, {files: 'foo'}).send(:tar_files)).to eq('foo')
    end

    it 'accepts multiple files as array' do
      expect(archive(:foo, {files: %w[foo bar]}).send(:tar_files)).to eq('foo bar')
    end
  end
end
