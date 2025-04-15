module TableTennis
  # We use this to store each row of data in the table. Row is an array, but with `r` too.
  class Row < Array
    # r is the index of this row
    attr_reader :r
    def initialize(r, values)
      super(values)
      @r = r
    end
  end
end
