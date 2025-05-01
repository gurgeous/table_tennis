module TableTennis
  class << self
    attr_accessor :defaults
  end

  # Table configuration options, with schema validation courtesy of MagicOptions.
  class Config < Util::MagicOptions
    OPTIONS = {
      color_scales: nil, # columns => color scale
      color: nil, # true/false/nil (detect)
      columns: nil, # array of symbols, or inferred from rows
      debug: false, # true for debug output
      delims: true, # true for numeric delimeters
      digits: 3, # format floats
      headers: nil, # columns => header strings, or inferred from columns
      layout: true, # true/false/int or hash of columns -> width. true to infer
      mark: nil, # lambda returning boolean or symbol to mark rows in output
      placeholder: "—", # placeholder for empty cells. default is emdash
      row_numbers: false, # show line numbers?
      save: nil, # csv file path to save the table when created
      search: nil, # string/regex to highlight in output
      separators: true, # if true, show separators between columns
      strftime: nil, # string for formatting dates
      theme: nil,  # :dark, :light or :ansi. :dark is the default
      title: nil, # string for table title, if any
      titleize: false, # if true, titleize column names
      zebra: false, # turn on zebra stripes
    }.freeze

    SCHEMA = {
      color_scales: ->(value) do
        if (error = Config.magic_validate!(value, {Symbol => Symbol}))
          error
        elsif value.values.any? { !Util::Scale::SCALES.include?(_1) }
          "values must be the name of a color scale"
        end
      end,
      color: :bool,
      columns: :symbols,
      debug: :bool,
      delims: :bool,
      digits: (0..10),
      headers: {sym: :str},
      layout: -> do
        return if _1 == true || _1 == false || _1.is_a?(Integer)
        Config.magic_validate!(_1, {Symbol => Integer})
      end,
      mark: :proc,
      placeholder: :str,
      row_numbers: :bool,
      save: :str,
      search: -> do
        if !(_1.is_a?(String) || _1.is_a?(Regexp))
          "expected string/regex"
        end
      end,
      separators: :bool,
      strftime: :str,
      theme: %i[dark light ansi],
      title: :str,
      titleize: :bool,
      zebra: :bool,
    }

    def initialize(options = {}, &block)
      super(SCHEMA)

      # preprocess
      options = [OPTIONS, TableTennis.defaults, options].reduce { _1.merge(_2 || {}) }
      options[:color] = Config.detect_color? if options[:color].nil?
      if (value = options[:color_scales])
        case value
        when Array then value = value.to_h { [_1, :g] }
        when Symbol then value = {value => :g}
        end
        options[:color_scales] = value
      end
      options[:debug] = true if ENV["TT_DEBUG"]
      options[:placeholder] = "" if options[:placeholder].nil?
      options[:theme] = Config.detect_theme if options[:theme].nil?
      options[:title] = options[:title].to_s if options[:title].is_a?(Symbol)
      update!(options)

      yield self if block_given?
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
  end
end
