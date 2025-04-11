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

    def detect_type
      sample = rows.sample(100).map { _1[name] }
      tally = sample.map do
        case _1
        when String
          case _1
          when /\A-?\d+\Z/ then :number
          when /\A-?\d+\.\d+\Z/ then :float
          when /\A(n\/a|na|none)\Z/i then :nil
          else; :string
          end
        when Float then :float
        when Numeric then :number
        when Date, Time then :date
        when nil then :nil
        else; :other
        end
      end.compact.tally.sort_by { [-_2, _1] }.to_h
      puts "#{header} => #{tally}"
      p sample.map { _1.nil? ? "nil" : _1.to_s }.sort.join(" ")
      puts
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
