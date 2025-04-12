module TableTennis
  module Stage
    class TestPainter < Minitest::Test
      def test_main
        config = Config.new(
          color: true,
          color_scales: {b: :rg},
          mark: ->(row) { row[:a] == "0" },
          placeholder: "NA",
          row_numbers: true,
          theme: :dark,
          zebra: true
        )
        data = TableData.new(config:, input_rows: [
          {a: "0", b: "0"},
          {a: "1", b: "1"},
          {a: "2", b: "2"},
          {a: "3", b: "3"},
          {a: "NA", b: "4"},
        ])
        Painter.new(data).run

        # row numbers
        assert_equal :chrome, data.get_style(c: 0)
        # color scale
        assert (0..3).all? { data.get_style(r: _1, c: 2) != nil }
        # mark/zebra
        [:mark, nil, :zebra, nil, :zebra].each_with_index do |style, r|
          assert_equal style, data.get_style(r:), "row #{r}"
        end
        # cell
        assert_equal :chrome, data.get_style(r: 4, c: 1)
        # placeholder
        assert_equal :chrome, data.get_style(r: 4, c: 1)
      end

      def test_mark_style
        data = TableData.new(config: Config.new, input_rows: ab)
        painter = Painter.new(data)
        [
          [true, :mark],
          [123, :mark],
          ["red", [nil, "red"]],
          [:red, [nil, :red]],
          [%i[blue green], %i[blue green]],
        ].each do |user_mark, exp|
          assert_equal exp, painter.send(:mark_style, user_mark)
        end
      end
    end
  end
end
