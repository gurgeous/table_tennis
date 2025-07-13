require_relative "test_helper"

class TestTerminal < Minitest::Test
  SUCCESS_STR = ["\e];rgb:ffff/8888/2222\e\\", "\e[1;2R"].join
  SUCCESS_BYTES = SUCCESS_STR.bytes

  def console = IO.console

  def test_main
    if windows?
      terminal = TableTennis::Terminal.new
      terminal.stubs(:osc_supported?).returns(false)
      assert !terminal.send(:osc_supported?)
      return
    end

    terminal = TableTennis::Terminal.new
    terminal.stubs(:in_foreground?).returns(true)
    console.fakeread.concat(SUCCESS_BYTES)
    assert_equal "#ff8822", terminal.fg
    console.fakeread.concat(SUCCESS_BYTES)
    assert_equal "#ff8822", terminal.bg

    assert_no_raises { terminal.info }
  end

  def test_fg_fallback
    terminal = TableTennis::Terminal.new
    terminal.stubs(:osc_query).with(10)
    terminal.stubs(:env_colorfgbg).returns([123, 456])
    assert_equal 123, terminal.fg
  end

  def test_bg_fallback
    terminal = TableTennis::Terminal.new
    terminal.stubs(:osc_query).with(11)
    terminal.stubs(:env_colorfgbg).returns([123, 456])
    assert_equal 456, terminal.bg
  end

  def test_fgbg_fallback
    terminal = TableTennis::Terminal.new
    terminal.stubs(:osc_query)
    terminal.stubs(:env_colorfgbg)
    assert_equal [nil, nil], [terminal.fg, terminal.bg]
  end

  def test_env_colorfgbg
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.send(:env_colorfgbg, nil)
    assert_nil terminal.send(:env_colorfgbg, "bogus")
    assert_equal ["#ffffff", "#000000"], terminal.send(:env_colorfgbg, "15;0")
    assert_equal ["#000000", "#ffffff"], terminal.send(:env_colorfgbg, "0;15")
  end

  def test_in_foreground?
    [
      [-1, 999, nil],
      [123, 456, false],
      [123, 123, true],
    ].each do |tcgetpgrp, getpgrp, exp|
      terminal = TableTennis::Terminal.new
      terminal.reset_memo_wise
      terminal.stubs(:tcgetpgrp).returns(tcgetpgrp)
      Process.stubs(:getpgrp).returns(getpgrp)
      assert_equal exp, terminal.send(:in_foreground?)
    end
  end

  def test_osc_query
    terminal = TableTennis::Terminal.new
    terminal.stubs(:osc_supported?).returns(false)
    assert !terminal.send(:osc_query, 99)
    terminal.stubs(:osc_supported?).returns(true)
    assert console.fakewrite.length == 0

    terminal.stubs(:in_foreground?).returns(false)
    assert !terminal.send(:osc_query, 99)
    terminal.stubs(:in_foreground?).returns(true)
    assert console.fakewrite.length == 0

    # invalid response
    terminal.stubs(:read_term_response)
    assert !terminal.send(:osc_query, 99)
    assert_equal "\e]99;?\a\e[6n", console.fakewrite.string

    # no OSC response
    terminal.stubs(:read_term_response).returns("xx\e[xxR")
    assert !terminal.send(:osc_query, 99)

    # success!
    terminal.stubs(:read_term_response).returns(SUCCESS_STR)
    assert_equal "#ff8822", terminal.send(:osc_query, 123)
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
        terminal = TableTennis::Terminal.new
        assert_equal _1[:exp], terminal.send(:osc_supported?)
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
      terminal = TableTennis::Terminal.new
      assert_equal exp, terminal.send(:read_term_response)
      assert console.fakeread.empty?
    end
  end

  def test_decode_osc_response
    terminal = TableTennis::Terminal.new(nil)
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
      assert_equal _1[:exp], terminal.send(:decode_osc_response, _1[:str])
    end
  end

  # Test Terminal methods

  def test_default_width_constant
    assert_equal 80, TableTennis::Terminal::DEFAULT_WIDTH
  end

  def test_initialization_with_and_without_console
    # With console
    fake_console = FakeConsole.new
    terminal = TableTennis::Terminal.new(fake_console)
    assert_equal fake_console, terminal.console
    assert terminal.available?

    # Without console
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.console
    refute terminal.available?

    # Auto-detection
    terminal = TableTennis::Terminal.new
    assert_instance_of FakeConsole, terminal.console
    assert terminal.available?
  end

  def test_width_with_fallback_behavior
    # Normal case
    terminal = TableTennis::Terminal.new
    assert_equal 80, terminal.width

    # Without console - uses default
    terminal = TableTennis::Terminal.new(nil)
    assert_equal 80, terminal.width

    # With error - uses default
    mock_console = mock("console")
    mock_console.expects(:winsize).raises(StandardError)
    terminal = TableTennis::Terminal.new(mock_console)
    assert_equal 80, terminal.width
  end

  def test_fileno_with_error_handling
    # With console
    terminal = TableTennis::Terminal.new
    assert_equal 123, terminal.fileno

    # Without console
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.fileno
  end

  def test_raw_operation_with_fallback
    terminal = TableTennis::Terminal.new
    result = terminal.raw_operation("fallback") { "success" }
    assert_equal "success", result

    # Without console uses fallback
    terminal = TableTennis::Terminal.new(nil)
    result = terminal.raw_operation("fallback") { "success" }
    assert_equal "fallback", result
  end

  def test_io_operations
    # Test getbyte
    terminal = TableTennis::Terminal.new
    terminal.console.fakeread << 65
    assert_equal 65, terminal.getbyte

    # Test syswrite
    terminal = TableTennis::Terminal.new
    assert terminal.syswrite("test")
    assert_equal "test", terminal.console.fakewrite.string

    # Without console
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.getbyte
    refute terminal.syswrite("test")
  end

  def test_with_console_method
    # With console
    terminal = TableTennis::Terminal.new
    result = terminal.with_console("fallback") { |console| "success" }
    assert_equal "success", result

    # Without console
    terminal = TableTennis::Terminal.new(nil)
    result = terminal.with_console("fallback") { "fallback" }
    assert_equal "fallback", result
  end

  # Fallback tests for CI environments

  def test_terminal_bg_fg_fallback
    # Test that Terminal gracefully handles when bg/fg detection fails
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.bg
    assert_nil terminal.fg
  end

  def test_terminal_info_with_nil_console
    # Test that Terminal.info works even with nil console
    terminal = TableTennis::Terminal.new(nil)
    assert_no_raises { terminal.info }
    info = terminal.info
    assert_nil info[:bg]
    assert_nil info[:fg]
    assert_nil info[:bg_luma]
  end

  def test_osc_supported_fallback
    # Test that osc_supported? works even with nil console
    terminal = TableTennis::Terminal.new(nil)
    # Should not crash, may return true or false depending on environment
    assert_no_raises { terminal.send(:osc_supported?) }
  end

  def test_in_foreground_fallback
    # Test that in_foreground? handles nil console gracefully
    terminal = TableTennis::Terminal.new(nil)
    # Should return nil when console is not available
    assert_nil terminal.send(:in_foreground?)
  end

  def test_osc_query_fallback
    # Test that osc_query handles nil console gracefully
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.send(:osc_query, 10)
    assert_nil terminal.send(:osc_query, 11)
  end

  def test_read_term_response_fallback
    # Test that read_term_response handles nil console gracefully
    terminal = TableTennis::Terminal.new(nil)
    assert_nil terminal.send(:read_term_response)
  end

  def test_ci_environment_simulation
    # Simulate CI environment where IO.console returns nil
    # This is the exact scenario that was causing the original bug
    IO.stubs(:console).returns(nil)

    # Creating a terminal with auto-detection should handle nil gracefully
    terminal = TableTennis::Terminal.new(:auto_detect)
    assert_nil terminal.console
    refute terminal.available?

    # All operations should work without throwing exceptions
    assert_equal TableTennis::Terminal::DEFAULT_WIDTH, terminal.width
    assert_nil terminal.fileno
    assert_nil terminal.bg
    assert_nil terminal.fg
    assert_nil terminal.getbyte
    refute terminal.syswrite("test")

    # This should not crash - the original bug scenario
    assert_no_raises do
      info = terminal.info
      assert_nil info[:bg]
      assert_nil info[:fg]
    end
  end
end
