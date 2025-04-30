module TableTennis
  # A single column in a table. The data is actually stored in the rows, but it
  # can be enumerated from here.
  class Column
    extend Forwardable
    include Enumerable
    include Util::Inspectable
    prepend MemoWise

    # c is the column index
    attr_reader :name, :data, :c
    attr_accessor :header, :width
    def_delegators :data, *%i[config rows]

    def initialize(data, name, c)
      @name, @data, @c = name, data, c
      @header = config&.headers&.dig(name) || name.to_s
      if config&.titleize?
        @header = Util::Strings.titleize(@header)
      end
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      rows.each { yield(_1[c]) }
      self
    end

    def map!(&block) = rows.each { _1[c] = yield(_1[c]) }

    # what type is this column? Sample 100 rows and guess. Will be nil if we aren't sure.
    def type
      samples = rows.sample(100).map { _1[c] }
      Util::Identify.identify_column(samples)
    end
    memo_wise :type

    def alignment
      case type
      when :float, :int then :right
      else :left
      end
    end

    def truncate(stop)
      @header = Util::Strings.truncate(header, stop)
      map! { Util::Strings.truncate(_1, stop) }
    end

    def measure
      [2, max_by(&:length)&.length, header.length].max
    end
  end
end
