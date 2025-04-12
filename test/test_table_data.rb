module TableTennis
  class TestTableData < Minitest::Test
    def test_all
      # columns inferred
      data = TableData.new(input_rows: [{a: 1, b: 2}])
      assert_equal %i[a b], data.column_names
      assert_equal [[1, 2]], data.rows

      # columns specified
      config = Config.new(columns: %i[a])
      data = TableData.new(config:, input_rows: [{a: 1, b: 2}])
      assert_equal %i[a], data.column_names
      assert_equal [[1]], data.rows
    end

    def test_different_inputs
      [
        [{a: 1}], # array of hashes (symbols)
        [{"a" => 1}], # array of hashes (strings)
        [HasToH.new(a: 1)], # to_h
        [HasAttributes.new(a: 1)], # ActiveModel/ActiveRecord
      ].each do |input_rows|
        data = TableData.new(input_rows:)
        assert_equal [[1]], data.rows
      end
    end

    def test_edge_input_rows
      # an array
      data = TableData.new(input_rows: [[1]])
      assert_equal [[1]], data.rows

      # a single hash. this is the only time input_rows is modified
      data = TableData.new(input_rows: {a: 1, b: 2})
      assert_equal [[:a, 1], [:b, 2]], data.rows
      assert_equal [{key: :a, value: 1}, {key: :b, value: 2}], data.input_rows

      # invalid
      assert_raises(ArgumentError) { TableData.new(input_rows: 123) }
    end

    def test_ragged_rows
      rows = TableData.new(input_rows: [
        {a: 1, b: 2}, {a: 1},
      ]).rows
      assert_equal [[1, 2], [1, nil]], rows
    end

    def test_missing_columns
      assert_raises(ArgumentError) do
        # there is no column c
        config = Config.new(columns: %i[a c])
        TableData.new(config:, input_rows: [{a: 1, b: 2}]).columns
      end
    end

    def test_row_numbers
      config = Config.new(row_numbers: true)
      data = TableData.new(config:, input_rows: [{a: 1}, {b: 2}])
      assert_equal :"#", data.columns.first.name
      assert_equal [1, 2], data.columns.first.to_a
    end

    def test_inspectable
      input_rows = 7.times.map { {a: rand, b: rand} }
      data = TableData.new(input_rows:)
      assert_match(/7 rows/, data.inspect_without_rows)
    end

    class HasAttributes
      def initialize(hash) = @hash = hash
      def attributes = @hash
    end

    class HasToH
      def initialize(hash) = @hash = hash
      def to_h = @hash
    end
  end
end
