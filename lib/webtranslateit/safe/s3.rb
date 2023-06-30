module WebTranslateIt

  module Safe

    class S3 < Sink

      MAX_S3_FILE_SIZE = 5_368_709_120

      def initialize(config, backup)
        super(config, backup)
        @connection = Aws::S3::Resource.new(access_key_id: key, secret_access_key: secret, region: region) unless local_only?
      end

      def active?
        bucket && key && secret
      end

      protected

      def path
        @path ||= expand(config[:s3, :path] || config[:local, :path] || ':kind/:id')
      end

      def save
        # FIXME: user friendly error here :)
        raise 'pipe-streaming not supported for S3.' unless @backup.path

        puts "Uploading #{bucket}:#{full_path}" if verbose? || dry_run?
        return if dry_run? || local_only?

        if File.stat(@backup.path).size > MAX_S3_FILE_SIZE
          warn "ERROR: File size exceeds maximum allowed for upload to S3 (#{MAX_S3_FILE_SIZE}): #{@backup.path}"
          return
        end
        benchmark = Benchmark.realtime do
          the_bucket = @connection.buckets.create(bucket)
          File.open(@backup.path) do |file|
            the_bucket.objects.create(full_path, file)
          end
        end
        puts '...done' if verbose?
        puts("Upload took #{format('%.2f', benchmark)} second(s).") if verbose?
      end

      def cleanup
        return if local_only?

        return unless keep = config[:keep, :s3]

        puts "listing files: #{bucket}:#{base}*" if verbose?
        files = @connection.buckets[bucket].objects.with_prefix(base)
        puts files.collect(&:key) if verbose?

        files = files
                .collect(&:key)
                .sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing s3 file #{bucket}:#{f}" if dry_run? || verbose?
          @connection.bucket(bucket).object(f).delete unless dry_run? || local_only?
        end
      end

      def bucket
        config[:s3, :bucket]
      end

      def key
        config[:s3, :key]
      end

      def secret
        config[:s3, :secret]
      end

      def region
        config[:s3, :region]
      end

      private

      def bucket_exists?(bucket)
        @connection.bucket(bucket).exists?
      end

    end

  end

end
