module TableTennis
  module Stage
    # This stage "formats" the table by injesting columns that contain various
    # ruby objects and formatting each as a string. Cells are formatted in place
    # by transforming rows.
    class Format < Base
      def run
        # find (optional) fn for each column
        fns = columns.map do
          fn = fn(_1.type)
          :"fn_#{fn}" if fn
        end

        rows.each do |row|
          row.each_index do
            value = row[_1]
            value = send(fns[_1], value) if fns[_1]
            row[_1] = value || fallback(value)
          end
        end
      end

      #
      # fns for each column type
      #

      def fn(type)
        case type
        when :float then :float if config.digits
        when :int then :int
        when :time then :time if config.strftime
        end
      end

      def fn_float(value)
        case value
        when String then fmt_float(value.to_f) if Util::What.float_or_int?(value)
        when Numeric then fmt_float(value)
        end
      end

      def fn_int(value)
        case value
        when String then fmt_int(value.to_i) if Util::What.int?(value)
        when Integer then fmt_int(value)
        end
      end

      def fn_time(value)
        value.strftime(config.strftime) if Util::What.time?(value)
      end

      #
      # primitives
      #

      def placeholder = @placeholder ||= config.placeholder || ""

      def fallback(value)
        return placeholder if value.nil?
        # to string, normalize whitespace, honor placeholder
        str = (value.is_a?(String) ? value : value.to_s)
        str = str.strip.gsub("\n", "\\n").gsub("\r", "\\r") if str.match?(/\s/)
        str.empty? ? placeholder : str
      end

      def fmt_float(x) = (@fmt_float ||= "%.#{config.digits}f") % x
      def fmt_int(x) = x.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/) { "#{_1}," }
    end
  end
end
