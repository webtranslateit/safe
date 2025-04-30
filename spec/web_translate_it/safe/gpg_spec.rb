describe WebTranslateIt::Safe::Gpg do
  def def_backup
    {
      compressed: false,
      command: 'command',
      extension: '.foo',
      filename: 'qweqwe'
    }
  end

  def gpg(config = {}, backup = def_backup)
    WebTranslateIt::Safe::Gpg.new(
      WebTranslateIt::Safe::Config::Node.new(nil, config),
      WebTranslateIt::Safe::Backup.new(backup)
    )
  end

  after { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :process do

    before do
      @gpg = gpg
      stub(@gpg).gpg_password_file { 'pwd-file' }
      stub(@gpg).pipe { '|gpg -BLAH' }
    end

    describe 'when active' do
      before do
        stub(@gpg).active? { true }
      end

      it 'adds .gpg extension' do
        mock(@gpg.backup.extension) << '.gpg'
        @gpg.process
      end

      it 'adds command pipe' do
        mock(@gpg.backup.command) << /\|gpg -BLAH/
        @gpg.process
      end

      it 'sets compressed' do
        mock(@gpg.backup).compressed = true
        @gpg.process
      end
    end

    describe 'when inactive' do
      before do
        stub(@gpg).active? { false }
      end

      it 'does not touch extension' do
        dont_allow(@gpg.backup.extension) << anything
        @gpg.process
      end

      it 'does not touch command' do
        dont_allow(@gpg.backup.command) << anything
        @gpg.process
      end

      it 'does not touch compressed' do
        dont_allow(@gpg.backup).compressed = anything
        @gpg.process
      end
    end
  end

  describe :active? do

    describe 'with key' do
      it 'is true' do
        expect(gpg(gpg: {key: :foo}).active?).to be_truthy
      end
    end

    describe 'with password' do
      it 'is true' do
        expect(gpg(gpg: {password: :foo}).active?).to be_truthy
      end
    end

    describe 'without key & password' do
      it 'is false' do
        expect(gpg.active?).to be_falsy
      end
    end

    describe 'with key & password' do
      it 'raises RuntimeError' do
        expect do
          gpg(gpg: {key: 'foo', password: 'bar'}).send :active?
        end.to raise_error(RuntimeError, "can't use both gpg password and pubkey")
      end
    end
  end

  describe :pipe do

    describe 'with key' do
      def kgpg(extra = {})
        gpg({gpg: {key: 'foo', options: 'GPG-OPT'}.merge(extra), options: 'OPT'})
      end

      it 'does not call gpg_password_file' do
        g = kgpg
        dont_allow(g).gpg_password_file(anything)
        g.send(:pipe)
      end

      it "uses '-r' and :options" do
        expect(kgpg.send(:pipe)).to eq('|gpg GPG-OPT -e -r foo')
      end

      it "uses the 'command' options" do
        expect(kgpg(command: 'other-gpg').send(:pipe)).to eq('|other-gpg GPG-OPT -e -r foo')
      end
    end

    describe 'with password' do
      def pgpg(extra = {})
        gpg({gpg: {password: 'bar', options: 'GPG-OPT'}.merge(extra), options: 'OPT'}).tap do |g|
          stub(g).gpg_password_file(anything) { 'pass-file' }
        end
      end

      it "uses '--passphrase-file' and :options" do
        expect(pgpg.send(:pipe)).to eq('|gpg GPG-OPT -c --passphrase-file pass-file')
      end

      it "uses the 'command' options" do
        expect(pgpg(command: 'other-gpg').send(:pipe)).to eq('|other-gpg GPG-OPT -c --passphrase-file pass-file')
      end
    end
  end

  describe :gpg_password_file do
    it 'creates password file' do
      file = gpg.send(:gpg_password_file, 'foo')
      expect(File.exist?(file)).to be true
      expect(File.read(file)).to eq('foo')
    end
  end
end
