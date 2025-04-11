module TableManners
  module Stage
    # This stage figures out how wide each column should be. Most of the fun is
    # in the autolayout behavior, which tries to fill the terminal without
    # overflowing. Once we know the column sizes, it will go ahead and truncate
    # the cells if necessary.
    class Layout < Base
      def_delegators :data, :chrome_width, :data_width

      def run
        # did the user specify a layout strategy?
        if config.layout
          case config.layout
          when true then autolayout
          when Hash then columns.each { _1.width = config.layout[_1.name] }
          when Integer then columns.each { _1.width = config.layout }
          end
        end

        # fill in missing widths, and truncate if necessary
        columns.each do
          _1.width ||= _1.measure
          _1.truncate(_1.width) if config.layout
        end
      end

      #
      # some math
      #

      AUTOLAYOUT_MIN_COLUMN_WIDTH = 2
      AUTOLAYOUT_FUDGE = 2

      # Fit columns into terminal width. This is copied from the very simple HTML
      # table column algorithm. Returns a hash of column name to width.
      def autolayout
        # set provisional widths
        columns.each { _1.width = _1.measure }

        # how much space is available, and do we already fit?
        screen_width = IO.console.winsize[1]
        available = screen_width - chrome_width - AUTOLAYOUT_FUDGE
        return if available >= data_width

        # min/max column widths, which we use below
        min = columns.map { [_1.width, AUTOLAYOUT_MIN_COLUMN_WIDTH].min }
        max = columns.map(&:width)

        # W = difference between the available space and the minimum table width
        # D = difference between maximum and minimum width of the table
        w = available - min.sum
        d = max.sum - min.sum

        # edge case if we don't even have enough room for min
        if w <= 0
          columns.each.with_index { _1.width = min[_2] }
          return
        end

        # expand min to fit available space
        columns.each.with_index do
          # width = min + (delta * W / D)
          _1.width = min[_2] + ((max[_2] - min[_2]) * w / d.to_f).to_i
        end

        # because we always round down, there might be some extra space to distribute
        if (extra_space = available - data_width) > 0
          distribute = columns.sort_by.with_index do |_, c|
            [-(max[c] - min[c]), c]
          end
          distribute[0, extra_space].each { _1.width += 1 }
        end
      end
    end
  end
end
