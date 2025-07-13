module TableTennis
  class TestColumn < Minitest::Test
    def test_headers
      # normal
      data = TableData.new(config: ConfigBuilder.build, rows: [])
      assert_equal "foo_bar_id", Column.new(data, :foo_bar_id, 1).header

      # headers:
      data.config.headers = {hello: "world"}
      assert_equal "world", Column.new(data, :hello, 1).header

      # titleize: true
      data.config.titleize = true
      assert_equal "Foo Bar", Column.new(data, :foo_bar_id, 1).header
    end

    def test_measure
      [
        [{hi: "hello"}, 5], # long cell
        [{foo: "b"}, 3], # long header
        [{a: "b"}, 2], # min 2
      ].each do |row, exp|
        data = TableData.new(config: ConfigBuilder.build, rows: [row])
        assert_equal exp, data.columns.first.measure, "#{row} => #{exp}"
      end
    end
  end
end
