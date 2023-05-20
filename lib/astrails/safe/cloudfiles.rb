module Astrails
  module Safe
    class Cloudfiles < Sink
      MAX_CLOUDFILES_FILE_SIZE = 5368709120

      def active?
        container && user && api_key
      end

      protected

      def path
        @path ||= expand(config[:cloudfiles, :path] || config[:local, :path] || ':kind/:id')
      end

      # UGLY: we need this function for the reason that
      # we can't double mock on ruby 1.9.2, duh!
      # so we created this func to mock it all together
      def get_file_size(path)
        File.stat(path).size
      end

      def save
        raise RuntimeError, 'pipe-streaming not supported for S3.' unless @backup.path

        # needed in cleanup even on dry run
        cf = CloudFiles::Connection.new(user, api_key, true, service_net) unless local_only?
        puts "Uploading #{container}:#{full_path} from #{@backup.path}" if verbose? || dry_run?
        unless dry_run? || local_only?
          if get_file_size(@backup.path) > MAX_CLOUDFILES_FILE_SIZE
            STDERR.puts "ERROR: File size exceeds maximum allowed for upload to Cloud Files (#{MAX_CLOUDFILES_FILE_SIZE}): #{@backup.path}"
            return
          end
          benchmark = Benchmark.realtime do
            cf_container = cf.create_container(container)
            o = cf_container.create_object(full_path,true)
            o.write(File.open(@backup.path))
          end
          puts '...done' if verbose?
          puts('Upload took ' + sprintf('%.2f', benchmark) + ' second(s).') if verbose?
        end
      end

      def cleanup
        return if local_only?

        return unless keep = config[:keep, :cloudfiles]

        puts "listing files: #{container}:#{base}*" if verbose?
        cf = CloudFiles::Connection.new(user, api_key, true, service_net) unless local_only?
        cf_container = cf.container(container)
        files = cf_container.objects(:prefix => base).sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing Cloud File #{container}:#{f}" if dry_run? || verbose?
          cf_container.delete_object(f) unless dry_run? || local_only?
        end
      end

      def container
        config[:cloudfiles, :container]
      end

      def user
        config[:cloudfiles, :user]
      end

      def api_key
        config[:cloudfiles, :api_key]
      end

      def service_net
        config[:cloudfiles, :service_net] || false
      end
    end
  end
end
