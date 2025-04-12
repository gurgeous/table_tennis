module TableTennis
  #
  # A single column in a table. The data is actually stored in the rows, but it
  # can be enumerated from here. Mostly used for layout calculations.
  #

  class Column
    include Enumerable
    include Util::Inspectable
    extend Forwardable
    prepend MemoWise

    attr_reader :name, :data, :index
    attr_accessor :header, :width
    def_delegators :data, *%i[rows]

    def initialize(data, name, index)
      @name, @data, @index = name, data, index
      @header = name.to_s
      if data&.config&.titleize?
        @header = Util::Strings.titleize(@header)
      end
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      rows.each { yield(_1[index]) }
      self
    end

    def each_index(&block)
      return to_enum(__method__) unless block_given?
      rows.each_index { yield(_1) }
    end

    def map!(&block) = rows.each { _1[index] = yield(_1[index]) }

    # sample some cells to infer column type
    def type = detect_type
    memo_wise :type

    def alignment
      case type
      when :float, :int then :right
      else :left
      end
    end
    memo_wise :alignment

    def truncate(stop)
      @header = Util::Strings.truncate(header, stop)
      map! { Util::Strings.truncate(_1, stop) }
    end

    def measure
      [2, max_by(&:length)&.length, header.length].max
    end

    def detect_type
      samples = rows.sample(100).map { _1[index] }
      types = samples.filter_map { Util::What.what_is_it(_1) }.uniq.sort
      return types.first if types.length == 1
      return :float if types == %i[float int]
      :other
    end
  end
end
