module TableTennis
  #
  # A single column in a table. The data is actually stored in the rows, but it
  # can be enumerated from here. Mostly used for layout calculations.
  #

  class Column
    include Enumerable
    extend Forwardable
    prepend MemoWise

    attr_reader :name, :data
    attr_accessor :header, :width
    def_delegators :data, *%i[rows]

    def initialize(name, data)
      @name, @data = name, data
      @header = name.to_s
      if data&.config&.titleize?
        @header = Util::Strings.titleize(@header)
      end
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      rows.each { yield(_1[name]) }
      self
    end

    def each_index(&block)
      return to_enum(__method__) unless block_given?
      rows.each_index { yield(_1) }
    end

    def map!(&block) = rows.each { _1[name] = yield(_1[name]) }

    def sample(n = 1)
      rows.sample(n).map { _1[name] }
    end

    # Sample 100 cells to infer column type. Ignore nils entirely.
    def type
      samples = sample(100)
      types = samples.filter_map { Util::What.what_is_it(_1) }
      # puts "#{name} => #{samples.sort_by(&:to_s)} #{types.tally}"
      types = types.uniq.sort
      return nil if types.empty? # all nils
      return types.first if types.length == 1 # one type
      return :float if types == %i[float int] # floats + numbers
      :mixed
    end
    memo_wise :type

    def truncate(stop)
      @header = Util::Strings.truncate(header, stop)
      map! { Util::Strings.truncate(_1, stop) }
    end

    def measure
      [2, max_by(&:length)&.length, header.length].max
    end
  end
end
