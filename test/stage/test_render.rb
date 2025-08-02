module TableTennis
  module Stage
    class TestRender < Minitest::Test
      def test_main
        lines = render_string.split("\n")
        [
          /^╭─+╮$/,              # top
          /^│ +xyzzy +│$/,       # title
          /^├─+┬─+┤$/,           # sep
          /^│\s+a\s+│\s+b\s+│$/, # headers
          /^├─+┼─+┤$/,           # sep
          /^│\s+1\s+│\s+│$/,     # row 0
          /^╰─+┴─+╯$/,           # bot
        ].zip(lines) { assert_match(_1, _2) }
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
          [
            /^╭─+╮$/,          # top
            /^│ +xyzzy +│$/,   # title
            /^├─+┤$/,          # sep
            /^│ +no data +│$/, # body
            /^╰─+╯$/,          # bot
          ].zip(lines) { assert_match(_1, _2) }
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

      def test_no_separators
        lines = render_string(separators: false).split("\n")
        [
          /^╭─+╮$/,          # top
          /^│ +xyzzy +│$/,   # title
          /^│\s+a\s+b\s+│$/, # headers
          /^│\s+1\s+│$/,     # row 0
          /^╰─+╯$/,          # bot
        ].zip(lines) { assert_match(_1, _2) }
      end

      def test_link
        # add a link
        r = create_render.tap do
          _1.data.links[[0, 0]] = "https://example.com"
        end
        # no color, no link
        refute_match(/example.com/, render_to_string(r))
        # with color, link
        r.config.color = true
        assert_match(/example\.com/, render_to_string(r))
      end

      def test_painted_text_whitespace
        painted_rows = [
          {
            Paint["a", :green] => Paint[1, :red],
            :b => " ",
          },
        ]
        painted_table = render_string(
          rows: painted_rows,
          title: Paint["xyzzy", :blue]
        ).split("\n")

        raw_table = render_string.split("\n")

        # test title, header and data lines (indices: 1=title, 3=header, 5=data)
        [1, 3, 5].each do |i|
          raw_row = raw_table[i]
          painted_row = painted_table[i]

          # ansi codes should be balanced
          close_codes = painted_row.scan("\e[0m").length
          open_codes = painted_row.scan(/\e\[[1-9]\d*m/).length
          assert_equal(
            open_codes,
            close_codes,
            "Row #{i} should have balanced ANSI codes"
          )

          # calculate ansi codes length
          ansi_codes = painted_row.scan(/\e\[\d*m/)
          actual_ansi_length = ansi_codes.join.length

          assert_equal(
            raw_row.length + actual_ansi_length,
            painted_row.length,
            "Row #{i}: painted row should be raw row length + ANSI codes length"
          )

          # stripped length should match raw table
          cleaned_row = TableTennis::Util::Strings.unpaint(painted_row)
          assert_equal(
            raw_row.length,
            cleaned_row.length,
            "Row #{i}: cleaned row should match raw row length"
          )
        end
      end

      protected

      def create_render(color: false, rows: nil, separators: true, theme: nil, title: "xyzzy")
        rows ||= [{a: "1", b: " "}]
        config = Config.new(color:, separators:, theme:, title:)
        data = TableData.new(config:, rows:)
        if data.columns.length >= 2
          data.columns[0].width = 3
          data.columns[1].width = 3
        end
        Render.new(data)
      end

      def render_string(color: false, rows: nil, separators: true, theme: nil, title: "xyzzy")
        render = create_render(color:, rows:, separators:, theme:, title:)
        render_to_string(render)
      end

      def render_to_string(render)
        StringIO.new.tap { render.run(_1) }.string
      end
    end
  end
end
