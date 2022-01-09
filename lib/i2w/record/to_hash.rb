module I2w
  class Record
    # Object that serializes a Record to a hash (suitable for creating a Model, or JSON)
    #
    #   extra:      hash of attribute name and callable (record arg), eg: { foobar: -> { _1.foo + _1.bar } }
    #   only:       array of record attribute names to whitelist
    #   except:     array of record attribute names to blacklist
    #   always:     array of attribute names to add to the output, even if they are not provided
    #   on_missing: callable (attribute name arg) to populate missing attributes specified by :always
    class ToHash
      def initialize(extra: {}, only: nil, except: nil, always: nil, on_missing: nil)
        raise ArgumentError, "can't set both only and except" if except && only

        @extra = extra
        @only = [*only] if only
        @except = [*except] if except
        @always = [*always]
        @on_missing = on_missing

        freeze
      end

      def call(record)
        attrs = record.to_hash
        attrs = attrs.dup if record.equal?(attrs)

        attrs.tap do |a|
          a.slice!(*@only) if @only
          a.extract!(*@except) if @except
          a.merge!(@extra.to_h { [_1, _2.call(record)] })
          @always.each { a[_1] = @on_missing&.call(_1) unless a.key?(_1) }
        end
      end
    end
  end
end