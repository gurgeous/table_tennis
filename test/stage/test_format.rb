module TableTennis
  module Stage
    class TestFormat < Minitest::Test
      # REMIND: remove first_call
      # end to end test
      def test_main
        # find (optional) fn for each column
        # fns = columns.map do
        #   fn = fn(_1.type)
        #   :"fn_#{fn}" if fn
        # end
        # rows.each do |row|
        #   row.each_index do
        #     value = row[_1]
        #     value = send(fns[_1], value) if fns[_1]
        #     row[_1] = value || fallback(value)
        #   end
        # end
      end

      # fn()
      def test_fn
        f = create_format
        assert_equal :int, f.fn(:int)
        # w optional formatting
        config = f.config
        config.digits, config.strftime = 123, "xx"
        assert_equal :float, f.fn(:float)
        assert_equal :time, f.fn(:time)
        # w/o optional formatting
        config.digits = config.strftime = nil
        assert_nil f.fn(:float)
        assert_nil f.fn(:time)
      end

      #
      # fns
      #

      def test_fn_float
        f = create_format
        [
          # floats
          ["1.12345", "1.123"],
          ["-1.12345", "-1.123"],
          ["1.1", "1.100"],
          ["1.", "1.000"],
          ["0", "0.000"],
          [1.12345, "1.123"],
          [1, "1.000"],
          # unsupported
          [:surprise, nil],
          ["   ", nil],
          ["gub", nil],
          [nil, nil],
        ].each do |value, exp|
          assert_equal exp, f.fn_float(value)
        end
      end

      def test_fn_int
        f = create_format
        [
          # int
          ["123", "123"],
          [123, "123"],
          ["1", "1"],
          ["-123", "-123"],
          # unsupported
          [:surprise, nil],
          ["   ", nil],
          ["123.45", nil],
          ["gub", nil],
          [nil, nil],
        ].each do |value, exp|
          assert_equal exp, f.fn_int(value)
        end
      end

      def test_fn_time
        f = create_format
        # times
        [Time.now, Date.today, DateTime.now, WithStrftime.new].each do
          assert_match(/^\d{4}-\d{2}-\d{2}$/, f.fn_time(_1))
        end
        # unsupported
        [:surprise, "   ", "gub", nil].each do
          assert_nil f.fn_time(_1)
        end
      end

      #
      # primitives
      #

      def test_placeholder
        assert_equal "foo", create_format(placeholder: "foo").placeholder
        assert_equal "", create_format(placeholder: nil).placeholder
      end

      def test_fallback
        f = create_format
        [
          [nil, "NA"],
          ["", "NA"],
          ["   ", "NA"],
          ["foo", "foo"],
          [" foo\nbar\rx ", "foo\\nbar\\rx"],
        ].each do |value, exp|
          assert_equal exp, f.fallback(value)
        end
      end

      def test_fmt_float
        f = create_format
        assert_equal("-1.234", f.fmt_float(-1.234111))
        assert_equal("1", f.fmt_int(1))
        assert_equal("1,234,567", f.fmt_int(1234567))
        assert_equal("-1,234,567", f.fmt_int(-1234567))
      end

      # def test_floats
      #   # floats should be formatted to 3 by default
      #   assert_equal "1.123", format_one(value: "1.12345")
      #   assert_equal "1.123", format_one(value: 1.12345)
      #   # or not
      #   config = Config.new(digits: nil)
      #   assert_equal "1.12345", format_one(config:, value: 1.12345)
      #   assert_equal "1.12345", format_one(config:, value: "1.12345")
      # end

      # def test_other
      #   assert_equal "foo", format_one(value: :foo)
      #   assert_equal "foo bar", format_one(value: :" foo bar ")
      # end

      # def test_placeholder
      #   config = Config.new(placeholder: "foo")
      #   [nil, "", " "].each do |value|
      #     assert_equal "foo", format_one(config:, value:)
      #   end
      # end

      # def test_strftime
      #   config = Config.new(strftime: "%Y-%m-%d") # test strftime formatting
      #   [Time.now, Date.today, WithStrftime.new].each do |value|
      #     assert_match(/^\d{4}-\d{2}-\d{2}$/, format_one(config:, value:))
      #   end
      # end

      # def test_whitespace
      #   assert_equal "foo\\nbar\\rx", format_one(value: " foo\nbar\rx ")
      # end

      protected

      def create_format(input_rows: [], **options)
        defaults = {placeholder: "NA", digits: 3, strftime: "%Y-%m-%d"}
        config = Config.new(defaults.merge(options))
        data = TableData.new(config:, input_rows:)
        Format.new(data)
      end

      # def format_one(value:, config: nil)
      #   config ||= Config.new
      #   data = TableData.new(config:, input_rows: [{value:}])
      #   f.new(data).run
      #   data.first_cell
      # end

      # TimeWithZone
      class WithStrftime
        def strftime(_) = "9999-99-99" # hack
      end
    end
  end
end
