module TableTennis
  # This class stores our data as rows & columns. The initialization is a little
  # tricky due to memoization and some ordering issues, but basically works like
  # this:
  #
  # 1) Start with input_rows.
  # 2) Calculate `fat_rows` which is an array of hashes with all keys. This
  #    might be too much data because we haven't taken config.columns into
  #    account.
  # 3) Use fat_rows to calculate rows & columns.
  #
  #  Generally we try to use this language:
  # - `row` is a a Row, an array of cells
  # - `column` is a Column. It doesn't store any data directly but it
  #    can be enumerated.
  # - `name` is a column.name
  # - `value` is the value of a cell
  # - `r` and `c` are row and column indexes
  #
  class TableData
    prepend MemoWise
    include Util::Inspectable

    attr_accessor :config, :input_rows, :links, :styles

    def initialize(rows:, config: nil)
      @config, @input_rows = config, rows

      if !config && !ENV["MINITEST"]
        raise ArgumentError, "must provide a config"
      end

      # We leave input_rows untouched so we can pass them back to the user for
      # `mark`. The only strange case is if the user passed in a plain old Hash.
      if @input_rows.is_a?(Hash)
        @input_rows = @input_rows.map { |key, value| {key:, value:} }
      elsif !@input_rows.is_a?(Enumerable)
        raise ArgumentError, "input_rows must be an array of hash-like objects, not #{input_rows.class}"
      end

      @links = {}
      @styles = {}
    end

    # Lazily calculate the list of columns.
    def columns
      names = config&.columns
      if !fat_rows.empty?
        names ||= {}.tap do |memo|
          fat_rows.each { |row| row.each_key { memo[_1] = 1 } }
        end.keys
      else
        names = []
      end
      names.each do |name|
        if !fat_rows.any? { _1.key?(name) }
          raise ArgumentError, "specified column `#{name}` not found in any row of input data"
        end
      end
      names.map.with_index { Column.new(self, _1, _2) }
    end
    memo_wise :columns

    # Lazily calculate column names (always symbols)
    def column_names = columns.map(&:name)
    memo_wise :column_names

    # fat_rows is an array of hashes with ALL keys (not just config.columns).
    # rows is an array of Row objects with just the keys we want. We use
    # memoization to cache the result of fat_rows, and then we create final rows
    # with just the columns we want
    def rows
      fat_rows.map.with_index { Row.new(_2, _1.values_at(*column_names)) }
    end
    memo_wise :rows

    # currnet theme
    def theme = Theme.new(config&.theme)
    memo_wise :theme

    # Set the style for a cell, row or column. The "style" is a
    # theme symbol or hex color.
    def set_style(style:, r: nil, c: nil) = styles[[r, c]] = style

    # Get the style for a cell, row or column.
    def get_style(r: nil, c: nil) = styles[[r, c]]

    # what is the width of the columns, not including chrome?
    def data_width = columns.sum(&:width)

    # how wide is the table?
    def table_width = data_width + chrome_width

    # layout math
    #
    # with separators
    # |•xxxx•|•xxxx•|•xxxx•|•xxxx•|•xxxx•|•xxxx•|•xxxx•|•xxxx•|
    # ↑↑    ↑                                                 ↑
    # 12    3    <-   three chrome chars per column           │
    #                                                         │
    #                                           extra chrome char at the end
    # without
    # |•xxxx••xxxx••xxxx••xxxx••xxxx••xxxx••xxxx••xxxx•|
    #  ↑    ↑                                          ↑
    #  1    2    <-   two chrome chars per column      │
    #                                                  │
    #                             extra chrome char at beginning and end
    def chrome_width
      config.separators ? (columns.length * 3 + 1) : (columns.length * 2 + 2)
    end
    memo_wise :chrome_width

    # for debugging
    def debug(str)
      return if !config&.debug
      str = "[#{Time.now.strftime("%H:%M:%S")}] #{str}"
      str = str.ljust(@debug_width ||= Util::Console.winsize[1])
      puts Paint[str, :white, :green]
    end

    def debug_if_slow(str, &block)
      tm = Time.now
      yield.tap do
        if (elapsed = Time.now - tm) > 0.01
          debug(sprintf("%-40s [+%0.3fs]", str, elapsed))
        end
      end
    end

    protected

    # fat_rows is an array of hashes with ALL keys (not just config.columns).
    def fat_rows
      first_row = input_rows.first
      array = if first_row.is_a?(Hash)
        input_rows
      elsif first_row.is_a?(Array)
        indexes = first_row.each_index.to_a
        input_rows.map { indexes.zip(_1).to_h }
      elsif first_row.respond_to?(:to_h)
        input_rows.map(&:to_h)
      elsif first_row.respond_to?(:attributes)
        input_rows.map(&:attributes)
      else
        raise ArgumentError, "unknown row type #{first_row.inspect}"
      end
      return [] if array.empty?

      # this is faster with a lookup table
      quick = array.first.keys.map { [_1, symbolize(_1)] }
      fat_rows = array.map do |row|
        row.transform_keys.with_index do |name, ii|
          if (q = quick[ii]) && (name == q[0])
            q[1]
          else
            symbolize(name)
          end
        end
      end

      # add row_numbers
      if config&.row_numbers?
        fat_rows = fat_rows.map.with_index do |row, r|
          row.to_a.unshift([:"#", r + 1]).to_h
        end
      end

      fat_rows
    end
    memo_wise :fat_rows

    # helper for turning something into a symbol
    def symbolize(obj) = obj.is_a?(Symbol) ? obj : obj.to_s.to_sym
  end
end
