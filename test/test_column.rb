module TableTennis
  class TestColumn < Minitest::Test
    def test_titleize
      data = TableData.new(config: Config.new, input_rows: [])
      assert_equal "foo_bar_id", Column.new(data, :foo_bar_id, 1).header
      data.config.titleize = true
      assert_equal "Foo Bar", Column.new(data, :foo_bar_id, 1).header
    end
  end
end
