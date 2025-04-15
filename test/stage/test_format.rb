module TableTennis
  module Stage
    class TestFormat < Minitest::Test
      def test_main
        types = %i[float int time string other]

        # this column has everything!
        kitchen_sink = [
          1234.567111, 1234, "-1234.567111", "-1234",
          "gub", :xyzzy,
          "  ", nil,
          Date.today, Time.now,
        ]
        # rows
        rows = ([kitchen_sink] * types.length).transpose

        # minimal - everything should just turn into a string
        Util::Identify.stubs(:identify_column).returns(*types)
        f = create_format(rows:, delims: false, digits: nil, placeholder: nil, strftime: nil).tap(&:run)
        f.columns.each do
          values = _1.to_a
          # numbers - passed through verbatim
          assert_equal %w[1234.567111 1234 -1234.567111 -1234 gub xyzzy], values.shift(6)
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
          when :float then assert_equal %w[1,234.567 1,234.000 -1,234.567 -1,234.000], numbers
          when :int then assert_equal %w[1234.567111 1,234 -1234.567111 -1,234], numbers
          else; assert_equal %w[1234.567111 1234 -1234.567111 -1234], numbers
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
          ["1234.567111", "1,234.567"],
          ["-1234.567111", "-1,234.567"],
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

      def test_fmt_number
        # f = create_format
        # tm = Time.now
        # # 0.234
        # 1_000_000.times { f.fmt_number(-1000, digits: 3) }
        # printf("\nbm %0.3f\n", Time.now - tm)

        # digits = false
        f = create_format
        [
          [1234, "1,234"],
          [0.0, "0"],
          [0.1234, "0.1234"],
          [1234.1234, "1,234.1234"],
          [-1234.1234, "-1,234.1234"],
        ].each do |x, exp|
          assert_equal(exp, f.fmt_number(x), "with #{x}")
        end

        # digits = 3
        f = create_format
        [
          [1234, "1,234.000"],
          [0.0, "0.000"],
          [0.1234, "0.123"],
          [1234.1234, "1,234.123"],
          [-1234.1234, "-1,234.123"],
        ].each do |x, exp|
          assert_equal(exp, f.fmt_number(x, digits: 3), "with #{x}")
        end

        f = create_format(delims: false)
        assert_equal("1234", f.fmt_number(1234))
        assert_equal("1234.1234", f.fmt_number(1234.1234))
        assert_equal("1234.123", f.fmt_number(1234.1234, digits: 3))
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
