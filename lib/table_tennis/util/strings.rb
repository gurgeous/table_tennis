module TableTennis
  module Util
    # Helpers for measuring and truncating strings.
    module Strings
      prepend MemoWise

      module_function

      # does this string contain ansi codes?
      def painted?(str) = str.match?(/\e/)

      # strip ansi codes
      def unpaint(str) = str.gsub(/\e\[[0-9;]*m/, "")

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

      # Truncate a string based on the display width of characters. Does not
      # attempt to handle graphemes. Should handle emojis and international
      # characters. Painted strings too.
      def truncate(str, stop)
        if str.bytesize <= stop
          str
        elsif simple?(str)
          (str.length > stop) ? "#{str[0, stop - 1]}…" : str
        else
          truncate0(str, stop)
        end
      end

      # slow, but handles ansi colors and wide characters. inspired by
      # piotrmurach/strings-truncation
      def truncate0(text, stop)
        # puts
        buf, len, painting = [], 0, false
        scan = StringScanner.new(text)
        until scan.eos?
          if scan.scan("\e[0m")
            # puts "RESET"
            buf << scan.matched
            painting = false
          elsif scan.scan(/\e\[[0-9;]*m/)
            # puts "ANSI - #{scan.matched.inspect}"
            buf << scan.matched
            painting = true
          else
            ch = scan.getch
            chw = Unicode::DisplayWidth.of(ch)
            # puts "CH #{ch.inspect}"
            if (len += chw) >= stop
              ch = "…" unless scan.check(/\A(\e\[[0-9;]*m|\u200B)*\z/)
              buf << ch
              break
            end
            buf << ch
          end
        end
        buf << Paint::NOTHING if painting
        buf.join
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
