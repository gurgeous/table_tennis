module TableManners
  module Util
    class TestScale < Minitest::Test
      def test_interpolate
        assert_equal Scale::RED, Scale.interpolate(:red_green, 0)
        assert_equal "#ffffff", Scale.interpolate(:red_green, 0.5)
        assert_equal Scale::GREEN, Scale.interpolate(:red_green, 1)
      end
    end
  end
end
