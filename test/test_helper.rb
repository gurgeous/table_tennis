if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    coverage_dir "/tmp/coverage"
  end
end

require "amazing_print"
require "minitest/autorun"
require "minitest/hooks"
require "minitest/pride"
require "mocha/minitest"
require "ostruct"
require "table_tennis"

class Minitest::Test
  include Minitest::Hooks

  TMP = "#{Dir.tmpdir}/_tm_test.csv"

  def before_all = super
  def after_all = super

  def setup
    super
    {
      CI: nil,
      FORCE_COLOR: nil,
      MINITEST: 1,
      NO_COLOR: nil,
      TERM: nil,
      TT_DEBUG: nil,
      ZELLIJ: nil,
    }.each do
      ENV[_1.to_s] = _2&.to_s
    end
    File.unlink(TMP) if File.exist?(TMP)
    IO.stubs(:console).returns(FakeConsole.new)
    reset_memo_wise!
    TableTennis.defaults = nil

    # we can't do much with windows, but at least make the tests pass by
    # pretending that Paint.mode is doing something.
    Paint.mode = 0xffffff if windows?
  end

  def teardown = super

  protected

  def ab = [{a: 1, b: 2}]

  def reset_memo_wise!
    @memoized ||= ObjectSpace.each_object(Module).select { _1.included_modules.include? MemoWise } # rubocop:disable Style/ModuleMemberExistenceCheck
    @memoized.each do
      _1.reset_memo_wise if _1.instance_variable_defined?(:@_memo_wise)
    end
  end

  def assert_no_raises(msg = nil)
    yield
  rescue => ex
    flunk(msg || "assert_no_raises, but raised #{ex.inspect}")
  end

  def assert_equal(exp, act, msg = nil)
    # just a hack to workaround the assert_nil warning
    assert(exp == act, message(msg) { diff(exp, act) })
  end

  def assert_true(act, msg = nil) = assert_equal true, act, msg
  def assert_false(act, msg = nil) = assert_equal false, act, msg

  def windows? = RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/

  def with_env(env, &block)
    old = ENV.to_hash
    env.each { ENV[_1.to_s] = _2.to_s }
    yield
  ensure
    ENV.replace(old)
  end
end

#
# fake IO.console since it can hang under certain circumstances
#

class FakeConsole
  def fileno = 123
  def getbyte = fakeread.shift
  def raw = yield
  def syswrite(str) = fakewrite << str
  def winsize = [24, 80]
  def fakeread = (@fakeread ||= [])
  def fakewrite = (@fakewrite ||= StringIO.new)
end
