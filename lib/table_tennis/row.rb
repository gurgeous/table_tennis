module TableTennis
  # A single table row (a hash). Doesn't have much behavior.
  class Row < Hash
    def initialize(column_names, fat_row)
      super()
      column_names.each { self[_1] = fat_row[_1] }
    end
  end
end
