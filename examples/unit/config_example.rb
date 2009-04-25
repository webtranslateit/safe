require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Config do
  it "pgdump" do
    config = Astrails::Safe::Config::Node.new do
      local do
        path "path"
      end

      pgdump do
        # `pg_dump -U "#{abcs[RAILS_ENV]["username"]}" -i -x -O  #{abcs[RAILS_ENV]["database"]} -f db/#{filename}`
        options "-i -x -O"

        user "astrails"
        password ""
        host "localhost"
        port 5432

        database :blog

        database :production do
          keep :local => 3

          skip_tables [:logger_exceptions, :request_logs]
        end

      end
    end

    expected = {
      "local" => {"path" => "path"},

      "pgdump" => {
        "options" => "-i -x -O",
        "user" => "astrails",
        "password" => "",
        "host" => "localhost",
        "port" => 5432,

        "databases" => {
          "blog" => {},
          "production" => {
           "keep" => {"local" => 3},
            "skip_tables" => ["logger_exceptions", "request_logs"],
          },
        },
      }
    }

    config.to_hash.should == expected
  end

  it "foo" do
    config = Astrails::Safe::Config::Node.new do
      local do
        path "path"
      end

      s3 do
        key "s3 key"
        secret "secret"
        bucket "bucket"
        path "path1"
      end

      gpg do
        key "gpg-key"
        password "astrails"
      end

      keep do
        local 4
        s3 20
      end

      mysqldump do
        options "-ceKq --single-transaction --create-options"

        user "astrails"
        password ""
        host "localhost"
        port 3306
        socket "/var/run/mysqld/mysqld.sock"

        database :blog

        database :production do
          keep :local => 3

          gpg do
            password "custom-production-pass"
          end

          skip_tables [:logger_exceptions, :request_logs]
        end

      end


      tar do
        archive "git-repositories" do
          files "/home/git/repositories"
        end

        archive "etc-files" do
          files "/etc"
          exclude "/etc/puppet/other"
        end

        archive "dot-configs" do
          files "/home/*/.[^.]*"
        end

        archive "blog" do
          files "/var/www/blog.astrails.com/"
          exclude ["/var/www/blog.astrails.com/log", "/var/www/blog.astrails.com/tmp"]
        end

        archive :misc do
          files [ "/backup/*.rb" ]
        end
      end

    end

    expected = {
      "local" => {"path" => "path"},

      "s3" => {
        "key" => "s3 key",
        "secret" => "secret",
        "bucket" => "bucket",
        "path" => "path1",
      },

      "gpg" => {"password" => "astrails", "key" => "gpg-key"},

      "keep" => {"s3" => 20, "local" => 4},

      "mysqldump" => {
        "options" => "-ceKq --single-transaction --create-options",
        "user" => "astrails",
        "password" => "",
        "host" => "localhost",
        "port" => 3306,
        "socket" => "/var/run/mysqld/mysqld.sock",

        "databases" => {
          "blog" => {},
          "production" => {
           "keep" => {"local" => 3},
           "gpg" => {"password" => "custom-production-pass"},
            "skip_tables" => ["logger_exceptions", "request_logs"],
          },
        },
      },
      "tar" => {
        "archives" => {
          "git-repositories" => {"files" => "/home/git/repositories"},
          "etc-files" => {"files" => "/etc", "exclude" => "/etc/puppet/other"},
          "dot-configs" => {"files" => "/home/*/.[^.]*"},
          "blog" => {
            "files" => "/var/www/blog.astrails.com/",
            "exclude" => ["/var/www/blog.astrails.com/log", "/var/www/blog.astrails.com/tmp"],
          },
          "misc" => { "files" => ["/backup/*.rb"] },
        },
      },
    }

    config.to_hash.should == expected

  end
end

