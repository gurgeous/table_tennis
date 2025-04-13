module TableTennis
  class TestColumn < Minitest::Test
    def test_titleize
      data = TableData.new(config: Config.new, input_rows: [])
      assert_equal "foo_bar_id", Column.new(data, :foo_bar_id, 1).header
      data.config.titleize = true
      assert_equal "Foo Bar", Column.new(data, :foo_bar_id, 1).header
    end

    def test_detect_type
      data = TableData.new(config: Config.new, input_rows: [
        [1.23, 1234, 1, "gub", Time.now, :xyz],
        [1.23, 1.23, 1, "gub", Time.now, :xyz],
        [nil, nil, nil, nil, nil, nil],
      ])
      types = data.columns.map { _1.send(:detect_type) }
      assert_equal %i[float float int string time other], types
    end
  end
end
