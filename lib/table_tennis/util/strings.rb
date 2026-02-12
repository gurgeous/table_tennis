module TableTennis
  module Util
    # Helpers for measuring and truncating strings.
    module Strings
      prepend MemoWise

      module_function

      ANSI_CODE = /\e\[[0-9;]*m/

      # does this string contain ansi codes?
      def painted?(str) = str.match?(/\e/)

      # strip ansi codes
      def unpaint(str) = str.gsub(ANSI_CODE, "")

      # similar to rails titleize
      def titleize(str)
        str = str.gsub(/_id$/, "") # remove _id
        str = str.tr("_", " ") # remove underscores
        str = str.gsub(/(\w)([A-Z])/, '\1 \2') # OneTwo => One Two
        str = str.split.map(&:capitalize).join(" ") # capitalize
        str
      end

      # measure width of text, with support for emojis, painted/ansi strings, etc
      def width(str)
        if simple?(str)
          str.length
        elsif painted?(str)
          unpaint(str).length
        else
          Unicode::DisplayWidth.of(str)
        end
      end

      # center text, like String#center but works with painted strings
      def center(str, width)
        # artificially inflate width to include escape codes
        if painted?(str)
          width += str.length - unpaint(str).length
        end
        str.center(width)
      end

      def hyperlink(str)
        # fail fast, for speed
        return unless str.length >= 6 && str[0] == "["
        if str =~ /^\[(.*)\]\((.*)\)$/
          [$1, $2]
        end
      end

      ELLIPSIS = "…"
      TRIM = /\A(\e\[[0-9;]*m|\u200B)*\z/

      # Truncate a string based on the display width of characters. Does not
      # attempt to handle graphemes. Should handle emojis and international
      # characters. Painted strings too.
      def truncate(str, stop)
        if str.bytesize <= stop
          str
        elsif simple?(str)
          (str.length <= stop) ? str : "#{str[0, stop - 1]}#{ELLIPSIS}"
        else
          truncate0(str, stop)
        end
      end

      # This is a slower truncate to handle ansi colors and wide characters like
      # emojis. Inspired by piotrmurach/strings-truncation
      def truncate0(text, stop)
        [].tap do |buf|
          scan, len, painting = StringScanner.new(text), 0, false
          until scan.eos?
            # are we looking at an ansi code?
            if scan.scan(ANSI_CODE)
              painting = scan.matched != Paint::NOTHING
              buf << scan.matched
              next
            end

            # what's next?
            ch = scan.getch
            len += Unicode::DisplayWidth.of(ch)

            # done?
            if len >= stop
              buf << (scan.check(TRIM) ? ch : ELLIPSIS)
              break
            end

            buf << ch
          end
          buf << Paint::NOTHING if painting
        end.join
      end
      private_class_method :truncate0

      # note that escape \e (0x1b) is excluded
      SIMPLE = /\A[\x00-\x1a\x1c-\x7F–—…·‘’“”•áéíñóúÓ]*\Z/

      # Is this a "simple" string? (no emojis, etc). Caches results for small
      # strings for performance reasons.
      def simple?(str)
        if str.length <= 8
          @simple ||= Hash.new { _1[_2] = _2.match?(SIMPLE) }
          @simple[str]
        else
          str.match?(SIMPLE)
        end
      end
      private_class_method :simple?
    end
  end
end
