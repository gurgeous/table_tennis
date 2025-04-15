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
          when :float then :fn_float
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
            row[_1] = formatted || fn_default(value) || config.placeholder
          end
        end
      end

      #
      # fns for each column type
      #

      def fn_float(value)
        case value
        when String then fmt_number(to_f(value), digits: config.digits) if Util::Identify.number?(value)
        when Numeric then fmt_number(value, digits: config.digits)
        end
      end

      def fn_int(value)
        case value
        when String then fmt_number(to_i(value)) if Util::Identify.int?(value)
        when Integer then fmt_number(value)
        end
      end

      def fn_time(value)
        value.strftime(config.strftime) if Util::Identify.time?(value)
      end

      #
      # primitives
      #

      # default formatting. cleanup whitespace
      def fn_default(value)
        return if value.nil?
        str = (value.is_a?(String) ? value : value.to_s)
        str = str.strip.gsub("\n", "\\n").gsub("\r", "\\r") if str.match?(/\s/)
        return if str.empty?
        str
      end

      DELIMS = /(\d)(?=(\d\d\d)+(?!\d))/

      # this is a bit slow but easy to understand
      def fmt_number(x, digits: nil)
        delims = config.delims && (x >= 1000 || x <= -1000)

        # convert to string (and honor digits)
        x = if digits
          "%0.#{digits}f" % x
        else
          # be careful not to leave a trailing .0
          x = x.to_i if x.is_a?(Float) && (x % 1) == 0
          x.to_s
        end

        if delims
          x, r = x.split(".")
          x.gsub!(DELIMS) { "#{_1}," }
          x = "#{x}.#{r}" if r
        end

        x
      end

      # str to_xxx that are resistant to commas
      def to_f(str) = str.delete(",").to_f
      def to_i(str) = str.delete(",").to_i
    end
  end
end
