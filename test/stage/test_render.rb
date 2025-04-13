module TableTennis
  module Stage
    class TestRender < Minitest::Test
      def test_main
        lines = render_string.split("\n")
        assert_match(/^╭─+╮$/, lines[ii = 0]) # sep
        assert_match(/^│ +xyzzy +│$/, lines[ii += 1]) # title
        assert_match(/^├─+┬─+┤$/, lines[ii += 1]) # sep
        assert_match(/^│\s+a\s+│\s+b\s+│$/, lines[ii += 1]) # headers
        assert_match(/^├─+┼─+┤$/, lines[ii += 1]) # sep
        assert_match(/^│\s+1\s+│\s+│$/, lines[ii += 1]) # row 0
        assert_match(/^╰─+┴─+╯$/, lines[ii + 1]) # sep
      end

      def test_colors
        %i[dark light ansi].each do |theme|
          exp = Theme.new(theme).codes(:chrome)

          # with color
          body = render_string(color: true, theme:)
          actual = body[/(\e[^m]+m)╭/, 1]
          assert_equal exp, actual, "theme: #{theme}"

          # without
          body = render_string(theme:)
          refute_match(/\e/, body, "theme: #{theme}")
        end
      end

      # this one is important, let's test separately
      def test_cell
        render = create_render
        render.expects(:paint).with("1  ", :cell)
        render.expects(:paint).with("2  ", :foo)
        render.expects(:paint).with("3  ", :foo)
        render.expects(:paint).with("4  ", :foo)

        # :cell
        render.render_cell("1", 0, 1, nil)
        # default_cell_style > :cell
        render.render_cell("2", 0, 1, :foo)
        # column > default_cell_style
        render.data.set_style(c: 1, style: :foo)
        render.render_cell("3", 0, 1, :bogus)
        # cell > column
        render.data.set_style(c: 1, style: :bogus)
        render.data.set_style(r: 0, c: 1, style: :foo)
        render.render_cell("4", 0, 1, :bogus)
      end

      # no rows or no cols? this can happen for sure
      def test_empty
        [[], [{}, {}, {}, {}]].each do |rows|
          lines = render_string(rows:).split("\n")
          assert_match(/^╭─+╮$/, lines[ii = 0]) # sep
          assert_match(/^│ +xyzzy +│$/, lines[ii += 1]) # title
          assert_match(/^├─+┤$/, lines[ii += 1]) # sep
          assert_match(/^│ +no data +│$/, lines[ii += 1]) # body
          assert_match(/^╰─+╯$/, lines[ii + 1]) # sep
        end
      end

      def test_truncate_title
        title = ("a".."z").to_a.join
        title_line = render_string(title:).split("\n")[1]
        assert_match(/abc\w+…/, title_line)
      end

      def test_alignment
        [
          [:float, /^│   a │/],
          [:int, /^│   a │/],
          [:unknown, /^│ a   │/],
          [nil, /^│ a   │/],
        ].each do |type, alignment|
          Column.any_instance.stubs(:type).returns(type)
          assert_match(alignment, render_string(title: nil).split("\n")[1])
        end
      end

      protected

      def create_render(color: false, rows: nil, theme: nil, title: "xyzzy")
        rows ||= [{a: "1", b: " "}]
        config = Config.new(color:, theme:, title:)
        data = TableData.new(config:, rows:)
        if data.columns.length >= 2
          data.columns[0].width = 3
          data.columns[1].width = 3
        end
        Render.new(data)
      end

      def render_string(color: false, rows: nil, theme: nil, title: "xyzzy")
        render = create_render(color:, rows:, theme:, title:)
        StringIO.new.tap { render.run(_1) }.string
      end
    end
  end
end
