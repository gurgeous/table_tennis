module TableTennis
  #
  # This module helps to classifying columns and values. Are they floats? Dates?
  # Floats strings?
  #
  module Util
    module What
      # Helpers for measuring and truncating strings.
      prepend MemoWise

      module_function

      # what is this value?
      def what_is_it(value)
        case value
        when nil, "" then return nil
        when String
          return :float if float?(value)
          return :int if int?(value)
          return nil if na?(value)
          return :string
        when Float then return :float
        when Numeric then return :int
        end
        return :time if time?(value)

        :other
      end

      # tests
      def na?(str) = str.match?(/\A(n\/a|na|none|\s+)\Z/i)
      def float_or_int?(str) = str.match?(/\A-?\d+(?:[.]?\d*)?\Z/)
      def float?(str) = str.match?(/\A-?\d+[.]\d*\Z/)
      def int?(str) = str.match?(/\A-?\d+\Z/)
      def time?(value) = value.respond_to?(:strftime)
    end
  end
end
