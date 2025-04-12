module TableTennis
  class TestColumn < Minitest::Test
    def test_titleize
      data = TableData.new(config: Config.new, input_rows: [])
      assert_equal "foo_bar_id", Column.new(:foo_bar_id, data).header
      data.config.titleize = true
      assert_equal "Foo Bar", Column.new(:foo_bar_id, data).header
    end
  end
end
