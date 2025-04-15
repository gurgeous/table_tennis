module TableTennis
  #
  # This module helps to classifying columns and values. Are they floats? Dates?
  # Floats strings?
  #

  module Util
    # Helpers for measuring and truncating strings.
    module Identify
      prepend MemoWise

      module_function

      def identify_column(values)
        # grab 100, what do we have?
        types = values.filter_map { identify(_1) }.uniq
        case types.length
        when 0 # all nils, too bad
        when 1
          types.first # one type, it wins
        when 2
          :float if types.sort == %i[float int]
        end
        # all mixed up, can't do much with it
      end

      # Try to identify a single cell value. Peer into strings.
      def identify(value)
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
        :unknown
      end

      # tests
      def na?(str) = str.match?(/\A(n\/a|na|none|\s+)\Z/i)
      def number?(str) = str.match?(/\A-?[\d,]+(?:[.]?\d*)?\Z/)
      def float?(str) = str.match?(/\A-?[\d,]+[.]\d*\Z/)
      def int?(str) = str.match?(/\A-?[\d,]+\Z/)
      def time?(value) = value.respond_to?(:strftime)
    end
  end
end
