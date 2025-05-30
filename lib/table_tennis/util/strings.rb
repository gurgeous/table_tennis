module TableTennis
  module Util
    # Helpers for measuring and truncating strings.
    module Strings
      prepend MemoWise

      module_function

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

      def width(text)
        simple?(text) ? text.length : Unicode::DisplayWidth.of(text)
      end

      def hyperlink(str)
        # fail fast, for speed
        return unless str.length >= 6 && str[0] == "["
        if str =~ /^\[(.*)\]\((.*)\)$/
          [$1, $2]
        end
      end

      # truncate a string based on the display width of the grapheme clusters.
      # Should handle emojis and international characters
      def truncate(text, stop)
        if simple?(text)
          return (text.length > stop) ? "#{text[0, stop - 1]}…" : text
        end

        # get grapheme clusters, and attach zero width graphemes to the previous grapheme
        list = [].tap do |accum|
          text.grapheme_clusters.each do
            if width(_1) == 0 && !accum.empty?
              accum[-1] = "#{accum[-1]}#{_1}"
            else
              accum << _1
            end
          end
        end

        width = 0
        list.each_index do
          w = Unicode::DisplayWidth.of(list[_1])
          next if (width += w) <= stop

          # we've gone too far. do we need to pop for the ellipsis?
          text = list[0, _1]
          text.pop if width - w == stop
          return "#{text.join}…"
        end

        text
      end

      SIMPLE = /\A[\x00-\x7F–—…·‘’“”•áéíñóúÓ]*\Z/

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
