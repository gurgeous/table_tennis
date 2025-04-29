module TableTennis
  # This class contains the current theme, as well as the definitions for all
  # themes.
  class Theme
    prepend MemoWise

    RESET = Paint::NOTHING
    OSC_8 = "\e]8;;"
    ST = "\e\\"

    NHEADER_COLORS = 6
    THEMES = {
      dark: {
        title: ["blue-400", :bold],
        chrome: "gray-500",
        cell: "gray-200",
        header0: ["#ff6188", :bold],
        header1: ["#fc9867", :bold],
        header2: ["#ffd866", :bold],
        header3: ["#a9dc76", :bold],
        header4: ["#78dce8", :bold],
        header5: ["#ab9df2", :bold],
        mark: %w[white blue-500],
        search: %w[black yellow-300],
        zebra: %w[white #222],
      },
      light: {
        title: ["blue-600", :bold],
        chrome: "#bbb",
        cell: "gray-800",
        header0: ["#ee4066", :bold],
        header1: ["#da7645", :bold],
        header2: ["#ddb644", :bold],
        header3: ["#87ba54", :bold],
        header4: ["#56bac6", :bold],
        header5: ["#897bd0", :bold],
        mark: %w[white blue-500],
        search: %w[black yellow-300],
        zebra: %w[black gray-200],
      },
      ansi: {
        title: %i[green bold],
        chrome: %i[faint default],
        cell: :default,
        header0: nil, # not supported
        header1: nil, # not supported
        header2: nil, # not supported
        header3: nil, # not supported
        header4: nil, # not supported
        header5: nil, # not supported
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

    # use osc 8 to create a terminal hyperlink. underline too
    def link(str, link)
      linked = "#{OSC_8}#{link}#{ST}#{str}#{OSC_8}#{ST}"
      # underline if aren't on iterm
      linked = Paint[linked, :underline] if term_program != :iterm
      linked
    end

    def term_program
      if ENV["TERM_PROGRAM"] == "iTerm.app"
        :iterm
      end
    end
    memo_wise :term_program

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
