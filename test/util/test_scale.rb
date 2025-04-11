module TableTennis
  module Util
    class TestScale < Minitest::Test
      def test_interpolate
        assert_equal Scale::RED, Scale.interpolate(:rg, 0)
        assert_equal "#ffffff", Scale.interpolate(:rg, 0.5)
        assert_equal Scale::GREEN, Scale.interpolate(:rg, 1)
      end
    end
  end
end
