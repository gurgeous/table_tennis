module TableTennis
  module Stage
    class TestFormat < Minitest::Test
      def test_main
        types = %i[float int time string other]

        # this column has everything!
        kitchen_sink = [
          1.2345, 12345, "1.2345", "12345",
          "gub", :xyzzy,
          "  ", nil,
          Date.today, Time.now,
        ]
        # rows
        rows = ([kitchen_sink] * types.length).transpose

        # minimal - everything should just turn into a string
        Util::Identify.stubs(:identify_column).returns(*types)
        f = create_format(rows:, digits: nil, placeholder: nil, strftime: nil).tap(&:run)
        f.columns.each do
          # numbers (no digits)
          values = _1.to_a
          if _1.type == :int
            assert_equal %w[1.2345 12,345 1.2345 12,345 gub xyzzy], values.shift(6)
          else
            assert_equal %w[1.2345 12345 1.2345 12345 gub xyzzy], values.shift(6)
          end
          # empty (no placeholder)
          2.times { assert_equal "", values.shift }
          # date/time (no strftime)
          assert_match(/^[\d-]{10}/, values.shift)
          assert_match(/^[\d-]{10} \d\d/, values.shift)
        end

        # maximal
        Util::Identify.stubs(:identify_column).returns(*types)
        f = create_format(rows:, strftime: "%Y").tap(&:run)
        f.columns.each do
          values = _1.to_a
          # numbers (digits = 3)
          numbers = values.shift(4)
          case _1.type
          when :float then assert_equal %w[1.234 12345.000 1.234 12345.000], numbers
          when :int then assert_equal %w[1.2345 12,345 1.2345 12,345], numbers
          else; assert_equal %w[1.2345 12345 1.2345 12345], numbers
          end
          # strings & placeholder
          assert_equal %w[gub xyzzy NA NA], values.shift(4)
          # date/time (strftime = %Y)
          if _1.type == :time
            2.times { assert_match(/^\d{4}$/, values.shift) }
          else
            2.times { assert_match(/^[\d-]{10}/, values.shift) }
          end
        end
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
          assert_match(/^\d{4}$/, f.fn_time(_1))
        end
        # unsupported
        [:surprise, "   ", "gub", nil].each do
          assert_nil f.fn_time(_1)
        end
      end

      def test_fn_default
        f = create_format
        [
          [nil, nil],
          ["", nil],
          ["   ", nil],
          ["foo", "foo"],
          [" foo\nbar\rx ", "foo\\nbar\\rx"],
        ].each do |value, exp|
          assert_equal exp, f.fn_default(value)
        end
      end

      #
      # primitives
      #

      def test_fmt_float
        f = create_format
        assert_equal("-1.234", f.fmt_float(-1.234111))
        assert_equal("1", f.fmt_int(1))
        assert_equal("1,234,567", f.fmt_int(1234567))
        assert_equal("-1,234,567", f.fmt_int(-1234567))
      end

      protected

      def create_format(rows: [], **options)
        defaults = {digits: 3, placeholder: "NA", strftime: "%Y"}
        config = Config.new(defaults.merge(options))
        data = TableData.new(config:, rows:)
        Format.new(data)
      end

      # Rails TimeWithZone
      class WithStrftime
        def strftime(fmt) = Time.now.strftime(fmt)
      end
    end
  end
end
