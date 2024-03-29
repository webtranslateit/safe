module WebTranslateIt

  module Safe

    class Source < Stream

      attr_accessor :id

      def initialize(id, config)
        @id = id.to_s
        @config = config
      end

      def timestamp
        Time.now.strftime('%y%m%d-%H%M')
      end

      def kind
        self.class.human_name
      end

      def filename
        @filename ||= expand(':kind-:id.:timestamp')
      end

      def backup
        return @backup if @backup

        @backup = Backup.new(
          id: @id,
          kind: kind,
          extension: extension,
          command: command,
          timestamp: timestamp
        )
        # can't do this in the initializer hash above since
        # filename() calls expand() which requires @backup
        # FIXME: move expansion to the backup (last step in ctor) assign :tags here
        @backup.filename = filename
        @backup
      end

      def self.human_name
        name.split('::').last.downcase
      end

    end

  end

end
