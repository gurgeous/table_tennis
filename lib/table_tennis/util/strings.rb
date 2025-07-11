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
        # handle ansi codes by working with unpainted version
        work_text = text.match?(/\e\[\d*m/) ? unpaint(text) : text

        if simple?(work_text)
          truncated = (work_text.length > stop) ?
            "#{work_text[0, stop - 1]}…" :
            work_text
          return close_ansi_if_needed(truncated, text)
        end

        # get grapheme clusters, and attach zero width graphemes to the previous grapheme
        list = [].tap do |accum|
          work_text.grapheme_clusters.each do
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
          text_parts = list[0, _1]
          text_parts.pop if width - w == stop
          return close_ansi_if_needed("#{text_parts.join}…", text)
        end

        # if we get here, the text fits
        close_ansi_if_needed(work_text, text)
      end

      # helper to close ansi codes if needed
      def close_ansi_if_needed(truncated, original)
        return truncated unless original.match?(/\e\[\d*m/)

        # extract opening ANSI codes from the beginning of the original string
        opening_codes = original.scan(/^\e\[[1-9]\d*m/).join

        # if we have opening codes, wrap the truncated text with them
        if !opening_codes.empty?
          "#{opening_codes}#{truncated}\e[0m"
        else
          truncated
        end
      end
      private_class_method :close_ansi_if_needed

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
