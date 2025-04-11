module TableTennis
  module Stage
    # This stage "formats" the table by injesting cells that contain various
    # ruby objects and formatting each one as a string. `rows` are formatted in
    # place.
    #
    # For performance reasons, formatting is implemented as a series of lambdas.
    # Each fn must return a string. Minimize the number of times we examine each
    # cell. Float detection/printing can be slow. Favor .match? over =~.
    class Format < Base
      attr_reader :fns

      def run
        setup_fns
        rows.each do |row|
          row.transform_values! do
            fn = fns[fn_for(_1)] || fns[:other]
            fn.call(_1)
          end
        end
      end

      def fn_for(value)
        case value
        when String then float?(value) ? :floatstr : :str
        when Float then :float
        when Date, Time, DateTime then :time
        else
          if value.respond_to?(:acts_like_time)
            # Rails TimeWithZone
            return :time
          end
          :other
        end
      end

      def float?(str) = str.match?(/^-?\d+[.]\d+$/)

      def setup_fns
        placeholder = config.placeholder || ""
        str = ->(s) do
          # normalize whitespace
          if s.match?(/\s/)
            s = s.strip.gsub("\n", "\\n").gsub("\r", "\\r")
          end
          # replace empty values with placeholder
          s = placeholder if s.empty?
          s
        end
        other = ->(x) { str.call(x.to_s) }

        # default behavior
        @fns = {other:, str:}

        # now mix in optional float/time formatters
        if config.digits
          fmt = "%.#{config.digits}f"
          @to_f_cache = Hash.new { _1[_2] = fmt % _2.to_f }
          fns[:float] = -> { fmt % _1 }
          fns[:floatstr] = -> { @to_f_cache[_1] }
        end
        if config.strftime
          fns[:time] = -> { _1.strftime(config.strftime) }
        end
      end
    end
  end
end
