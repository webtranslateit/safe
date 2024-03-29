module WebTranslateIt

  module Safe

    class Mongodump < Source

      def command # rubocop:todo Metrics/AbcSize
        opts = []
        opts << "--host #{config[:host]}" if config[:host]
        opts << "-u #{config[:user]}" if config[:user]
        opts << "-p #{config[:password]}" if config[:password]
        opts << "--out #{output_directory}"

        "mongodump -q \"{xxxx : { \\$ne : 0 } }\" --db #{@id} #{opts.join(' ')} && cd #{output_directory} && tar cf - ."
      end

      def extension = '.tar'

      protected

      def output_directory
        File.join(TmpFile.tmproot, 'mongodump')
      end

    end

  end

end
