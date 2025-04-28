module TableTennis
  class TestColumn < Minitest::Test
    def test_titleize
      data = TableData.new(config: Config.new, rows: [])
      assert_equal "foo_bar_id", Column.new(data, :foo_bar_id, 1).header
      data.config.titleize = true
      assert_equal "Foo Bar", Column.new(data, :foo_bar_id, 1).header
    end

    def test_measure
      [
        [{hi: "hello"}, 5], # long cell
        [{foo: "b"}, 3], # long header
        [{a: "b"}, 2], # min 2
      ].each do |row, exp|
        data = TableData.new(config: Config.new, rows: [row])
        assert_equal exp, data.columns.first.measure, "#{row} => #{exp}"
      end
    end
  end
end
