module TableTennis
  module Stage
    class TestFormat < Minitest::Test
      def test_floats
        # floats should be formatted to 3 by default
        assert_equal "1.123", format_one(value: "1.12345")
        assert_equal "1.123", format_one(value: 1.12345)
        # or not
        config = Config.new(digits: nil)
        assert_equal "1.12345", format_one(config:, value: 1.12345)
        assert_equal "1.12345", format_one(config:, value: "1.12345")
      end

      def test_other
        assert_equal "foo", format_one(value: :foo)
        assert_equal "foo bar", format_one(value: :" foo bar ")
      end

      def test_placeholder
        config = Config.new(placeholder: "foo")
        [nil, "", " "].each do |value|
          assert_equal "foo", format_one(config:, value:)
        end
      end

      def test_strftime
        config = Config.new(strftime: "%Y-%m-%d") # test strftime formatting
        [Time.now, Date.today, WithStrftime.new].each do |value|
          assert_match(/^\d{4}-\d{2}-\d{2}$/, format_one(config:, value:))
        end
      end

      def test_whitespace
        assert_equal "foo\\nbar\\rx", format_one(value: " foo\nbar\rx ")
      end

      def format_one(value:, config: nil)
        config ||= Config.new
        data = TableData.new(config:, input_rows: [{value:}])
        Format.new(data).run
        data.first_cell
      end

      # TimeWithZone
      class WithStrftime
        def strftime(_) = "9999-99-99" # hack
      end
    end
  end
end
