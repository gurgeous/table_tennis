module TableTennis
  # This class contains the current theme, as well as the definitions for all
  # themes.
  class Theme
    prepend MemoWise

    RESET = Paint::NOTHING
    THEMES = {
      dark: {
        title: "#7f0",
        chrome: "gray-500",
        cell: "gray-200",
        mark: %w[white blue-500],
        search: %w[black yellow-300],
        zebra: %w[white #333],
      },
      light: {
        title: "blue-600",
        chrome: "#bbb",
        cell: "gray-800",
        mark: %w[white blue-500],
        search: %w[black yellow-300],
        zebra: %w[black gray-200],
      },
      ansi: {
        title: :green,
        chrome: %i[faint default],
        cell: :default,
        mark: %i[white blue],
        search: %i[white magenta],
        zebra: nil, # not supported
      },
    }
    THEME_KEYS = THEMES[:dark].keys
    BG = [nil, :default]

    attr_reader :name

    def initialize(name)
      @name = name
      raise ArgumentError, "unknown theme #{name}, should be one of #{THEMES.keys}" if !THEMES.key?(name)
    end

    # Value is one of the following:
    # - theme.symbol (like ":title")
    # - a color that works with Colors.get (#fff, or :bold, or "steelblue")
    # - an array of colors
    def codes(value)
      # theme key?
      if value.is_a?(Symbol) && THEME_KEYS.include?(value)
        value = THEMES[name][value]
      end
      # turn value(s) into colors
      colors = Array(value).map { Util::Colors.get(_1) }
      return if colors == [] || colors == [nil]

      # turn colors into ansi codes
      Paint["", *colors].gsub(RESET, "")
    end
    memo_wise :codes

    # Apply colors to a string. Value is one of the following:
    # - theme.symbol (like ":title")
    # - a color that works with Colors.get (#fff, or :bold, or "steelblue")
    # - an array of colors
    def paint(str, value)
      # cap memo_wise
      @_memo_wise[__method__].tap { _1.clear if _1.length > 5000 }

      if (codes = codes(value))
        str = str.gsub(RESET, "#{RESET}#{codes}")
        str = "#{codes}#{str}#{RESET}"
      end
      str
    end
    memo_wise :paint

    # for debugging, mostly
    def self.info
      sample = if !Config.detect_color?
        "(color is disabled)"
      elsif Config.detect_theme == :light
        Paint[" light theme ", "#000", "#eee", :bold]
      elsif Config.detect_theme == :dark
        Paint[" dark theme ", "#fff", "#444", :bold]
      end

      {
        detect_color?: Config.detect_color?,
        detect_theme: Config.detect_theme,
        sample:,
        terminal_dark?: Config.terminal_dark?,
      }.merge(Util::Termbg.info)
    end
  end
end
