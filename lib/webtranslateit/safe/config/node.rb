require 'webtranslateit/safe/config/builder'
module WebTranslateIt
  module Safe
    module Config
      class Node
        attr_reader :parent, :data

        def initialize(parent = nil, data = {}, &block)
          @parent = parent
          @data = {}
          merge data, &block
        end

        def merge(data = {}, &block)
          builder = Builder.new(self, data)
          builder.instance_eval(&block) if block
          self
        end

        # looks for the path from this node DOWN. will not delegate to parent
        def get(*path)
          key = path.shift
          value = @data[key.to_s]
          return value if !value.nil? && path.empty?

          value&.get(*path)
        end

        # recursive find
        # starts at the node and continues to the parent
        def find(*path)
          get(*path) || @parent&.find(*path)
        end
        alias :[] :find

        def set_multi(key, value)
          @data[key.to_s] ||= []
          @data[key.to_s].push(*value)
        end

        def set(key, value)
          @data[key.to_s] = value
        end
        alias :[]= :set

        def each(&block)
          @data.each(&block)
        end
        include Enumerable

        def to_hash
          @data.keys.each_with_object({}) do |key, res|
            value = @data[key]
            res[key] = value.is_a?(Node) ? value.to_hash : value
          end
        end

        def dump(indent = '')
          @data.each do |key, value|
            if value.is_a?(Node)
              puts "#{indent}#{key}:"
              value.dump("#{indent}    ")
            else
              puts "#{indent}#{key}: #{value.inspect}"
            end
          end
        end
      end
    end
  end
end
