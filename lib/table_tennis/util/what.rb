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
          return :number if int?(value)
          return nil if na?(value)
          return :string
        when Float then return :float
        when Numeric then return :number
        when Date, DateTime, Time then return :date
        end

        # Rails TimeWithZone
        return :time if value.respond_to?(:acts_like_time)

        :other
      end

      # string tests
      def na?(str) = str.match?(/\A(n\/a|na|none|\s+)\Z/i)
      def float?(str) = str.match?(/\A-?\d+\.\d+\Z/)
      def int?(str) = str.match?(/\A-?\d+\Z/)
    end
  end
end
