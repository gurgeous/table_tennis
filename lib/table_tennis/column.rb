module TableTennis
  #
  # A single column in a table. The data is actually stored in the rows, but it
  # can be enumerated from here. Mostly used for layout calculations.
  #

  class Column
    include Enumerable
    prepend MemoWise

    attr_reader :name
    attr_accessor :header, :width

    def initialize(name, data)
      @name, @data = name, data
      @header = name.to_s
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      @data.rows.each { yield(_1[name]) }
      self
    end

    def each_index(&block)
      return to_enum(__method__) unless block_given?
      @data.rows.each_index { yield(_1) }
    end

    def map!(&block) = @data.rows.each { _1[name] = yield(_1[name]) }

    def truncate(stop)
      @header = Util::Strings.truncate(header, stop)
      map! { Util::Strings.truncate(_1, stop) }
    end

    def measure
      [2, max_by(&:length)&.length, header.length].max
    end
  end
end
