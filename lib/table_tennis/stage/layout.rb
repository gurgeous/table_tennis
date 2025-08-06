module TableTennis
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

      FUDGE = 2

      # Fit columns into terminal width. This is copied from the very simple HTML
      # table column algorithm. Returns a hash of column name to width.
      def autolayout
        # set provisional widths
        columns.each { _1.width = _1.measure }

        # How much space is available, and do we already fit?
        screen_width = Util::Console.winsize[1]
        available = screen_width - chrome_width - FUDGE
        return if available >= data_width

        # We don't fit, so we are going to shrink (truncate) some columns.
        # Potentially all the way down to a lower bound. But what is the lower
        # bound? It's nice to have a generous value so that narrow columns have
        # a shot at avoiding truncation. That isn't always possible, though.
        lower_bound = (available / columns.length).clamp(2, 10)

        # Calculate a "min" and a "max" for each column, then allocate available
        # space proportionally to each column. This is similar to the algorithm
        # for HTML tables.
        min = max = columns.map(&:width)
        min = min.map { [_1, lower_bound].min }

        # W = difference between the available space and the minimum table width
        # D = difference between maximum and minimum table width
        # ratio = W / D
        # col.width = col.min + ((col.max - col.min) * ratio)
        ratio = (available - min.sum).to_f / (max.sum - min.sum)
        if ratio <= 0
          # even min doesn't fit, we gotta overflow
          columns.each.with_index { _1.width = min[_2] }
          return
        end
        columns.zip(min, max).each do |column, min, max|
          column.width = min + ((max - min) * ratio).to_i
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
