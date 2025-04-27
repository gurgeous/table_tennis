module TableTennis
  class TestTheme < Minitest::Test
    def test_theme_keys
      Theme::THEMES.each_value { assert_equal Theme::THEME_KEYS, _1.keys }
    end

    def test_codes
      t = Theme.new(:dark)
      [
        # ansi
        [:red, "\e[31m"],
        [[:red], "\e[31m"],
        [%i[red blue], "\e[31;44m"],
        # hex
        ["#fff", "\e[38;2;255;255;255m"],
        ["#ff8822", "\e[38;2;255;136;34m"],
        # named colors
        ["green", "\e[38;2;0;128;0m"],
        # theme
        [:zebra, "\e[38;2;255;255;255;48;2;34;34;34m"],
      ].each do |value, exp|
        assert_equal exp, t.codes(value), "for #{value.inspect}"
      end
    end

    def test_paint
      t = Theme.new(:dark)
      assert_equal "foo", t.paint("foo", nil)
      assert_output(/unknown/) { assert_equal "foo", t.paint("foo", :bogus) }
      assert_output(/unknown/) { assert_equal "foo", t.paint("foo", "bogus") }

      # simple
      reset, codes = "\e[0m", t.codes(:chrome)
      assert_equal "#{codes}FOO#{reset}", t.paint("FOO", :chrome)
      # nested
      assert_equal "#{codes}FOO#{codes}BAR#{reset}#{codes}BAZ#{reset}", t.paint("FOO#{codes}BAR#{reset}BAZ", :chrome)
    end

    def test_info
      assert_no_raises { Theme.info }
    end
  end
end
