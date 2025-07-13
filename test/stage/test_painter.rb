module TableTennis
  module Stage
    class TestPainter < Minitest::Test
      def test_main
        config = ConfigBuilder.build({
          color: true,
          color_scales: {b: :rg, c: :y},
          mark: ->(row) { row[:a] == "0" },
          placeholder: "NA",
          row_numbers: true,
          theme: :dark,
          zebra: true,
        })
        data = TableData.new(config:, rows: [
          {a: "0", b: "0", c: "a"},
          {a: "1", b: "1", c: "b"},
          {a: "2", b: "2", c: "a"},
          {a: "3", b: "3", c: "b"},
          {a: "NA", b: "4", c: "NA"},
          # ^^ gotta fill in the placeholder manually, no formatting stage
        ])
        Painter.new(data).run

        # row numbers
        assert_equal :chrome, data.get_style(c: 0)
        # headers
        assert_equal :header0, data.get_style(r: :header, c: 0)
        assert_equal :header1, data.get_style(r: :header, c: 1)
        # color scale numbers & categories
        assert (0..3).all? { data.get_style(r: _1, c: 2) != nil }
        assert (0..3).all? { data.get_style(r: _1, c: 3) != nil }
        # mark/zebra
        [:mark, nil, :zebra, nil, :zebra].each_with_index do |style, r|
          assert_equal style, data.get_style(r:), "row #{r}"
        end
        # placeholder
        assert_equal :chrome, data.get_style(r: 4, c: 1)
      end

      def test_mark_style
        data = TableData.new(config: ConfigBuilder.build, rows: ab)
        painter = Painter.new(data)
        [
          [true, :mark],
          [123, :mark],
          ["#000", ["white", "#000"]],
          ["black", %w[white black]],
          ["#fff", ["black", "#fff"]],
          [:white, ["black", :white]],
          ["red", %w[white red]],
          [:red, ["white", :red]],
          [%i[blue green], %i[blue green]],
        ].each do |user_mark, exp|
          assert_equal exp, painter.send(:mark_style, user_mark)
        end
      end
    end
  end
end
