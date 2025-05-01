module TableTennis
  class TestConfig < Minitest::Test
    def test_basic
      assert_equal "foo", Config.new(placeholder: "foo").placeholder
      assert_equal "foo", Config.new.tap { _1.placeholder = "foo" }.placeholder
      assert_equal true, Config.new.tap { _1.zebra = 1 }.zebra
      assert_equal false, Config.new.tap { _1.zebra = "0" }.zebra?
    end

    def test_defaults
      assert_equal "—", Config.new.placeholder
      TableTennis.defaults = {placeholder: "foo"}
      assert_equal "foo", Config.new.placeholder
      assert_equal "bar", Config.new(placeholder: "bar").placeholder
      assert_equal "", Config.new(placeholder: nil).placeholder
    end

    def test_validation
      # try something we know is invalid for every option
      bad = (123..345)
      Config::OPTIONS.each_key { assert_config_raise(_1, bad) }

      # here are things that work
      assert_config_no_raise(:color, true)
      assert_config_no_raise(:color_scales, :a)
      assert_config_no_raise(:color_scales, {a: :b})
      assert_config_no_raise(:color_scales, %i[a b c])
      assert_config_no_raise(:columns, %i[a b c])
      assert_config_no_raise(:headers, {a: "hi"})
      assert_config_no_raise(:digits, 7)
      assert_config_no_raise(:layout, {a: 123})
      assert_config_no_raise(:layout, 123)
      assert_config_no_raise(:layout, false)
      assert_config_no_raise(:layout, nil)
      assert_config_no_raise(:layout, true)
      assert_config_no_raise(:mark, -> { "foo" })
      assert_config_no_raise(:placeholder, "foo")
      assert_config_no_raise(:row_numbers, true)
      assert_config_no_raise(:separators, false)
      assert_config_no_raise(:search, "foo")
      assert_config_no_raise(:search, /foo/)
      assert_config_no_raise(:strftime, "foo")
      assert_config_no_raise(:theme, :light)
      assert_config_no_raise(:title, :foo)
      assert_config_no_raise(:title, "foo")
      assert_config_no_raise(:titleize, true)
      assert_config_no_raise(:zebra, true)

      # and some things that don't
      assert_config_raise(:color_scales, "nope")
      assert_config_raise(:color_scales, {"a" => :b})
      assert_config_raise(:color_scales, {a: :nope})
      assert_config_raise(:color_scales, {a: "nope"})
      assert_config_raise(:columns, [:a, :b, "c"])
      assert_config_raise(:digits, "nope")
      assert_config_raise(:digits, -3)
      assert_config_raise(:headers, {a: 123})
      assert_config_raise(:layout, {"a" => 123})
      assert_config_raise(:layout, {a: :nope})
      assert_config_raise(:layout, "nope")
      assert_config_raise(:search, 123)
      assert_config_raise(:theme, :nope)
      assert_config_raise(:theme, "nope")
      assert_config_raise(:zebra, 123)
    end

    def test_terminal_dark?
      [
        [nil, nil, :dark],
        ["000", true, :dark],
        ["888", true, :dark],
        ["fff", false, :light],
      ].each do |bg, dark, theme|
        Util::Termbg.stubs(:bg).returns(bg)
        assert_equal dark, Config.terminal_dark?, "for bg #{bg.inspect}"
        assert_equal theme, Config.detect_theme, "for bg #{bg.inspect}"
      end
    end

    def test_detect_color
      # env overrides
      [
        ["NO_COLOR", 1, false], ["CI", 1, false], ["FORCE_COLOR", 1, true],
      ].each do |k, v, exp|
        with_env({k => v}) do
          assert_equal exp, Config.detect_color?
        end
      end

      # ttys & Paint.mode
      [
        [true, true, 123, true],
        [false, true, 123, false],
        [true, false, 123, false],
        [true, true, 0, false],
      ].each do |stdout_tty, stderr_tty, paint, exp|
        $stdout.stubs(:tty?).returns(stdout_tty)
        $stderr.stubs(:tty?).returns(stderr_tty)
        Paint.stubs(:detect_mode).returns(paint)
        assert_equal exp, Config.detect_color?
      end
    end

    protected

    def assert_config_no_raise(name, value)
      assert_no_raises { Config.new(name => value) }
    end

    def assert_config_raise(name, value)
      begin
        Config.new(name => value)
      rescue => ex
      end

      what = "Config(#{name.inspect} => #{value.inspect})"
      if !ex.is_a?(ArgumentError)
        flunk("Expected ArgumentError for #{what}, but got #{ex.inspect}")
      end
      assert_match("TableTennis::Config.#{name}", ex.message)
    end
  end
end
