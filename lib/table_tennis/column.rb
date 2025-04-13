module TableTennis
  # A single column in a table. The data is actually stored in the rows, but it
  # can be enumerated from here.
  class Column
    include Enumerable
    include Util::Inspectable
    extend Forwardable

    # c is the column index
    attr_reader :name, :data, :c
    attr_accessor :header, :width
    def_delegators :data, *%i[rows]

    def initialize(data, name, c)
      @name, @data, @c = name, data, c
      @header = name.to_s
      if data&.config&.titleize?
        @header = Util::Strings.titleize(@header)
      end
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      rows.each { yield(_1[c]) }
      self
    end

    def map!(&block) = rows.each { _1[c] = yield(_1[c]) }

    # sample some cells to infer column type
    def type = @type ||= detect_type

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

    # sample some cells to infer column type
    def type = @type ||= detect_type

    protected

    def detect_type
      samples = rows.sample(100).map { _1[c] }
      types = samples.filter_map { Util::What.what_is_it(_1) }.uniq.sort
      return types.first if types.length == 1
      return :float if types == %i[float int]
      :other
    end
  end
end
