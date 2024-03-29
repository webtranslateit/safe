module WebTranslateIt

  module Safe

    class Sink < Stream

      def process
        return unless active?

        save
        cleanup
      end

      protected

      # path is defined in subclass
      # base is used in 'cleanup' to find all files that begin with base. the '.'
      # at the end is essential to distinguish b/w foo.* and foobar.* archives for example
      def base
        @base ||= File.join(path, "#{File.basename(@backup.filename).split('.').first}.")
      end

      def full_path
        @full_path ||= File.join(path, @backup.filename) + @backup.extension
      end

      # call block on files to be removed (all except for the LAST 'limit' files
      def cleanup_with_limit(files, limit, &)
        return unless files.size > limit

        to_remove = files[0..(files.size - limit - 1)]
        # TODO: validate here
        to_remove.each(&)
      end

    end

  end

end
