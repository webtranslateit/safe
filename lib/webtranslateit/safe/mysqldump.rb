module WebTranslateIt

  module Safe

    class Mysqldump < Source

      def command
        "mysqldump --defaults-extra-file=#{mysql_password_file} #{config[:options]} #{mysql_skip_tables} #{@id}"
      end

      def extension = '.sql'

      protected

      def mysql_password_file
        WebTranslateIt::Safe::TmpFile.create('mysqldump') do |file|
          file.puts '[mysqldump]'
          %w[user password socket host port].each do |k|
            v = config[k]
            # values are quoted if needed
            file.puts "#{k} = #{v.inspect}" if v
          end
        end
      end

      def mysql_skip_tables
        return unless (skip_tables = config[:skip_tables])

        [*skip_tables].map { |t| "--ignore-table=#{@id}.#{t}" }.join(' ')
      end

    end

  end

end
