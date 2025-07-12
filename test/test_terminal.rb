require_relative "test_helper"

class TestTerminal < Minitest::Test
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
    result = terminal.with_console("fallback") { "success" }
    assert_equal "fallback", result
  end

  def test_singleton_and_factory_methods
    # Singleton behavior
    TableTennis::Terminal.instance_variable_set(:@current, nil)
    terminal1 = TableTennis::Terminal.current
    terminal2 = TableTennis::Terminal.current
    assert_same terminal1, terminal2

    # Null terminal
    terminal = TableTennis::Terminal.null
    assert_nil terminal.console
    refute terminal.available?
  end
end
