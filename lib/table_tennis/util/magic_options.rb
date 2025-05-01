#
# Helper class for validated option processing. This is used by Config but could probably be a
# custom gem at some point...
#
# MagicOptions is created with a `schema` defining a list of `attributes`. Each attribute has a
# `name` and a `type`. `options` is a hash of values that will be validated against the schema.
# MagicOptions adds getters and setters for each attribute, and also supports [] and []=. The
# setters perform validation and raise ArgumentError if something is awry. Because setters always
# validate, it is not possible to populate MagicOptions with invalid values.
#
# To use, subclass MagicOptions and construct with a schema:
#
#   class Config < MagicOptions
#     def initialize
#       super(
#         first_name: :str,
#         colors: :strings,
#         customer: :bool,
#         age: (20..90)
#       )
#     end
#   end
#
# Then assign values:
#
#   config = Config.new
#   config.colors = %w[red white blue]
#   config.update!(first_name: "john", customer: false)
#
# Here are the supported attribute types:
#
# (1) A simple type like :bool, :int, :num, :float, :str or :sym.
# (2) An array type like :bools, :ints, :nums, :floats, :strs, or :syms.
# (3) A range, regexp or Class.
# (4) A lambda which should return an error string or nil.
# (5) An array of possible values (typically numbers, strings, or symbols). The
#     value must be one of those possibilities.
# (6) A hash with one element { class => class }. This specifies the hash
#     signature, and the value must be a hash where the keys and values are
#     those classes.
#
# There is a bit of type coercion, but not much. For example, the string "true" or "1" will be
# coerced to true for boolean options. Integers can be used when the schema calls for floats.
#

module TableTennis
  module Util
    class MagicOptions
      #
      # public api (also see [] and []=)
      #

      attr_accessor :magic_attributes, :magic_values

      def initialize(schema, options = {}, &block)
        @magic_attributes, @magic_values = {}, {}
        schema.each { magic_add_attribute(_1, _2) }
        update!(options) if options
        yield self if block_given?
      end

      def update!(hash) = hash.each { send("#{_1}=", _2) }
      def to_h = magic_values.dup

      def inspect
        values = magic_values.compact.map { "#{_1}=#{_2.inspect}" }.join(", ")
        "#<#{self.class} #{values}>"
      end

      #
      # magic_add_attribute
      #

      def magic_add_attribute(name, type)
        # resolve :boolean to :bool, :int => Integer class, etc.
        type = if type.is_a?(Hash)
          type.to_h { [self.class.magic_resolve(_1), self.class.magic_resolve(_2)] }
        else
          self.class.magic_resolve(type)
        end

        # sanity check for schema errors
        if (error = magic_sanity(name, type))
          raise ArgumentError, "MagicOptions schema #{name.inspect} #{error}"
        end

        # all is well
        magic_attributes[name] = type
        if !respond_to?(name)
          define_singleton_method(name) { self[name] }
        end
        if type == :bool && !respond_to?("#{name}?")
          define_singleton_method("#{name}?") { !!self[name] }
        end
        if !respond_to?("#{name}=")
          define_singleton_method("#{name}=") { |value| self[name] = value }
        end
      end

      # sanity check a name/type from the schema
      def magic_sanity(name, type)
        if !name.is_a?(Symbol)
          return "attribute names must be symbols"
        end
        if !name.to_s.match?(/\A[a-z_][0-9a-z_]*\z/i)
          return "attribute names must be valid method names"
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

      #
      # magic_get/set
      #

      def magic_get(name)
        raise ArgumentError, "unknown #{self.class}.#{name}" if !magic_attributes.key?(name)
        magic_values[name]
      end

      def magic_set(name, value)
        raise ArgumentError, "unknown #{self.class}.#{name}=" if !magic_attributes.key?(name)
        type = magic_attributes[name]
        value = self.class.magic_coerce(value, type)
        if !value.nil? && (error = MagicOptions.magic_validate(value, type))
          if !type.is_a?(Proc)
            error = "#{error}, got #{value.inspect}"
          end
          raise ArgumentError, "#{self.class}.#{name}= #{error}"
        end
        magic_values[name] = value
      end

      # these are part of the public api
      alias_method :[], :magic_get
      alias_method :[]=, :magic_set

      #
      # magic_validate and static helpers
      #

      def self.magic_validate(value, type)
        case type
        when Array
          "expected one of #{type.inspect}" if !type.include?(value)
        when Class, :bool
          "expected #{magic_pretty(type)}" if !magic_is_a?(value, type)
        when Hash
          name_klass, value_klass = type.first
          valid = value.is_a?(Hash) && value.all? { magic_is_a?(_1, name_klass) && magic_is_a?(_2, value_klass) }
          "expected hash of #{magic_pretty(name_klass)} => #{magic_pretty(value_klass)}" if !valid
        when Proc
          ret = type.call(value)
          case ret
          when String, false, nil then ret
          else
            puts "warning: MagicOptions.proc should ONLY return error string or nil/false, not #{ret.inspect}"
            ret.to_s
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

      # coerce value into type. pretty conservative at the moment
      def self.magic_coerce(value, type)
        if type == :bool
          case value
          when true, 1, "1", "true" then value = true
          when false, 0, "", "0", "false" then value = false
          end
        end
        value
      end

      # like is_a?, but supports :bool and allows ints to be floats
      def self.magic_is_a?(value, klass)
        if klass == :bool
          value == true || value == false
        elsif klass == Float
          value.is_a?(klass) || value.is_a?(Integer)
        else
          value.is_a?(klass)
        end
      end

      MAGIC_ALIASES = {
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
        lambda: Proc,
        num: Numeric,
        number: Numeric,
        numbers: :nums,
        nums: :nums,
        proc: Proc,
        str: String,
        string: String,
        strings: :strs,
        strs: :strs,
        sym: Symbol,
        symbol: Symbol,
        symbols: :syms,
        syms: :syms,
      }

      MAGIC_PRETTY = {
        :bool => "boolean",
        Float => "float",
        Integer => "integer",
        Numeric => "number",
        String => "string",
        Symbol => "symbol",
      }

      # pretty print a class (or :bool)
      def self.magic_pretty(klass) = MAGIC_PRETTY[klass] || klass.to_s

      # resolve :boolean to :bool, :int => Integer class, etc.
      def self.magic_resolve(type) = MAGIC_ALIASES[type] || type
    end
  end
end
