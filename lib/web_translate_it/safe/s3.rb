module WebTranslateIt

  module Safe

    class S3 < Sink

      MAX_S3_FILE_SIZE = 5_368_709_120

      def active?
        bucket && key && secret
      end

      protected

      def path
        @path ||= expand(config[:s3, :path] || config[:local, :path] || ':kind/:id')
      end

      def save # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
        # FIXME: user friendly error here :)
        raise 'pipe-streaming not supported for S3.' unless @backup.path

        # needed in cleanup even on dry run
        AWS::S3::Base.establish_connection!(access_key_id: key, secret_access_key: secret, use_ssl: true) unless local_only?

        puts "Uploading #{bucket}:#{full_path}" if verbose? || dry_run?
        return if dry_run? || local_only?

        if File.stat(@backup.path).size > MAX_S3_FILE_SIZE
          warn "ERROR: File size exceeds maximum allowed for upload to S3 (#{MAX_S3_FILE_SIZE}): #{@backup.path}"
          return
        end
        benchmark = Benchmark.realtime do
          AWS::S3::Bucket.create(bucket) unless bucket_exists?(bucket)
          File.open(@backup.path) do |file|
            AWS::S3::S3Object.store(full_path, file, bucket)
          end
        end
        puts '...done' if verbose?
        puts("Upload took #{format('%.2f', benchmark)} second(s).") if verbose?
      end

      # rubocop:todo Metrics/PerceivedComplexity
      def cleanup # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        return if local_only?

        return unless keep = config[:keep, :s3]

        puts "listing files: #{bucket}:#{base}*" if verbose?
        files = AWS::S3::Bucket.objects(bucket, prefix: base, max_keys: keep * 2)
        puts files.collect(&:key) if verbose?

        files = files
                .collect(&:key)
                .sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing s3 file #{bucket}:#{f}" if dry_run? || verbose?
          AWS::S3::Bucket.objects(bucket, prefix: f)[0].delete unless dry_run? || local_only?
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def bucket
        config[:s3, :bucket]
      end

      def key
        config[:s3, :key]
      end

      def secret
        config[:s3, :secret]
      end

      private

      def bucket_exists?(bucket)
        true if AWS::S3::Bucket.find(bucket)
      rescue AWS::S3::NoSuchBucket
        false
      end

    end

  end

end
