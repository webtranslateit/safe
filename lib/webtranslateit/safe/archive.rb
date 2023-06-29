module WebTranslateIt
  module Safe
    class Archive < Source

      def command
        "tar -cf - #{config[:options]} #{tar_exclude_files} #{tar_files}"
      end

      def extension = '.tar'

      protected

      def tar_exclude_files
        [*config[:exclude]].compact.map { |x| "--exclude=#{x}" }.join(' ')
      end

      def tar_files
        raise 'missing files for tar' unless config[:files]
        [*config[:files]].map(&:strip).join(' ')
      end

    end
  end
end
