include FileUtils

describe 'tar backup' do
  before(:all) do
    # need both local and instance vars
    # instance variables are used in tests
    # local variables are used in the backup definition (instance vars can't be seen)
    @root = 'tmp/archive_backup_example'

    # clean state
    rm_rf @root
    mkdir_p @root

    # create source tree
    @src = src = "#{@root}/src"
    mkdir_p "#{@src}/q/w/e"
    mkdir_p "#{@src}/a/s/d"

    File.write("#{@src}/qwe1", 'qwe')
    File.write("#{@src}/q/qwe2", 'qwe' * 2)
    File.write("#{@src}/q/w/qwe3", 'qwe' * 3)
    File.write("#{@src}/q/w/e/qwe4", 'qwe' * 4)

    File.write("#{@src}/asd1", 'asd')
    File.write("#{@src}/a/asd2", 'asd' * 2)
    File.write("#{@src}/a/s/asd3", 'asd' * 3)

    @dst = dst = "#{@root}/backup"
    mkdir_p @dst

    @now = Time.now
    @timestamp = @now.strftime('%y%m%d-%H%M')

    stub(Time).now { @now } # Freeze

    config = WebTranslateIt::Safe.safe do
      local path: "#{dst}/:kind"
      tar do
        archive :test1 do
          files src
          exclude "#{src}/q/w"
          exclude "#{src}/q/w/e"
        end
      end
    end
    WebTranslateIt::Safe.process config

    @backup = "#{dst}/archive/archive-test1.#{@timestamp}.tar.gz"
  end

  it 'creates backup file' do
    expect(File.exist?(@backup)).to be true
  end

  describe 'after extracting' do
    before(:all) do
      # prepare target dir
      @target = "#{@root}/test"
      mkdir_p @target
      system "tar -zxvf #{@backup} -C #{@target}"

      @test = "#{@target}/#{@root}/src"
      puts @test
    end

    it 'includes asd1/2/3' do
      expect(File.exist?("#{@test}/asd1")).to be true
      expect(File.exist?("#{@test}/a/asd2")).to be true
      expect(File.exist?("#{@test}/a/s/asd3")).to be true
    end

    it 'onlies include qwe 1 and 2 (no 3)' do
      expect(File.exist?("#{@test}/qwe1")).to be true
      expect(File.exist?("#{@test}/q/qwe2")).to be true
      expect(File.exist?("#{@test}/q/w/qwe3")).to be false
      expect(File.exist?("#{@test}/q/w/e/qwe4")).to be false
    end

    it 'preserves file content' do
      expect(File.read("#{@test}/qwe1")).to eq('qwe')
      expect(File.read("#{@test}/q/qwe2")).to eq('qweqwe')
      expect(File.read("#{@test}/a/s/asd3")).to eq('asdasdasd')
    end
  end

end
