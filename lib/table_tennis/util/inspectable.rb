module TableTennis
  module Util
    # A mixin to avoid putting all row data into xxx.inspect. This makes
    # development much easier.
    module Inspectable
      def inspect = ENV["MINITEST"] ? super : inspect_without_rows

      def inspect_without_rows
        vars = instance_variables.filter_map do
          value = instance_variable_get(_1)
          if value.is_a?(Array) && _1.to_s =~ /rows$/
            value = if value.length == 1
              "[1 row]"
            else
              "[#{value.length} rows]"
            end
          end
          "#{_1}=#{value.inspect}"
        end.join(" ")

        "<#{self.class.name} #{vars}>"
      end
    end
  end
end
