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

      def paint_columns
        columns.each.with_index do |column, c|
          if (scale = config.color_scales[column.name])
            if column.type == :float || column.type == :int
              scale_numbers(c, scale)
            else
              scale_categories(c, scale)
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

      def scale_numbers(c, scale)
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

      def scale_categories(c, scale)
        # focus on rows that contain values
        focus = rows.select { _1[c] != config.placeholder }

        # find a "t" for each row
        categories = focus.map { _1[c] }.uniq.sort
        return if categories.length < 2 # edge case
        categories = categories.map.with_index do |category, ii|
          t = ii.to_f / (categories.length - 1)
          [category, t]
        end.to_h
        t = focus.map { categories[_1[c]] }

        # now interpolate
        scale(c, scale, focus, t)
      end

      # interpolate column c with scale, using rows+t
      def scale(c, scale, rows, t)
        rows.map(&:r).zip(t).each do |r, t|
          bg = Util::Scale.interpolate(scale, t)
          fg = Util::Colors.contrast(bg)
          set_style(r:, c:, style: [fg, bg])
        end
      end

      def mark_style(user_mark)
        case user_mark
        when String, Symbol then [nil, user_mark] # assume bg color
        when Array then user_mark # a Paint array
        else; :mark # default
        end
      end
    end
  end
end
