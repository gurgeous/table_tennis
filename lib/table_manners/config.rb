module TableManners
  class << self
    attr_accessor :defaults
  end

  # Store the table configuration options, with lots of validation.
  class Config
    OPTIONS = {
      color_scales: nil, # columns => color scale
      color: nil, # true/false/nil (detect)
      columns: nil, # array of symbols, or inferred from rows
      debug: false, # true for debug output
      digits: 3, # format floats
      layout: true, # true/false/int or hash of columns -> width. true to infer
      mark: nil, # lambda returning boolean or symbol to mark rows in output
      placeholder: "—", # placeholder for empty cells. default is emdash
      row_numbers: false, # show line numbers?
      save: nil, # csv file path to save the table when created
      search: nil, # string/regex to highlight in output
      strftime: nil, # string for formatting dates
      theme: nil,  # :dark, :light or :ansi. :dark is the default
      title: nil, # string for table title, if any
      zebra: false, # turn on zebra stripes
    }.freeze

    def initialize(options = {}, &block)
      options = [OPTIONS, TableManners.defaults, options].reduce { _1.merge(_2 || {}) }
      options[:color] = Config.detect_color? if options[:color].nil?
      options[:theme] = Config.detect_theme if options[:theme].nil?
      options[:debug] = true if ENV["TM_DEBUG"]
      options.each { self[_1] = _2 }

      yield self if block_given?
    end

    # readers
    attr_reader(*OPTIONS.keys)

    #
    # simple writers
    #

    {
      color: :bool,
      debug: :bool,
      digits: :int,
      mark: :proc,
      placeholder: :str,
      row_numbers: :bool,
      save: :str,
      strftime: :str,
      title: :str,
      zebra: :bool,
    }.each do |option, type|
      define_method(:"#{option}=") do |value|
        instance_variable_set(:"@#{option}", send(:"_#{type}", option, value))
      end
      alias_method(:"#{option}?", option) if type == :bool
    end

    #
    # helpers
    #

    # is this a dark terminal?
    def self.terminal_dark?
      if (bg = Util::Termbg.bg)
        Util::Colors.dark?(bg)
      end
    end

    def self.detect_color?
      return false if ENV["NO_COLOR"] || ENV["CI"]
      return true if ENV["FORCE_COLOR"] == "1"
      return false if !($stdout.tty? && $stderr.tty?)
      Paint.detect_mode > 0
    end

    def self.detect_theme
      case terminal_dark?
      when true, nil then :dark
      when false then :light
      end
    end

    #
    # complex writers
    #

    def color_scales=(value)
      @color_scales = validate(:color_scales, value) do
        if !value.is_a?(Hash)
          "expected hash"
        elsif value.keys.any? { !_1.is_a?(Symbol) }
          "keys must be symbols"
        elsif value.values.any? { !_1.is_a?(Symbol) }
          "values must be symbols"
        elsif value.values.any? { !Util::Scale::SCALES.include?(_1) }
          "values must be the name of a color scale"
        end
      end
    end

    def columns=(value)
      @columns = validate(:columns, value) do
        if !(value.is_a?(Array) && !value.empty? && value.all? { _1.is_a?(Symbol) })
          "expected array of symbols"
        end
      end
    end

    def theme=(value)
      @theme = validate(:theme, value) do
        if !value.is_a?(Symbol)
          "expected symbol"
        elsif !Theme::THEMES.key?(value)
          "expected one of #{Theme::THEMES.keys.inspect}"
        end
      end
    end

    def search=(value)
      @search = validate(:search, value) do
        if !(value.is_a?(String) || value.is_a?(Regexp))
          "expected string/regex"
        end
      end
    end

    def layout=(value)
      @layout = validate(:layout, value) do
        next if [true, false].include?(value) || value.is_a?(Integer)
        if !value.is_a?(Hash)
          "expected boolean, int or hash"
        elsif value.keys.any? { !_1.is_a?(Symbol) }
          "keys must be symbols"
        elsif value.values.any? { !_1.is_a?(Integer) }
          "values must be ints"
        end
      end
    end

    def [](key)
      raise ArgumentError, "unknown TableManners.#{key}" if !respond_to?(key)
      send(key)
    end

    def []=(key, value)
      raise ArgumentError, "unknown TableManners.#{key}=" if !respond_to?(:"#{key}=")
      send(:"#{key}=", value)
    end

    def inspect
      options = to_h.map { "@#{_1}=#{_2.inspect}" }.join(", ")
      "#<Config #{options}>"
    end

    def to_h
      OPTIONS.keys.to_h { [_1, self[_1]] }.compact
    end

    protected

    #
    # validations
    #

    def validate(option, value, &block)
      if value != nil && (error = yield)
        raise ArgumentError, "TableManners.#{option} #{error}, got #{value.inspect}"
      end
      value
    end

    def _bool(option, value)
      value = case value
      when true, 1, "1", "true" then true
      when false, 0, "", "0", "false" then false
      else; value # this will turn into an error down below
      end
      validate(option, value) do
        "expected boolean" if ![true, false].include?(value)
      end
    end

    def _int(option, value)
      validate(option, value) do
        if !value.is_a?(Integer)
          "expected int"
        elsif value < 0
          "expected positive int"
        end
      end
    end

    def _proc(option, value)
      validate(option, value) do
        "expected proc" if !value.is_a?(Proc)
      end
    end

    def _str(option, value)
      value = value.to_s if option == :title && value.is_a?(Symbol)
      validate(option, value) do
        "expected string" if !value.is_a?(String)
      end
    end

    def _sym(option, value)
      validate(option, value) do
        "expected symbol" if !value.is_a?(Symbol)
      end
    end
  end
end
