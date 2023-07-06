# frozen_string_literal: true

module WebTranslateIt

  module Safe

    class Pigz < Pipe

      protected

      def post_process
        @backup.compressed = true
      end

      def pipe
        '|pigz'
      end

      def extension
        '.gz'
      end

      def active?
        !@backup.compressed && !(find_executable 'pigz').nil?
      end

    end

  end

end
