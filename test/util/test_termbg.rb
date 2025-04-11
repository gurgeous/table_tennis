module TableTennis
  module Util
    class TestTermbg < Minitest::Test
      SUCCESS_STR = ["\e];rgb:ffff/8888/2222\e\\", "\e[1;2R"].join
      SUCCESS_BYTES = SUCCESS_STR.bytes

      def console = IO.console

      def test_main
        if windows?
          assert !Termbg.osc_supported?
          return
        end

        Termbg.stubs(:in_foreground?).returns(true)
        console.fakeread.concat(SUCCESS_BYTES)
        assert_equal "#ff8822", Termbg.fg
        console.fakeread.concat(SUCCESS_BYTES)
        assert_equal "#ff8822", Termbg.bg

        assert_no_raises { Termbg.info }
      end

      def test_fg_fallback
        Termbg.stubs(:osc_query).with(10)
        Termbg.stubs(:env_colorfgbg).returns([123, 456])
        assert_equal 123, Termbg.fg
      end

      def test_bg_fallback
        Termbg.stubs(:osc_query).with(11)
        Termbg.stubs(:env_colorfgbg).returns([123, 456])
        assert_equal 456, Termbg.bg
      end

      def test_fgbg_fallback
        Termbg.stubs(:osc_query)
        Termbg.stubs(:env_colorfgbg)
        assert_equal [nil, nil], [Termbg.fg, Termbg.bg]
      end

      def test_env_colorfgbg
        assert_nil Termbg.send(:env_colorfgbg, nil)
        assert_nil Termbg.send(:env_colorfgbg, "bogus")
        assert_equal ["#ffffff", "#000000"], Termbg.send(:env_colorfgbg, "15;0")
        assert_equal ["#000000", "#ffffff"], Termbg.send(:env_colorfgbg, "0;15")
      end

      def test_in_foreground?
        [
          [-1, 999, nil],
          [123, 456, false],
          [123, 123, true],
        ].each do |tcgetpgrp, getpgrp, exp|
          Termbg.reset_memo_wise
          Termbg.stubs(:tcgetpgrp).returns(tcgetpgrp)
          Process.stubs(:getpgrp).returns(getpgrp)
          assert_equal exp, Termbg.send(:in_foreground?)
        end
      end

      def test_osc_query
        Termbg.stubs(:osc_supported?).returns(false)
        assert !Termbg.send(:osc_query, 99)
        Termbg.stubs(:osc_supported?).returns(true)
        assert console.fakewrite.length == 0

        Termbg.stubs(:in_foreground?).returns(false)
        assert !Termbg.send(:osc_query, 99)
        Termbg.stubs(:in_foreground?).returns(true)
        assert console.fakewrite.length == 0

        # invalid response
        Termbg.stubs(:read_term_response)
        assert !Termbg.send(:osc_query, 99)
        assert_equal "\e]99;?\a\e[6n", console.fakewrite.string

        # no OSC response
        Termbg.stubs(:read_term_response).returns("xx\e[xxR")
        assert !Termbg.send(:osc_query, 99)

        # success!
        Termbg.stubs(:read_term_response).returns(SUCCESS_STR)
        assert_equal "#ff8822", Termbg.send(:osc_query, 123)
      end

      def test_osc_supported?
        [
          # good
          {host_os: "darwin", platform: "arm64", exp: true},
          {host_os: "linux", platform: "x86_64", exp: true},
          # bad
          {host_os: "mingw32", exp: false},
          {platform: "mips", exp: false},
          {TERM: "dumb", exp: false},
          {TERM: "screen", exp: false},
          {TERM: "tmux", exp: false},
          {ZELLIJ: "1", exp: false},
        ].each do
          old_config, old_env = RbConfig::CONFIG.dup, ENV.to_h
          RbConfig::CONFIG["host_os"] = _1[:host_os] || "darwin"
          RbConfig::CONFIG["platform"] = _1[:platform] || "x86_64"
          ENV["TERM"] = _1[:TERM] || "xterm"
          ENV["ZELLIJ"] = _1[:ZELLIJ]
          begin
            assert_equal _1[:exp], Termbg.osc_supported?
          ensure
            ENV.replace(old_env)
            RbConfig::CONFIG.replace(old_config)
          end
        end
      end

      def test_read_term_response
        [
          # good
          {bytes: "\e[123R", exp: true},
          {bytes: "\e]456\a", exp: true},
          {bytes: "\e]789\e\\", exp: true},
          # cruft beforehand, but still ok
          {bytes: "xxx\e[123R", exp: "\e[123R"},
          # bad
          {bytes: ""},
          {bytes: "xxx\e[123"},
          {bytes: "xxx\ex"},
        ].each do
          exp = _1[:exp]
          exp = _1[:bytes] if exp == true
          console.fakeread.concat(_1[:bytes].bytes)
          assert_equal exp, Termbg.send(:read_term_response)
          assert console.fakeread.empty?
        end
      end

      def test_decode_osc_response
        [
          # good
          {str: ";rgb:f/8/2\e\\", exp: "#ff8822"},
          {str: ";rgb:F/8/2\a", exp: "#ff8822"},
          {str: ";rgb:ff/88/22", exp: "#ff8822"},
          {str: ";rgb:fff/888/222", exp: "#ff8822"},
          {str: ";rgb:ffff/8888/2222", exp: "#ff8822"},
          # bad
          {str: ""},
          {str: "bogus"},
          {str: ";rgb"},
          {str: ";rgb:"},
          {str: ";rgb:bogus"},
          {str: ";rgb:ff/ddff"},
          {str: ";rgb:1/2/3/4"},
          {str: ";rgb:ff/fg/ff"},
        ].each do
          assert_equal _1[:exp], Termbg.send(:decode_osc_response, _1[:str])
        end
      end
    end
  end
end
