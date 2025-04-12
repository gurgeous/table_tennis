module TableTennis
  module Stage
    # This stage "formats" the table by injesting columns that contain various
    # ruby objects and formatting each as a string. Cells are formatted in place
    # by transforming rows.
    class Format < Base
      attr_reader :fns, :placeholder

      def run
        @placeholder = config.placeholder || ""

        # built an fn for each column
        fns = columns.map do
          fn = fn_for_column_type(_1.type) || :other
          :"column_#{fn}"
        end

        rows.each do |row|
          row.map.zip(fns) do |(name, value), fn|
            row[name] = send(fn, value) || fmt_other(value)
          end
        end
      end

      #
      # column formatters
      #

      def fn_for_column_type(type)
        case type
        when :float then :float if config.digits
        when :time then :time if config.strftime
        when :int, :string then type
        end
      end

      def column_float(value)
        case value
        when String
          Util::What.float_or_int?(value) ? fmt_float(value.to_f) : fmt_str(value)
        when Numeric
          fmt_float(value)
        end
      end

      def column_int(value)
        case value
        when String
          Util::What.int?(value) ? fmt_int(value.to_i) : fmt_str(value)
        when Integer
          fmt_int(value)
        end
      end

      def column_time(value)
        if Util::What.time?(value)
          value.strftime(config.strftime)
        end
      end

      def column_string(value) = value ? fmt_str(value) : placeholder
      def column_other(value) = value ? fmt_other(value) : placeholder

      #
      # primitives
      #

      def fmt_str(str)
        # normalize whitespace
        if str.match?(/\s/)
          str = str.strip.gsub("\n", "\\n").gsub("\r", "\\r")
        end
        # empty?
        return placeholder if str.empty?
        str
      end

      def fmt_other(value)
        return placeholder if !value
        fmt_str(value.to_s)
      end

      def fmt_float(x) = (@fmt_float ||= "%.#{config.digits}f") % x
      def fmt_int(x) = x.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/) { "#{_1}," }
    end
  end
end
