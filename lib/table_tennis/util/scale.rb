module TableTennis
  module Util
    # Helpers for color scales (adding background colors to a column based on the
    # value of the float in the cell). Like conditional formattiong with a color
    # range in google sheets.
    module Scale
      prepend MemoWise

      module_function

      WHITE, GREEN, RED, YELLOW, BLUE = "#fff", "#57bb8a", "#e67c73", "ffd666", "#6c9eeb"

      SCALES = {
        # white => color
        g: [WHITE, GREEN],
        y: [WHITE, YELLOW],
        r: [WHITE, RED],
        b: [WHITE, BLUE],

        # green/yellow/red => white
        gw: [GREEN, WHITE],
        yw: [YELLOW, WHITE],
        rw: [RED, WHITE],
        bw: [BLUE, WHITE],

        # red <=> green
        rg: [RED, WHITE, GREEN],
        gr: [GREEN, WHITE, RED],
        gyr: [GREEN, YELLOW, RED],
      }

      def interpolate(name, t)
        t = t.clamp(0, 1).to_f
        stops = color_stops(name)
        rgb = if stops.first.length == 2
          stops.map { lerp(t, _1, _2) }
        elsif t < 0.5
          t *= 2
          stops.map { lerp(t, _1, _2) }
        else
          t = (t - 0.5) * 2
          stops.map { lerp(t, _2, _3) }
        end
        Colors.to_hex(rgb)
      end

      def color_stops(name)
        SCALES[name].map { Colors.to_rgb(_1) }.transpose
      end
      memo_wise self: :color_stops

      def lerp(t, v0, v1) = t * (v1 - v0) + v0
    end
  end
end
