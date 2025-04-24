module TableTennis
  module Util
    class TestColors < Minitest::Test
      def test_get
        [
          # good
          [nil, nil],
          %i[red red],
          ["#fff", "#fff"],
          ["ff8822", "ff8822"],
          ["#ff8822", "#ff8822"],
          ["firebrick", "#b22222"],

          # bad
          [:bogus, nil],
          ["#ff", nil],
          ["bogus", nil],
        ].each do |value, exp|
          if value.nil? || exp != nil
            assert_equal exp, Colors.get(value), "for #{value}"
          else
            assert_output(/unknown/) { assert_nil Colors.get(value) }
          end
        end
      end

      def test_luma
        assert_equal 0.251, Colors.luma("#888")
        assert_equal 0, Colors.luma("#000")
        assert_equal 1, Colors.luma("#fff")
      end

      def test_dark?
        [
          [nil, true],
          [:black, true],
          [:gray, false],
          [:red, true],
          [:white, false],
          ["#222", true],
          ["#ff8822", false],
          ["bogus", true],
          ["f84", false],
        ].each do |color, exp|
          if color == "bogus"
            assert_output(/unknown/) { assert_equal exp, Colors.dark?(color), "for #{color}" }
          else
            assert_equal exp, Colors.dark?(color), "for #{color}"
          end
        end
      end

      def test_contrast
        [
          %w[#000000 white],
          %w[#fff black],
          %w[bogus white],
        ].each do |color, exp|
          if color == "bogus"
            assert_output(/unknown/) { assert_equal exp, Colors.contrast(color), "for #{color}" }
          else
            assert_equal exp, Colors.contrast(color), "for #{color}"
          end
        end
      end

      def test_to_hex
        assert_equal "#ff8002", Colors.to_hex([255, 128, 2])
      end

      def test_to_rgb
        assert_equal [255, 136, 34], Colors.to_rgb("f82")
        assert_equal [255, 136, 34], Colors.to_rgb("#f82")
        assert_equal [255, 136, 34], Colors.to_rgb("#ff8822")
        assert_equal [255, 136, 34], Colors.to_rgb("#fff888222")
        assert_equal [255, 136, 34], Colors.to_rgb("#ffff88882222")
      end

      def test_ansi_color_to_hex
        assert_nil Colors.ansi_color_to_hex(-1)
        assert_nil Colors.ansi_color_to_hex(16)
        assert_equal "#000000", Colors.ansi_color_to_hex(0)
        assert_equal "#7f7f7f", Colors.ansi_color_to_hex(8)
        assert_equal "#00ffff", Colors.ansi_color_to_hex(14)
      end

      def test_spectrum
        assert_output(/firebrick/) { Colors.spectrum }
      end
    end
  end
end
