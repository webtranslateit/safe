module WebTranslateIt
  module Safe
    class Pgdump < Source

      def command
        ENV['PGPASSWORD'] = (config['password'] || nil)
        "pg_dump #{postgres_options} #{postgres_username} #{postgres_host} #{postgres_port} #{@id}"
      end

      def extension = '.sql'

      protected

      def postgres_options
        config[:options]
      end

      def postgres_host
        config['host'] && "--host='#{config['host']}'"
      end

      def postgres_port
        config['port'] && "--port='#{config['port']}'"
      end

      def postgres_username
        config['user'] && "--username='#{config['user']}'"
      end

    end
  end
end
