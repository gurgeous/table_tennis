module TableTennis
  class TestMagicOptions < Minitest::Test
    SCHEMA = {
      bool: :bool,
      float: :float,
      int: :int,
      num: :num,
      proc_bool: -> { _1 == "yes" },
      proc_err: -> { (_1 == "yes") || "ugh" },
      range: (-10..10),
      re: /hello|world/i,
      str: :str,
      sym: :sym,

      # arrays
      bools: :bools,
      floats: :floats,
      nums: :nums,
      ints: :ints,
      strs: :strs,
      syms: :syms,

      # hash
      hash_strs: {sym: :str},
      hash_floats: {sym: :float},

      # any one of these
      possibilities: %w[foo bar],
    }

    # REMIND: block
    # REMIND: invalid schema keys (wrong type, bad method names)

    def test_basic
      options = magic(
        bool: 1,
        floats: [123, 1.23],
        hash_strs: {a: "b"},
        range: nil,
        possibilities: "foo",
        str: "what"
      ).to_h

      assert_equal({
        bool: true,
        floats: [123, 1.23],
        hash_strs: {a: "b"},
        possibilities: "foo",
        range: nil,
        str: "what",
      }, options)
    end

    def test_bad_schema
      assert_raises(ArgumentError, "must be symbols") do
        MagicOptions.new("a" => :bool)
      end
      assert_raises(ArgumentError, "method names") do
        MagicOptions.new("hi there": :bool)
      end
    end

    #   # def test_types
    #   #   # edge cases
    #   #   assert_no_raises { magic.parse({}) }
    #   #   assert_magic_no_raises(:bools, nil)
    #   #   assert_magic_no_raises(:bools, [])
    #   #   assert_magic_no_raises(:hash_strs, {})
    #   #   SCHEMA.each_key { assert_magic_no_raises(_1, nil) }

    #   #   # these all work
    #   #   assert_magic_no_raises(:bool, 1)
    #   #   assert_magic_no_raises(:bool, "0")
    #   #   assert_magic_no_raises(:bool, "false")
    #   #   assert_magic_no_raises(:bool, true)
    #   #   assert_magic_no_raises(:float, 1.23)
    #   #   assert_magic_no_raises(:float, 123)
    #   #   assert_magic_no_raises(:int, 123)
    #   #   assert_magic_no_raises(:num, (1/2r))
    #   #   assert_magic_no_raises(:num, 1.23)
    #   #   assert_magic_no_raises(:num, 123)
    #   #   assert_magic_no_raises(:range, 5)
    #   #   assert_magic_no_raises(:re, "HELLO there")
    #   #   assert_magic_no_raises(:str, "foo")
    #   #   assert_magic_no_raises(:sym, :foo)
    #   #   # arrays
    #   #   assert_magic_no_raises(:bools, [true, false])
    #   #   assert_magic_no_raises(:ints, [123, 456])
    #   #   assert_magic_no_raises(:floats, [1.23, 123])
    #   #   assert_magic_no_raises(:nums, [1, 1.23, (1/2r)])
    #   #   assert_magic_no_raises(:strs, %w[what is up])
    #   #   assert_magic_no_raises(:syms, %i[what is up])
    #   #   # more complicated stuff
    #   #   assert_magic_no_raises(:hash_floats, {a: 123})
    #   #   assert_magic_no_raises(:hash_floats, {a: 1.23})
    #   #   assert_magic_no_raises(:hash_strs, {a: "b"})
    #   #   assert_magic_no_raises(:possibilities, "foo")
    #   #   assert_magic_no_raises(:proc_bool, "yes")
    #   #   assert_magic_no_raises(:proc_err, "yes")

    #   #   # here is an evil value that doesn't work on anything!
    #   #   evil = Object.new
    #   #   SCHEMA.each_key { assert_magic_raises(_1, evil) }

    #   #   # these don't work
    #   #   assert_magic_raises(:bool, [true, :nope])
    #   #   assert_magic_raises(:bools, {})
    #   #   assert_magic_raises(:bools, [false, :nope])
    #   #   assert_magic_raises(:floats, [1.23, "nope"])
    #   #   assert_magic_raises(:hash_floats, [])
    #   #   assert_magic_raises(:hash_floats, {a: "nope"})
    #   #   assert_magic_raises(:hash_strs, {a: 999})
    #   #   assert_magic_raises(:int, 9.99)
    #   #   assert_magic_raises(:ints, [123, 9.99])
    #   #   assert_magic_raises(:nums, [:nope])
    #   #   assert_magic_raises(:possibilities, "nope")
    #   #   assert_magic_raises(:proc_bool, "nope")
    #   #   assert_magic_raises(:proc_err, "nope")
    #   #   assert_magic_raises(:range, 999)
    #   #   assert_magic_raises(:re, "nope")
    #   #   assert_magic_raises(:strs, [:nope])
    #   #   assert_magic_raises(:syms, ["nope"])

    #   #   # proc custom error
    #   #   assert_raises(ArgumentError, "ugh") { magic.parse(proc_err: "nope") }
    #   # end

    #   # def test_aliases
    #   #   m = MagicOptions.new({a: :bool})
    #   #   assert_equal :bool, m.resolve_alias(:boolean)
    #   #   assert_equal :ints, m.resolve_alias(:integers)
    #   #   assert_equal Numeric, m.resolve_alias(:num)
    #   # end

    #   # def test_coercion
    #   #   m = MagicOptions.new({a: :bool})
    #   #   assert_equal true, m.coerce(1, :bool)
    #   #   assert_equal false, m.coerce("false", :bool)
    #   # end

    #   # def test_error_prefix
    #   #   m = MagicOptions.new({a: :bool}, error_prefix: "Slurpy")
    #   #   assert_raises(ArgumentError, "Slurpy.a") do
    #   #     m.parse(a: "nope")
    #   #   end
    #   # end

    protected

    class Magic < MagicOptions
      def initialize(options = {}, &block)
        super(SCHEMA, options, &block)
      end
    end

    def magic(options = {}, &block)
      Magic.new(options, &block)
    end

    #   # def assert_magic_no_raises(key, value)
    #   #   assert_no_raises { magic.parse(key => value) }
    #   # end

    #   # def assert_magic_raises(key, value)
    #   #   begin
    #   #     magic.parse(key => value)
    #   #   rescue => ex
    #   #   end

    #   #   what = "magic(#{key.inspect} => #{value.inspect})"
    #   #   if !ex.is_a?(ArgumentError)
    #   #     flunk("expected ArgumentError for #{what}, but got #{ex.inspect}")
    #   #   end
    #   #   assert_match(key.to_s, ex.message)
    #   # end
  end
end
