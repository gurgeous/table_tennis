module TableTennis
  module Stage
    # This stage "paints" the table by calculating the style for cells, rows and
    # columns. The styles are stuffed into `data.set_style`. Later, the
    # rendering stage can apply them if color is enabled.
    #
    # A "style" is either:
    #
    # - a theme symbol (like :title or :chrome)
    # - hex colors, for color scaling
    #
    # Other kinds of styles are theoretically possible but not tested.
    class Painter < Base
      def_delegators :data, :set_style

      def run
        return if !config.color
        paint_title if config.title
        paint_headers
        paint_row_numbers if config.row_numbers
        paint_rows if config.mark || config.zebra
        paint_columns if config.color_scales
        paint_placeholders
      end

      protected

      #
      # helpers
      #

      def paint_title
        set_style(r: :title, style: :title)
      end

      NHEADER_COLORS = 6

      def paint_headers
        columns.each.with_index do |column, c|
          set_style(r: :header, c:, style: :"header#{c % Theme::NHEADER_COLORS}")
        end
      end

      def paint_row_numbers
        set_style(c: 0, style: :chrome)
      end

      def paint_rows
        rows.each_index do |r|
          style = nil
          if config.zebra? && r.even?
            style = :zebra
          end
          if (user_mark = config.mark&.call(input_rows[r]))
            style = mark_style(user_mark)
          end
          set_style(r:, style:) if style
        end
      end

      # This is the main entry point for color scales. Color scaling is pretty simple.
      # Scale.interpolate uses a `t` param to interpolate between the gradient colors. We pick a "t"
      # for each cell to get the right color. For numeric columns, this is easy: t = (cell_value -
      # min) / (max - min). For non-numeric columns, we do roughly the same thing but we pick
      # "cell_value" by creating a sorted list of all cells in the column, then using the position
      # of each string as the cell value. So if the column contained A..Z, A would bend up being t=0
      # and Z would be t=1.
      def paint_columns
        columns.each.with_index do |column, c|
          if (scale = config.color_scales[column.name])
            if column.type == :float || column.type == :int
              scale_numeric(c, scale)
            else
              scale_non_numeric(c, scale)
            end
          end
        end
      end

      def paint_placeholders
        rows.each.with_index do |row, r|
          row.each.with_index do |value, c|
            if value == config.placeholder
              set_style(r:, c:, style: :chrome)
            end
          end
        end
      end

      #
      # helpers
      #

      def scale_numeric(c, scale)
        # focus on rows that contain values
        focus = rows.select { Util::Identify.number?(_1[c]) }
        return if focus.length < 2 # edge case
        floats = focus.map { _1[c].delete(",").to_f }

        # find a "t" for each row
        min, max = floats.minmax
        return if min == max # edge case
        t = floats.map { (_1 - min) / (max - min) }

        # now interpolate
        scale(c, scale, focus, t)
      end

      def scale_non_numeric(c, scale)
        # focus on rows that contain values
        focus = rows.select { _1[c] != config.placeholder }

        # find a "t" for each row. since this column is non-numeric, we create a sorted list of all
        # values in the column and use the position of each cell value to calculate t. So if the
        # column contained A..Z, A would end up being t=0 and Z would be t=1.
        all_values = focus.map { _1[c] }.uniq.sort
        return if all_values.length < 2 # edge case
        all_values = all_values.map.with_index do |value, ii|
          t = ii.to_f / (all_values.length - 1)
          [value, t]
        end.to_h
        t = focus.map { all_values[_1[c]] }

        # now interpolate
        scale(c, scale, focus, t)
      end

      # interpolate column c to paint a color scale
      def scale(c, scale, rows, t)
        rows.map(&:r).zip(t).each do |r, t|
          bg = Util::Scale.interpolate(scale, t)
          fg = Util::Colors.contrast(bg)
          set_style(r:, c:, style: [fg, bg])
        end
      end

      def mark_style(user_mark)
        case user_mark
        when String, Symbol
          # pick a nice fg color
          [Util::Colors.contrast(user_mark), user_mark]
        when Array
          # a Paint array
          user_mark
        else; :mark # default
        end
      end
    end
  end
end
