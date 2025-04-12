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
          scale = config.color_scales[column.name]
          next if !scale

          floats = column.map { _1.to_f if _1 =~ /^-?\d+(\.\d+)?$/ }
          min, max = floats.compact.minmax
          next if min == max # edge case

          # color
          column.each_index.zip(floats).each do |r, f|
            next if !f
            t = (f - min) / (max - min)
            bg = Util::Scale.interpolate(scale, t)
            fg = Util::Colors.contrast(bg)
            set_style(r:, c:, style: [fg, bg])
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
