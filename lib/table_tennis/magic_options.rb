#
# Helper class for strict config/option processing. This is used by Config but
# could probably be a custom gem at some point.
#
# The schema is a hash of keys to types. The types are:
#
# (1) A simple type like :bool, :int, :num, :float, :str or :sym.
# (2) A range, regexp or Class.
# (3) An array type like :bools, :ints, :nums, :floats, :strs, or :syms.
# (4) A lambda which should return an error string, a boolean, or nil.
# (5) An array of possible values (typically numbers, strings, or symbols). The
#     value must be one of those possibilities.
# (6) A hash with one element { class => class }. This specifies the hash
#     signature, and the value must be a hash where the keys and values are
#     those classes.
#
# All values are optional. There is a bit of type coercion, but not much. For
# example, the string "true" or "1" will be coerced to true for boolean options.
# Integers can be used when the schema calls for floats.
#

module TableTennis
  class MagicOptions
    attr_accessor :magic_options, :magic_schema

    #
    # public api
    #

    def initialize(schema, options = {}, &block)
      @magic_options, @magic_schema = {}, {}
      schema.each { magic_define(_1, _2) }
      update!(options) if options
      yield self if block_given?
    end

    def []=(key, value)
      magic_set(key, value)
    end

    def [](key) = magic_get(key)
    def update!(hash) = hash.each { self[_1] = _2 }
    def to_h = magic_options.dup

    protected

    #
    # magic_define and friends
    #

    def magic_define(key, type)
      type = if type.is_a?(Hash)
        type.to_h { [magic_resolve(_1), magic_resolve(_2)] }
      else
        magic_resolve(type)
      end

      if (error = magic_sanity(key, type))
        raise ArgumentError, "MagicOptions schema #{key.inspect} #{error}"
      end
      magic_schema[key] = type

      define_singleton_method(key) { self[key] }
      define_singleton_method("#{key}?") { !!self[key] } if type == :bool
      define_singleton_method("#{key}=") { |value| self[key] = value }
    end

    # sanity check a key/type from the schema
    def magic_sanity(key, type)
      if !key.is_a?(Symbol)
        return "schema keys must be symbols"
      end
      if !key.to_s.match?(/\A[a-z_][0-9a-z_]+\z/i)
        return "schema keys must be valid method names"
      end

      case type
      when :bool, :bools, :floats, :ints, :nums, :strs, :syms, Class, Proc, Range, Regexp
        return
      when Array
        "must be an array of possible values" if type.empty?
      when Hash
        valid = type.length == 1 && type.first.all? { _1 == :bool || _1.is_a?(Class) }
        "must be { class => class }" if !valid
      else
        "unknown schema type #{type.inspect}"
      end
    end

    ALIASES = {
      boolean: :bool,
      booleans: :bools,
      bool: :bool,
      bools: :bools,
      float: Float,
      floats: :floats,
      int: Integer,
      integer: Integer,
      integers: :ints,
      ints: :ints,
      num: Numeric,
      number: Numeric,
      numbers: :nums,
      nums: :nums,
      str: String,
      string: String,
      strings: :strs,
      strs: :strs,
      sym: Symbol,
      symbol: Symbol,
      symbols: :syms,
      syms: :syms,
    }

    PRETTY = {
      :bool => "boolean",
      Float => "float",
      Integer => "integer",
      Numeric => "number",
      String => "string",
      Symbol => "symbol",
    }

    def magic_resolve(type) = ALIASES[type] || type
    def magic_pretty(klass) = PRETTY[klass] || klass.to_s

    #
    # magic_get/set
    #

    def magic_get(key)
      raise ArgumentError, "unknown #{self.class}.#{key}" if !magic_schema.key?(key)
      magic_options[key]
    end

    def magic_set(key, value)
      raise ArgumentError, "unknown #{self.class}.#{key}=" if !magic_schema.key?(key)
      type = magic_schema[key]
      value = magic_coerce(value, type)
      if !value.nil? && (error = magic_validate(value, type))
        if !type.is_a?(Proc)
          error = "#{error}, got #{value.inspect}"
        end
        raise ArgumentError, "#{self.class}.#{key}= #{error}"
      end
      magic_options[key] = value
    end

    # coerce value into type. pretty conservative at the moment
    def magic_coerce(value, type)
      if type == :bool
        case value
        when true, 1, "1", "true" then value = true
        when false, 0, "", "0", "false" then value = false
        end
      end
      value
    end

    #
    # magic_validate
    #

    def magic_validate(value, type)
      case type
      when Array
        "expected one of #{type.inspect}" if !type.include?(value)
      when Class, :bool
        "expected #{magic_pretty(type)}" if !magic_is_a?(value, type)
      when Hash
        key_klass, value_klass = type.first
        valid = value.is_a?(Hash) && value.all? { magic_is_a?(_1, key_klass) && magic_is_a?(_2, value_klass) }
        "expected hash of #{magic_pretty(key_klass)} => #{magic_pretty(value_klass)}" if !valid
      when Proc
        ret = type.call(value)
        if ret.is_a?(String)
          ret
        elsif !ret
          "invalid"
        end
      when Range
        if !value.is_a?(Numeric) || !type.include?(value)
          "expected to be in range #{type.inspect}"
        end
      when Regexp
        if !value.is_a?(String) || !value.match?(type)
          "expected to be a string matching #{type.inspect}"
        end
      when :bools, :floats, :ints, :nums, :strs, :syms
        klass = magic_resolve(type.to_s[..-2].to_sym)
        valid = value.is_a?(Array) && value.all? { magic_is_a?(_1, klass) }
        "expected array of #{type}" if !valid
      end
    end

    # like is_a?, but slightly more flexible
    def magic_is_a?(value, klass)
      if klass == :bool
        value == true || value == false
      elsif klass == Float
        value.is_a?(klass) || value.is_a?(Integer)
      else
        value.is_a?(klass)
      end
    end
  end
end
