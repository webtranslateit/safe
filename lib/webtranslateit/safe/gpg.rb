module WebTranslateIt
  module Safe
    class Gpg < Pipe

      def active?
        raise "can't use both gpg password and pubkey" if key && password

        !!(password || key)
      end

      protected

      def post_process
        @backup.compressed = true
      end

      def pipe
        command = config[:gpg, :command] || 'gpg'
        if key
          "|#{command} #{config[:gpg, :options]} -e -r #{key}"
        elsif password
          "|#{command} #{config[:gpg, :options]} -c --passphrase-file #{gpg_password_file(password)}"
        end
      end

      def extension
        '.gpg'
      end

      private

      def password
        @password ||= config[:gpg, :password]
      end

      def key
        @key ||= config[:gpg, :key]
      end

      def gpg_password_file(pass)
        return 'TEMP_GENERATED_FILENAME' if dry_run?
        WebTranslateIt::Safe::TmpFile.create('gpg-pass') { |file| file.write(pass) }
      end
    end
  end
end