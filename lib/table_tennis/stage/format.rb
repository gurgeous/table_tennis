module TableTennis
  module Stage
    # This stage "formats" the table by injesting columns that contain various
    # ruby objects and formatting each as a string. Cells are formatted in place
    # by transforming rows.
    class Format < Base
      def run
        # Sample each column and infer column types. Determine which fn_xxx to
        # use for each column.
        fns = columns.map do
          fn = case _1.type
          when :float then :fn_float if config.digits
          when :int then :fn_int
          when :time then :fn_time if config.strftime
          end
          fn || :fn_default
        end

        rows.each do |row|
          row.each_index do
            value = row[_1]
            # Try to format using the column fn. This can return nil. For
            # example, a float column and value is nil, not a float, etc.
            formatted = send(fns[_1], value)
            # If the column formatter failed, use the default formatter
            row[_1] = formatted || fn_default(value)
          end
        end
      end

      #
      # fns for each column type
      #

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

      def fn_default(value)
        return config.placeholder if value.nil?
        # to string, normalize whitespace, honor placeholder
        str = (value.is_a?(String) ? value : value.to_s)
        str = str.strip.gsub("\n", "\\n").gsub("\r", "\\r") if str.match?(/\s/)
        str.empty? ? config.placeholder : str
      end

      def fmt_float(x) = (@fmt_float ||= "%.#{config.digits}f") % x
      def fmt_int(x) = x.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/) { "#{_1}," }
    end
  end
end
