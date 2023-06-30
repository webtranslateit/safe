describe WebTranslateIt::Safe::Config do
  it 'parses example config' do
    config = WebTranslateIt::Safe::Config::Node.new do

      dry_run false
      local_only true
      verbose true

      local do
        path 'path'
      end

      s3 do
        key 's3 key'
        secret 'secret'
        bucket 'bucket'
        path 'path1'
      end

      sftp do
        user 'sftp user'
        password 'sftp password'
        host 'sftp host'
      end

      gpg do
        password 'astrails'
        key 'gpg-key'
      end

      keep do
        s3 20
        local 4
      end

      mysqldump do
        options '-ceKq --single-transaction --create-options'

        user 'astrails'
        password ''
        host 'localhost'
        port 3306
        socket '/var/run/mysqld/mysqld.sock'

        database :blog

        database :production do
          keep local: 3

          gpg do
            password 'custom-production-pass'
          end

          skip_tables %i[logger_exceptions request_logs]
        end

      end

      pgdump do
        options '-i -x -O'

        user 'astrails'
        password ''
        host 'localhost'
        port 5432

        database :blog

        database :production do
          keep local: 3

          skip_tables %i[logger_exceptions request_logs]
        end

      end

      svndump do
        repo :my_repo do
          repo_path '/home/svn/my_repo'
        end
      end

      tar do
        archive 'git-repositories' do
          files '/home/git/repositories'
        end

        archive 'etc-files' do
          files '/etc'
          exclude '/etc/puppet/other'
        end

        archive 'dot-configs' do
          files '/home/*/.[^.]*'
        end

        archive 'blog' do
          files '/var/www/blog.astrails.com/'
          exclude ['/var/www/blog.astrails.com/log', '/var/www/blog.astrails.com/tmp']
        end

        archive :misc do
          files ['/backup/*.rb']
        end
      end

      mongodump do
        host 'host'
        database 'database'
        user 'user'
        password 'password'
      end
    end

    expected = {
      'dry_run' => false,
      'local_only' => true,
      'verbose' => true,

      'local' => {'path' => 'path'},

      's3' => {
        'key' => 's3 key',
        'secret' => 'secret',
        'bucket' => 'bucket',
        'path' => 'path1'
      },

      'sftp' => {
        'user' => 'sftp user',
        'password' => 'sftp password',
        'host' => 'sftp host'
      },

      'gpg' => {'password' => 'astrails', 'key' => 'gpg-key'},

      'keep' => {'s3' => 20, 'local' => 4},

      'mysqldump' => {
        'options' => '-ceKq --single-transaction --create-options',
        'user' => 'astrails',
        'password' => '',
        'host' => 'localhost',
        'port' => 3306,
        'socket' => '/var/run/mysqld/mysqld.sock',

        'databases' => {
          'blog' => {},
          'production' => {
            'keep' => {'local' => 3},
            'gpg' => {'password' => 'custom-production-pass'},
            'skip_tables' => %w[logger_exceptions request_logs]
          }
        }
      },

      'pgdump' => {
        'options' => '-i -x -O',
        'user' => 'astrails',
        'password' => '',
        'host' => 'localhost',
        'port' => 5432,

        'databases' => {
          'blog' => {},
          'production' => {
            'keep' => {'local' => 3},
            'skip_tables' => %w[logger_exceptions request_logs]
          }
        }
      },

      'svndump' => {
        'repos' => {
          'my_repo' => {
            'repo_path' => '/home/svn/my_repo'
          }
        }
      },

      'tar' => {
        'archives' => {
          'git-repositories' => {'files' => ['/home/git/repositories']},
          'etc-files' => {'files' => ['/etc'], 'exclude' => ['/etc/puppet/other']},
          'dot-configs' => {'files' => ['/home/*/.[^.]*']},
          'blog' => {
            'files' => ['/var/www/blog.astrails.com/'],
            'exclude' => ['/var/www/blog.astrails.com/log', '/var/www/blog.astrails.com/tmp']
          },
          'misc' => {'files' => ['/backup/*.rb']}
        }
      },

      'mongodump' => {
        'host' => 'host',
        'databases' => {
          'database' => {}
        },
        'user' => 'user',
        'password' => 'password'
      }
    }

    expect(config.to_hash).to eq(expected)
  end

  it 'makes an array from multivalues' do
    config = WebTranslateIt::Safe::Config::Node.new do
      skip_tables 'a'
      skip_tables 'b'
      files '/foo'
      files '/bar'
      exclude '/foo/bar'
      exclude '/foo/bar/baz'
    end

    expected = {
      'skip_tables' => %w[a b],
      'files' => ['/foo', '/bar'],
      'exclude' => ['/foo/bar', '/foo/bar/baz']
    }

    expect(config.to_hash).to eq(expected)
  end

  it 'raises error on key duplication' do
    expect do
      WebTranslateIt::Safe::Config::Node.new do
        path 'foo'
        path 'bar'
      end
    end.to raise_error(ArgumentError, "duplicate value for 'path'")
  end

  it 'accepts hash as data' do
    expect(WebTranslateIt::Safe::Config::Node.new do
      tar do
        archive 'blog', files: 'foo', exclude: %w[aaa bbb]
      end
    end.to_hash).to eq({
                         'tar' => {
                           'archives' => {
                             'blog' => {
                               'files' => ['foo'],
                               'exclude' => %w[aaa bbb]
                             }
                           }
                         }
                       })
  end

  it 'accepts hash as data and a block' do
    expect(WebTranslateIt::Safe::Config::Node.new do
      tar do
        archive 'blog', files: 'foo' do
          exclude %w[aaa bbb]
        end
      end
    end.to_hash).to eq({
                         'tar' => {
                           'archives' => {
                             'blog' => {
                               'files' => ['foo'],
                               'exclude' => %w[aaa bbb]
                             }
                           }
                         }
                       })
  end

  it 'accepts multiple levels of data hash' do
    config = WebTranslateIt::Safe::Config::Node.new nil, tar: {
      s3: {bucket: '_bucket', key: '_key', secret: '_secret'},
      keep: {s3: 2}
    }

    expect(config.to_hash).to eq({
                                   'tar' => {
                                     's3' => {'bucket' => '_bucket', 'key' => '_key', 'secret' => '_secret'},
                                     'keep' => {'s3' => 2}
                                   }
                                 })
  end

  it 'sets multi value as array' do
    config = WebTranslateIt::Safe::Config::Node.new do
      tar do
        archive 'foo' do
          files 'bar'
        end
      end
    end

    expect(config.to_hash).to eq({
                                   'tar' => {
                                     'archives' => {
                                       'foo' => {
                                         'files' => ['bar']
                                       }
                                     }
                                   }
                                 })
  end

end
