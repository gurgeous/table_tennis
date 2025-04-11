module TableTennis
  module Util
    class TestString < Minitest::Test
      def test_unpaint
        assert_equal "foobar", Strings.unpaint("foo\e[123;mbar")
      end

      def test_width
        assert_equal 0, Strings.width("")
        assert_equal 1, Strings.width("a")
        assert_equal 4, Strings.width("🚀🚀")
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

      def test_difficult_unicode
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

      def test_grapheme_clusters
        # DisplayWidth thinks each hand is 4 wide for some reason. Doesn't
        # really matter for our test, though
        hands = "👋🏻👋🏿" # \u1f44b\u1f3fb and then \u1f44b\u1f3ff
        (1..3).each { assert_equal "…", Strings.truncate(hands, _1) }
        (4..7).each { assert_equal "👋🏻…", Strings.truncate(hands, _1) }
        (8..9).each { assert_equal "👋🏻👋🏿", Strings.truncate(hands, _1) }
      end
    end
  end
end
