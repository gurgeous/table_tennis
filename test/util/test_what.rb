module TableTennis
  module Util
    class TestWhat < Minitest::Test
      def test_what_is_it
        [
          [nil, nil],
          ["NA", nil],
          ["none", nil],
          ["", nil],
          ["1.234", :float],
          ["1", :int],
          ["gub", :string],
          [1.234, :float],
          [1, :int],
          [Time.now, :time],
        ].each do |value, exp|
          assert_equal exp, Util::What.what_is_it(value), "with #{value}"
        end
      end

      def test_float_helpers
        assert Util::What.float_or_int?("1.2")
        assert Util::What.float_or_int?("1")
        assert Util::What.float?("1.2")
        assert !Util::What.float?("1")
      end
    end
  end
end
