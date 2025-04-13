module TableTennis
  module Util
    class TestIdentify < Minitest::Test
      def test_detect_type
        data = [
          [1.23, 1234, 1, "gub", Time.now, :xyz],
          [1.23, 1.23, 1, "gub", Time.now, :xyz],
          [nil, nil, nil, nil, nil, nil],
        ]
        types = data.transpose.map { Identify.identify_column(_1) }
        assert_equal %i[float float int string time unknown], types
      end

      def test_identify
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
          assert_equal exp, Util::Identify.identify(value), "with #{value}"
        end
      end

      def test_float_helpers
        assert Util::Identify.number?("1.2")
        assert Util::Identify.number?("1")
        assert Util::Identify.float?("1.2")
        assert !Util::Identify.float?("1")
      end
    end
  end
end
