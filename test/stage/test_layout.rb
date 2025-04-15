module TableTennis
  module Stage
    class TestLayout < Minitest::Test
      def test_false
        config = Config.new(layout: false)
        data = TableData.new(config:, rows: [{hello: "x" * 123}])
        Layout.new(data).run
        assert_equal([123], data.columns.map(&:width))
        assert_equal([123], data.rows.first.map(&:length))
      end

      def test_constant
        config = Config.new(layout: 3)
        data = TableData.new(config:, rows: [{hello: "world"}])
        Layout.new(data).run

        # widths should get set, both header/data should get truncated
        assert_equal([3], data.columns.map(&:width))
        assert_equal([3], data.columns.map(&:header).map(&:length))
        assert_equal([3], data.rows.first.map(&:length))
      end

      def test_hash
        config = Config.new(layout: {foo: 3})
        data = TableData.new(config:, rows: [{foo: "foooo", barbar: "baaarrrr"}])
        Layout.new(data).run

        # widths should get set, both header/data should get truncated
        assert_equal([3, 8], data.columns.map(&:width))
        assert_equal([3, 6], data.columns.map(&:header).map(&:length))
        assert_equal([3, 8], data.rows.first.map(&:length))
      end

      def test_autolayout
        config = Config.new
        assert_equal true, config.layout
        data = TableData.new(config:, rows: [{address: "x" * 10, name: "x" * 20}])

        # extra large
        IO.console.stubs(:winsize).returns([nil, 80])
        Layout.new(data).run
        assert_equal([10, 20], data.columns.map(&:width))
        assert_equal([7, 4], data.columns.map(&:header).map(&:length))
        assert_equal([10, 20], data.rows.first.map(&:length))

        # cruncha muncha
        IO.console.stubs(:winsize).returns([nil, 20])
        Layout.new(data).run
        assert_equal([4, 7], data.columns.map(&:width))
        assert_equal([4, 4], data.columns.map(&:header).map(&:length))
        assert_equal([4, 7], data.rows.first.map(&:length))

        # tiny
        IO.console.stubs(:winsize).returns([nil, 10])
        Layout.new(data).run
        assert_equal([2, 2], data.columns.map(&:width))
        assert_equal([2, 2], data.columns.map(&:header).map(&:length))
        assert_equal([2, 2], data.rows.first.map(&:length))
      end

      def test_emojis
        rockets = "🚀" * 10
        config = Config.new(layout: 3)
        data = TableData.new(config:, rows: [{a: rockets}])
        Layout.new(data).run
        assert_equal("🚀…", data.rows.first.first)
      end
    end
  end
end
