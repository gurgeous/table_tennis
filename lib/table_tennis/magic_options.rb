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
    attr_reader :error_prefix, :schema

    def initialize(schema, error_prefix: nil)
      @error_prefix = error_prefix
      if !schema.is_a?(Hash) || schema.empty?
        raise ArgumentError, "MagicOptions schema must be a non-empty hash"
      end
      # resolve type aliases (:boolean => :bool, :int => Integer, etc.)
      @schema = schema.transform_values do |type|
        if type.is_a?(Hash)
          type.to_h { [resolve_alias(_1), resolve_alias(_2)] }
        else
          resolve_alias(type)
        end
      end
      # now do our sanity check on the schema
      @schema.each do |key, type|
        if (error = sanity(key, type))
          raise ArgumentError, "MagicOptions schema #{key.inspect} #{error}"
        end
      end
    end

    def parse(options)
      # does options have unknown keys?
      unknown = options.keys - schema.keys
      if !unknown.empty?
        raise ArgumentError, "unknown options #{unknown.inspect}"
      end

      # now validate options
      options.to_h do |key, value|
        type = schema[key]
        value = coerce(value, type)
        if !value.nil? && (error = validate(value, type))
          if !type.is_a?(Proc)
            error = "#{error}, got #{value.inspect}"
          end
          error = if error_prefix
            "#{error_prefix}.#{key} #{error}"
          else
            "#{key.inspect} #{error}"
          end
          raise ArgumentError, error
        end
        [key, value]
      end
    end

    # sanity check the schema
    def sanity(key, type)
      return "schema keys must be symbols" if !key.is_a?(Symbol)
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

    # coerce value into type. pretty conservative at the moment
    def coerce(value, type)
      if type == :bool
        case value
        when true, 1, "1", "true" then value = true
        when false, 0, "", "0", "false" then value = false
        end
      end
      value
    end

    # validate the value matches type
    def validate(value, type)
      case type
      when Array
        "expected one of #{type.inspect}" if !type.include?(value)
      when Class, :bool
        "expected #{pretty_class(type)}" if !is_flex?(value, type)
      when Hash
        key_klass, value_klass = type.first
        validate_hash(value, key_klass, value_klass)
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
        klass = resolve_alias(type.to_s[..-2].to_sym)
        valid = value.is_a?(Array) && value.all? { is_flex?(_1, klass) }
        "expected array of #{type}" if !valid
      end
    end

    #
    # helpers
    #

    # value should be a hash of key_klass => value_klass
    def validate_hash(value, key_klass, value_klass)
      valid = value.is_a?(Hash) && value.all? { is_flex?(_1, key_klass) && is_flex?(_2, value_klass) }
      "expected hash of #{pretty_class(key_klass)} => #{pretty_class(value_klass)}" if !valid
    end

    # like is_a?, but slightly more flexible
    def is_flex?(value, klass)
      if klass == :bool
        value == true || value == false
      elsif klass == Float
        value.is_a?(klass) || value.is_a?(Integer)
      else
        value.is_a?(klass)
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

    def pretty_class(klass) = PRETTY[klass] || klass.to_s
    def resolve_alias(type) = ALIASES[type] || type
  end
end
