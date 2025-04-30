#
# Helper class for strict config/option processing. This is used by Config but
# could probably be a custom gem at some point.
#
# The schema is a hash of keys to types. The types are:
#
# (1) A primitive type like :bool, :int, :num, :float, :str or :sym
# (2) An array type like :bools, :ints, :nums, :floats, :strs, or :syms
# (3) A range, regexp or Class
# (4) A lambda which should return an error string, a boolean, or nil
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
    attr_reader :schema

    def initialize(schema)
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

      # now do our sanity check
      @schema.each do |key, type|
        if (error = sanity(key, type))
          raise ArgumentError, "MagicOptions schema #{key.inspect} #{error}"
        end
      end
    end

    def parse(options)
      # any unknown keys?
      unknown = options.keys - schema.keys
      if !unknown.empty?
        raise ArgumentError, "unknown options #{unknown.inspect}"
      end

      # validate
      schema.filter_map do |key, type|
        if options.key?(key)
          if !(value = options[key]).nil?
            value = coerce(value, type)
            if (error = validate(value, type))
              raise ArgumentError, "#{key.inspect} #{error}, but it was #{value.inspect}"
            end
          end
          [key, value]
        end
      end.to_h
    end

    # sanity check the schema
    def sanity(key, type)
      if !key.is_a?(Symbol)
        return "schema keys must be symbols"
      end

      case type
      # single value that matches this type
      when :bool, Class, Proc, Range, Regexp then return

      # value is an array
      when :bools, :floats, :ints, :nums, :strs, :syms then return

      # one of these possible values
      when Array
        if type.empty?
          "must be an array of possible values"
        end

      # hash with a certain signature
      when Hash
        valid = type.length == 1 && type.first.all? { _1 == :bool || _1.is_a?(Class) }
        if !valid
          "must be { class => class }"
        end

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

      # one of these possible values
      when Array
        if !type.include?(value)
          "expected one of #{type.inspect}"
        end

      # hash with a certain signature
      when Hash
        key_klass, value_klass = type.first
        validate_hash(value, key_klass, value_klass)

      when Proc
        ret = type.call(value)
        case ret
        when String then ret
        when false then "expected to pass #{type.inspect}"
        end

      when Range
        if !value.is_a?(Numeric)
          "expected number"
        elsif !type.include?(value)
          "expected to be in range #{type.inspect}"
        end

      when Regexp
        if !value.is_a?(String)
          "expected string"
        elsif !value.match?(type)
          "expected to match #{type.inspect}"
        end

      when :bool, Class
        if !is_a_flexible?(value, type)
          "expected #{pretty_class(type)}"
        end

      # arrays
      when :bools, :floats, :ints, :nums, :strs, :syms
        klass = resolve_alias(type.to_s[..-2].to_sym)
        valid = value.is_a?(Array) && value.all? { is_a_flexible?(_1, klass) }
        if !valid
          "expected array of #{type}"
        end

      else
        # this should never happen
        raise "impossible type #{type.inspect}"
      end
    end

    #
    # helpers
    #

    # validate that valie is a hash of key_klass => value_klass
    def validate_hash(value, key_klass, value_klass)
      valid = if value.is_a?(Hash)
        valid_values = value.values.all? { is_a_flexible?(_1, value_klass) }
        valid_keys = value.keys.all? { is_a_flexible?(_1, key_klass) }
        valid_keys && valid_values
      end
      if !valid
        "expected hash of #{pretty_class(key_klass)} => #{pretty_class(value_klass)}"
      end
    end

    # like is_a?, but supports :bool is a klass
    def is_a_flexible?(value, klass)
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
