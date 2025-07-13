module TableTennis
  module Stage
    class TestLayout < Minitest::Test
      def test_false
        config = ConfigBuilder.build({layout: false})
        data = TableData.new(config:, rows: [{hello: "x" * 123}])
        Layout.new(data).run
        assert_equal([123], data.columns.map(&:width))
        assert_equal([123], data.rows.first.map(&:length))
      end

      def test_constant
        config = ConfigBuilder.build({layout: 3})
        data = TableData.new(config:, rows: [{hello: "world"}])
        Layout.new(data).run

        # widths should get set, both header/data should get truncated
        assert_equal([3], data.columns.map(&:width))
        assert_equal([3], data.columns.map(&:header).map(&:length))
        assert_equal([3], data.rows.first.map(&:length))
      end

      def test_hash
        config = ConfigBuilder.build({layout: {foo: 3}})
        data = TableData.new(config:, rows: [{foo: "foooo", barbar: "baaarrrr"}])
        Layout.new(data).run

        # widths should get set, both header/data should get truncated
        assert_equal([3, 8], data.columns.map(&:width))
        assert_equal([3, 6], data.columns.map(&:header).map(&:length))
        assert_equal([3, 8], data.rows.first.map(&:length))
      end

      def test_autolayout
        config = ConfigBuilder.build
        assert_true config.layout
        data = TableData.new(config:, rows: [{address: "x" * 10, name: "x" * 20}])

        # extra large
        terminal = Terminal.new(nil)
        terminal.stubs(:width).returns(80)
        Layout.new(data, terminal:).run
        assert_equal([10, 20], data.columns.map(&:width))
        assert_equal([7, 4], data.columns.map(&:header).map(&:length))
        assert_equal([10, 20], data.rows.first.map(&:length))

        # cruncha muncha
        terminal = Terminal.new(nil)
        terminal.stubs(:width).returns(20)
        Layout.new(data, terminal:).run
        assert_equal([5, 6], data.columns.map(&:width))
        assert_equal([5, 4], data.columns.map(&:header).map(&:length))
        assert_equal([5, 6], data.rows.first.map(&:length))

        # tiny
        terminal = Terminal.new(nil)
        terminal.stubs(:width).returns(10)
        Layout.new(data, terminal:).run
        assert_equal([2, 2], data.columns.map(&:width))
        assert_equal([2, 2], data.columns.map(&:header).map(&:length))
        assert_equal([2, 2], data.rows.first.map(&:length))
      end

      def test_emojis
        rockets = "🚀" * 10
        config = ConfigBuilder.build({layout: 3})
        data = TableData.new(config:, rows: [{a: rockets}])
        Layout.new(data).run
        assert_equal("🚀…", data.rows.first.first)
      end

      def test_lower_bound
        config = ConfigBuilder.build

        rows = [["hello world how are you doing today"] * 2]

        # if we don't have a lot of room, min should be 2
        terminal = Terminal.new(nil)
        terminal.stubs(:width).returns(10)
        data = TableData.new(config:, rows:)
        Layout.new(data, terminal:).run
        assert_equal [2, 2], data.columns.map(&:width)

        # if we have more room, columns can breathe
        terminal = Terminal.new(nil)
        terminal.stubs(:width).returns(40)
        data = TableData.new(config:, rows:)
        Layout.new(data, terminal:).run
        assert_equal [16, 15], data.columns.map(&:width)
      end
    end
  end
end
