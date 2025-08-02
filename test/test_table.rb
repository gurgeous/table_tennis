module TableTennis
  class TestTable < Minitest::Test
    def test_main
      table = Table.new([{a: 1, b: 2}])
      assert_equal %i[a b], table.columns.map(&:name)
      assert_equal [[1, 2]], table.rows

      # to_s
      lines = table.to_s.split("\n").map { Util::Strings.unpaint(_1) }
      assert_match(/^╭─+┬─+╮$/, lines[0])
      [1, 3].each do
        assert_match(/^|\s+[a1]\s+|\s+[b2]\s+|$/, lines[_1])
      end
      [2, 4].each do
        assert_match(/^[╰├]─+[┴┼]─+[╯┤]$/, lines[_1])
      end

      # $stdout
      assert_output(/┴/) { table.render }
    end

    # just make sure these don't crash
    def test_kitchen_sink
      options = {
        color_scales: {a: :r},
        digits: 2,
        layout: {b: 3},
        mark: ->(_) { rand < 0.1 },
        row_numbers: true,
        search: "2",
        strftime: "%Y-%m-%d",
        theme: :light,
        title: "hello",
        zebra: true,
      }
      Table.new([{a: 1, b: 2}])
      Table.new([], options)
    end

    def test_sanity!
      assert_no_raises do
        Table.new([{a: 1, b: 2}], color_scales: {a: :r}, layout: {a: 3})
      end
      assert_raises(ArgumentError) do
        Table.new([{a: 1, b: 2}], {color_scales: {xxx: :r}})
      end
      assert_raises(ArgumentError) do
        Table.new([{a: 1, b: 2}], {layout: {xxx: 3}})
      end
      assert_raises(ArgumentError) do
        Table.new([{a: 1, b: 2}], headers: %w[a])
      end
    end

    def test_save
      2.times do |ii|
        File.unlink(TMP) if File.exist?(TMP)
        rows = [{a: 1}]
        if ii == 0
          # explicit call to save
          Table.new(rows).save(TMP)
        else
          # save: option for render
          Table.new(rows, save: TMP).to_s
        end
        csv = CSV.read(TMP, headers: true).map(&:to_h)
        assert_equal([{"a" => "1"}], csv)
      end
    end

    require_relative "test_helper"

    # an end-to-end test when IO.console is nil, which can occur with Docker. Also see
    # https://github.com/gurgeous/table_tennis/issues/14
    def test_no_console
      IO.stubs(:console).returns(nil)

      # make sure we really stubbed it
      assert_equal [10, 80], Util::Console.winsize
      assert_raises { Util.console.raw }

      # now run our two main tests
      test_main
      test_kitchen_sink
    end
  end
end
