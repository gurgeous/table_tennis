module TableTennis
  module Stage
    # This is the final stage of the rending pipeline - take our layout
    # information, the table cells, and the painted styles to render the table
    # as a string. This is the slowest part of rendering since there is a lot of
    # ansi/string manipulation.
    #
    # This is also where config.search is applied.
    class Render < Base
      BOX = [
        "╭─┬─╮", # 0
        "│ │ │", # 1
        "├─┼─┤", # 2
        "╰─┴─╯", # 3
      ]

      # take these from BOX
      NW, N, NE = BOX[0].chars.values_at(0, 2, 4)
      W, C, E = BOX[2].chars.values_at(0, 2, 4)
      SW, S, SE = BOX[3].chars.values_at(0, 2, 4)

      # horizontal and vertical lines
      BAR, PIPE = BOX[0][1], BOX[1][0]

      def run(io)
        # edge case - empty
        if rows.empty? || columns.empty?
          io.puts render_empty
          return
        end

        if config.title
          io.puts render_separator(NW, BAR, NE)
          io.puts render_title
          io.puts render_separator(W, N, E) if config.separators
        else
          io.puts render_separator(NW, N, NE)
        end
        io.puts render_row(:header)
        io.puts render_separator(W, C, E) if config.separators
        rows.each_index { io.puts render_row(_1) }
        io.puts render_separator(SW, S, SE)
      end

      #
      # render different parts of the table
      #

      def render_title
        title_width = data.table_width - 4
        title = Util::Strings.truncate(config.title, title_width)
        title_style = data.get_style(r: :title) || :cell
        line = paint(Util::Strings.center(title, title_width), title_style || :cell)
        paint("#{pipe} #{line} #{pipe}", Theme::BG)
      end

      def render_row(r)
        row_style = data.get_style(r:)

        # assemble line by rendering cells
        enum = (r != :header) ? rows[r].each : columns.map(&:header)
        joiner = config.separators ? " #{pipe} " : "  "
        line = enum.map.with_index do |value, c|
          render_cell(value, r, c, row_style)
        end.join(joiner)
        line = "#{pipe} #{line} #{pipe}"

        # afterward, apply row color
        paint(line, row_style || Theme::BG)
      end

      def render_cell(value, r, c, default_cell_style)
        # calculate whitespace based on plaintext
        whitespace = columns[c].width - Util::Strings.width(value)

        # cell > column > default > cell (row styles are applied elsewhere)
        style = nil
        style ||= data.get_style(r:, c:)
        style ||= data.get_style(c:)
        style ||= default_cell_style
        style ||= :cell

        # add ansi codes for search
        value = search_cell(value) if search

        # add ansi codes for links
        if config.color && (link = data.links[[r, c]])
          value = theme.link(value, link)
        end

        # pad and paint
        if whitespace > 0
          spaces = " " * whitespace
          value = if columns[c].alignment == :left
            "#{value}#{spaces}"
          else
            "#{spaces}#{value}"
          end
        end
        paint(value, style)
      end

      def render_separator(l, m, r)
        m = "" if !config.separators
        line = [].tap do |buf|
          columns.each.with_index do |column, c|
            buf << ((c == 0) ? l : m)
            buf << (BAR * (column.width + 2))
          end
          buf << r
        end.join
        paint(paint(line, :chrome), Theme::BG)
      end

      def render_empty
        title, body = config.title || "empty table", "no data"
        width = [title, body].map(&:length).max

        # helpers
        sep_row = ->(l, c, r) do
          paint("#{l}#{c * (width + 2)}#{r}", :chrome)
        end
        text_row = ->(str, style) do
          inner = paint(str.center(width), style)
          paint("#{pipe} #{inner} #{pipe}", Theme::BG)
        end

        # go
        [].tap do
          _1 << sep_row.call(NW, BAR, NE)
          _1 << text_row.call(title, data.get_style(r: :title) || :cell)
          _1 << sep_row.call(W, BAR, E)
          _1 << text_row.call(body, :chrome)
          _1 << sep_row.call(SW, BAR, SE)
        end.join("\n")
      end

      #
      # helpers
      #

      def paint(str, style)
        # delegate painting to the theme, if color is enabled
        str = theme.paint(str, style) if config.color
        str
      end

      def pipe = paint(PIPE, :chrome)
      memo_wise :pipe

      def search
        case config.search
        when String then /#{Regexp.escape(config.search)}/i
        when Regexp then config.search
        end
      end
      memo_wise :search

      # add ansi codes for search
      def search_cell(value)
        return value if !value.match?(search)
        # edge case - we can't gsub a painted cell, it can mess up the escaping
        value = Util::Strings.unpaint(value)
        value.gsub(search) { paint(_1, :search) }
      end
    end
  end
end
