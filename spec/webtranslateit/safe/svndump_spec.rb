require 'spec_helper'

describe WebTranslateIt::Safe::Svndump do
  def def_config
    {
      options: 'OPTS',
      repo_path: 'bar/baz'
    }
  end

  def svndump(id = :foo, config = def_config)
    WebTranslateIt::Safe::Svndump.new(id, WebTranslateIt::Safe::Config::Node.new(nil, config))
  end

  before do
    stub(Time).now.stub!.strftime {'NOW'}
  end

  after { WebTranslateIt::Safe::TmpFile.cleanup }

  describe :backup do
    before do
      @svn = svndump
    end

    {
      id: 'foo',
      kind: 'svndump',
      extension: '.svn',
      filename: 'svndump-foo.NOW',
      command: 'svnadmin dump OPTS bar/baz'
    }.each do |k, v|
      it "should set #{k} to #{v}" do
        @svn.backup.send(k).should == v
      end
    end

  end
end
