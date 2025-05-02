module TableTennis
  module Util
    class TestMagicOptions < Minitest::Test
      SCHEMA = {
        bool: :bool,
        float: :float,
        int: :int,
        num: :num,
        proc: -> {
          raise ArgumentError, "ugh" if _1 != "yes"
        },
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

      def test_basic
        # create some options
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

        # ctor with some values and a block
        m = Magic.new(float: 1.23) { _1.bool = 0 }
        assert_equal({bool: false, float: 1.23}, m.to_h)
        # xxx? methods
        assert_false m.bool?
        # update!
        assert_equal 5, m.tap { m.update!(range: 5) }.range

        # can't be directly instantiated
        ex = assert_raises(ArgumentError) { MagicOptions.new({}) }
        assert_match(/abstract class/, ex.message)
      end

      class Subclass < MagicOptions; end

      def test_bad_schema_keys
        ex = assert_raises(ArgumentError) { Subclass.new("a" => :bool) }
        assert_match(/must be symbols/, ex.message)
        ex = assert_raises(ArgumentError) { Subclass.new("hi there": :bool) }
        assert_match(/method names/, ex.message)
      end

      def test_types
        # edge cases
        assert_magic_no_raises(:bools, nil)
        assert_magic_no_raises(:bools, [])
        assert_magic_no_raises(:hash_strs, {})
        SCHEMA.each_key { assert_magic_no_raises(_1, nil) }

        # these all work
        assert_magic_no_raises(:bool, 1)
        assert_magic_no_raises(:bool, "0")
        assert_magic_no_raises(:bool, "false")
        assert_magic_no_raises(:bool, true)
        assert_magic_no_raises(:float, 1.23)
        assert_magic_no_raises(:float, 123)
        assert_magic_no_raises(:int, 123)
        assert_magic_no_raises(:num, 1/2r)
        assert_magic_no_raises(:num, 1.23)
        assert_magic_no_raises(:num, 123)
        assert_magic_no_raises(:range, 5)
        assert_magic_no_raises(:re, "HELLO there")
        assert_magic_no_raises(:str, "foo")
        assert_magic_no_raises(:sym, :foo)
        # arrays
        assert_magic_no_raises(:bools, [true, false])
        assert_magic_no_raises(:ints, [123, 456])
        assert_magic_no_raises(:floats, [1.23, 123])
        assert_magic_no_raises(:nums, [1, 1.23, (1/2r)])
        assert_magic_no_raises(:strs, %w[what is up])
        assert_magic_no_raises(:syms, %i[what is up])
        # more complicated stuff
        assert_magic_no_raises(:hash_floats, {a: 123})
        assert_magic_no_raises(:hash_floats, {a: 1.23})
        assert_magic_no_raises(:hash_strs, {a: "b"})
        assert_magic_no_raises(:possibilities, "foo")
        assert_magic_no_raises(:proc, "yes")

        # here is an evil value that doesn't work on anything!
        evil = Object.new
        SCHEMA.each_key { assert_magic_raises(_1, evil) }

        # these don't work
        assert_magic_raises(:bool, [true, :nope])
        assert_magic_raises(:bools, {})
        assert_magic_raises(:bools, [false, :nope])
        assert_magic_raises(:floats, [1.23, "nope"])
        assert_magic_raises(:hash_floats, [])
        assert_magic_raises(:hash_floats, {a: "nope"})
        assert_magic_raises(:hash_strs, {a: 999})
        assert_magic_raises(:int, 9.99)
        assert_magic_raises(:ints, [123, 9.99])
        assert_magic_raises(:nums, [:nope])
        assert_magic_raises(:possibilities, "nope")
        assert_magic_raises(:proc, "nope")
        assert_magic_raises(:range, 999)
        assert_magic_raises(:re, "nope")
        assert_magic_raises(:strs, [:nope])
        assert_magic_raises(:syms, ["nope"])

        # test proc custom error
        ex = assert_raises(ArgumentError) { magic(proc: "nope") }
        assert_match(/ugh/, ex.message)
      end

      def test_aliases
        assert_equal :bool, MagicOptions.magic_resolve(:boolean)
        assert_equal :ints, MagicOptions.magic_resolve(:integers)
        assert_equal Numeric, MagicOptions.magic_resolve(:num)
      end

      def test_coercion
        assert_true magic(bool: "true").bool
        assert_true MagicOptions.magic_coerce(1, :bool)
        assert_false MagicOptions.magic_coerce("false", :bool)
      end

      protected

      class Magic < MagicOptions
        def initialize(options = {}, &block)
          super(SCHEMA, options, &block)
        end
      end

      def magic(options = {}, &block)
        Magic.new(options, &block)
      end

      def assert_magic_no_raises(key, value)
        assert_no_raises { magic(key => value) }
      end

      def assert_magic_raises(key, value)
        begin
          magic(key => value)
        rescue => ex
        end

        what = "magic(#{key.inspect} => #{value.inspect})"
        if !ex.is_a?(ArgumentError)
          flunk("expected ArgumentError for #{what}, but got #{ex.inspect}")
        end
        assert_match(key.to_s, ex.message)
      end
    end
  end
end
