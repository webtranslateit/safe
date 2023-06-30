module WebTranslateIt

  module Safe

    class Sftp < Sink

      MAX_RETRIES = 5

      protected

      def active?
        host && user
      end

      def path
        @path ||= expand(config[:sftp, :path] || config[:local, :path] || ':kind/:id')
      end

      def save # rubocop:todo Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        raise 'pipe-streaming not supported for SFTP.' unless @backup.path

        puts "Uploading #{host}:#{full_path} via SFTP" if verbose? || dry_run?

        return if dry_run? || local_only?

        retries = 0
        opts = {}
        opts[:password] = password if password
        opts[:port] = port if port
        Net::SFTP.start(host, user, opts) do |sftp|
          puts "Sending #{@backup.path} to #{full_path}" if verbose?
          begin
            sftp.upload! @backup.path, full_path
          rescue IO::TimeoutError
            puts 'Upload timed out, retrying'
            retries += 1
            if retries >= MAX_RETRIES
              puts "Tried #{retries} times. Giving up."
            else
              retry unless retries >= MAX_RETRIES
            end
          rescue Net::SFTP::StatusException
            puts "Ensuring remote path (#{path}) exists" if verbose?
            # mkdir -p
            folders = path.split('/')
            folders.each_index do |i|
              folder = folders[0..i].join('/')
              puts "Creating #{folder} on remote" if verbose?
              begin
                sftp.mkdir!(folder)
              rescue StandardError
                Net::SFTP::StatusException
              end
            end
            retry
          end
        end
        puts '...done' if verbose?
      end

      # rubocop:todo Metrics/PerceivedComplexity
      def cleanup # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        return if local_only? || dry_run?

        return unless keep = config[:keep, :sftp]

        puts "listing files: #{host}:#{base}*" if verbose?
        opts = {}
        opts[:password] = password if password
        opts[:port] = port if port
        Net::SFTP.start(host, user, opts) do |sftp|
          files = sftp.dir.glob(path, File.basename("#{base}*"))

          puts files.collect(&:name) if verbose?

          files = files.collect(&:name).sort

          cleanup_with_limit(files, keep) do |f|
            file = File.join(path, f)
            puts "removing sftp file #{host}:#{file}" if dry_run? || verbose?
            sftp.remove!(file) unless dry_run? || local_only?
          end
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def host
        config[:sftp, :host]
      end

      def user
        config[:sftp, :user]
      end

      def password
        config[:sftp, :password]
      end

      def port
        config[:sftp, :port]
      end

    end

  end

end
