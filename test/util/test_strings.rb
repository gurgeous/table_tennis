module TableTennis
  module Util
    class TestString < Minitest::Test
      PLAIN = "foobar"
      GREEN = "\e[38;2;0;255;0mfoobar\e[0m"

      def test_painted?
        assert !Strings.painted?(PLAIN)
        assert Strings.painted?(GREEN)
      end

      def test_unpaint
        assert_equal PLAIN, Strings.unpaint(GREEN)
      end

      def test_width
        assert_equal 0, Strings.width("")
        assert_equal 1, Strings.width("a")
        assert_equal 4, Strings.width("🚀🚀")
        assert_equal 6, Strings.width(PLAIN)
        # ansi
        assert_equal 6, Strings.width(GREEN)
      end

      def test_center
        assert_equal " foobar ", Strings.center(PLAIN, 8)
        assert_equal " #{GREEN} ", Strings.center(GREEN, 8)
      end

      def test_truncate
        zed = "\u200B"

        # pepper is display width 1, rocket is display width 2
        # these don't get truncated
        [
          "", "abc", "café", zed, "🌶", "🚀",
          # display width is 5
          "abcde",
          "1#{zed}2345#{zed}",
          "1🌶345",
          "1🚀45",
          "1🚀🚀",
        ].each do
          assert_equal _1, Strings.truncate(_1, 5)
        end

        # display width > 5
        assert_equal "1234…", Strings.truncate("123456", 5)
        assert_equal "“caf…", Strings.truncate("“café6", 5)
        assert_equal "#{zed}1#{zed}234#{zed}…", Strings.truncate("#{zed}1#{zed}234#{zed}5#{zed}6", 5)
        assert_equal "🌶2🌶4…", Strings.truncate("🌶2🌶4🌶6", 5)
        assert_equal "🌶🌶🌶🌶…", Strings.truncate("🌶🌶🌶🌶🌶🌶", 5)
        assert_equal "🚀🚀…", Strings.truncate("🚀🚀🚀🚀🚀", 5)
        assert_equal "🚀3…", Strings.truncate("🚀3🚀6", 5)
      end

      def test_truncate_difficult_unicode
        difficult = [
          "\u200f\u200e\u200e\u200f", # rtl,ltr,ltr,rtl marks
          "\u0635\u0648\u0631", # arabic sad, wah, reh
        ].join

        s1 = Strings.truncate(difficult, 1)
        s2 = Strings.truncate(difficult, 2)
        s3 = Strings.truncate(difficult, 3)
        s4 = Strings.truncate(difficult, 4)

        assert_equal 5, s1.length
        assert_equal 6, s2.length
        assert_equal 7, s3.length
        assert_equal 7, s4.length

        # uprint = ->(str) { str.chars.map { "\\u#{_1.ord.to_s(16)}" }.join.gsub("\\u2026", "…") }
        # strip rtl/ltr marks for easy comparison here
        del_rtl_ltr = ->(str) { str.gsub(/[\u200e-\u200f]/, "") }
        assert_equal "…", del_rtl_ltr.call(s1)
        assert_equal "ص…", del_rtl_ltr.call(s2)
        assert_equal "صور", del_rtl_ltr.call(s3)
        assert_equal "صور", del_rtl_ltr.call(s4)
      end

      def test_truncate_grapheme_clusters
        hands = "👋🏻👋🏿" # \u1f44b\u1f3fb and then \u1f44b\u1f3ff
        # hardcode since this can change based on the font
        Unicode::DisplayWidth.stubs(:of).returns(2)

        (1..2).each { assert_equal "…", Strings.truncate(hands, _1), "with #{_1}" }
        (3..3).each { assert_equal "👋🏻…", Strings.truncate(hands, _1), "with #{_1}" }
        (4..6).each { assert_equal "👋🏻👋🏿", Strings.truncate(hands, _1), "with #{_1}" }
      end

      def test_truncate_painted
        assert_equal "fo…", Strings.truncate(PLAIN, 3)
        assert_equal "\e[38;2;0;255;0mfo…\e[0m", Strings.truncate(GREEN, 3)

        # test that ANSI codes are properly closed when truncated
        colored_text = Paint["hello world", :red]
        # when truncated in the middle, preserve and close color
        result = Strings.truncate(colored_text, 7)
        assert_equal "\e[31mhello …\e[0m", result
        # when not truncated, should preserve original
        result = Strings.truncate(colored_text, 15)
        assert_equal colored_text, result
        # test with unclosed ANSI code
        unclosed_text = "\e[31mhello world"
        result = Strings.truncate(unclosed_text, 7)
        assert_equal "\e[31mhello …\e[0m", result
        # test with emojis and color:
        # rocket=2, pepper=1, h=1, ellipsis=1 = 5 total
        emoji_colored_text = Paint["🚀🌶hello", :blue]
        result = Strings.truncate(emoji_colored_text, 5)
        assert_equal "\e[34m🚀🌶h…\e[0m", result
        # test shorter truncation:
        # rocket=2, pepper=1, ellipsis=1 = 4 total
        result = Strings.truncate(emoji_colored_text, 4)
        assert_equal "\e[34m🚀🌶…\e[0m", result
        # test longer emoji text with color:
        # rocket=2, pepper=1, party=2, h=1, ellipsis=1 = 7 total
        long_emoji_text = Paint["🚀🌶🎉hello world", :green]
        result = Strings.truncate(long_emoji_text, 7)
        assert_equal "\e[32m🚀🌶🎉h…\e[0m", result
      end

      def test_titleize
        [
          ["action", "Action"],
          ["action_id", "Action"],
          ["created_at", "Created At"],
          ["serp_total_time", "Serp Total Time"],
          ["serp time", "Serp Time"],
          ["SerpTime", "Serp Time"],
        ].each do |str, exp|
          assert_equal exp, Strings.titleize(str)
        end
      end
    end
  end
end
