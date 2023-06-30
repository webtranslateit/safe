require 'spec_helper'

describe WebTranslateIt::Safe::Gzip do

  def def_backup
    {
      compressed: false,
      command: 'command',
      extension: '.foo',
      filename: 'qweqwe'
    }
  end

  after { WebTranslateIt::Safe::TmpFile.cleanup }

  def gzip(config = {}, backup = def_backup)
    WebTranslateIt::Safe::Gzip.new(
      @config = WebTranslateIt::Safe::Config::Node.new(nil, config),
      @backup = WebTranslateIt::Safe::Backup.new(backup)
    )
  end

  describe :preocess do

    describe 'when not yet compressed' do
      before { @gzip = gzip }

      it 'adds .gz extension' do
        mock(@backup.extension) << '.gz'
        @gzip.process
      end

      it 'adds |gzip pipe' do
        mock(@backup.command) << '|gzip'
        @gzip.process
      end

      it 'sets compressed' do
        mock(@backup).compressed = true
        @gzip.process
      end
    end

    describe 'when already compressed' do

      before { @gzip = gzip({}, extension: '.foo', command: 'foobar', compressed: true) }

      it 'does not touch extension' do
        @gzip.process
        expect(@backup.extension).to eq('.foo')
      end

      it 'does not touch command' do
        @gzip.process
        expect(@backup.command).to eq('foobar')
      end

      it 'does not touch compressed' do
        @gzip.process
        expect(@backup.compressed).to be(true)
      end
    end
  end
end
