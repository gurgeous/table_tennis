#
# Welcome to TableManners! Use as follows:
#
# puts TableManners.new(array_of_hashes, options = {})
#
# See the README for details on options - _color_scales_, _color_, _columns_,
# _debug_, _digits_, _layout_, _mark_, _placeholder_, _row_numbers_, _save_,
# _search_, _strftime_, _theme_, _title_, _zebra_
#
# TODO
# - badge, gemspec, logo?, finish readme
#

module TableManners
  # Public API for TableManners.
  class Table
    extend Forwardable
    include Util::Inspectable

    attr_reader :data
    def_delegators :data, *%i[column_names columns config input_rows rows]
    def_delegators :data, *%i[debug debug_if_slow]

    # Create a new table with options (see Config or README). This is typically
    # called using TableManners.new.
    def initialize(input_rows, options = {}, &block)
      config = Config.new(options, &block)
      @data = TableData.new(config:, input_rows:)
      sanity!
      save(config.save) if config.save
    end

    # Render the table to $stdout or another IO object.
    def render(io = $stdout)
      %w[format layout painter render].each do |stage|
        args = [].tap do
          _1 << io if stage == "render"
        end
        Stage.const_get(stage.capitalize).new(data).run(*args)
      end
    end

    # Save the table as a CSV file. Users can also do this manually.
    def save(path)
      headers = column_names
      CSV.open(path, "wb", headers:, write_headers: true) do |csv|
        rows.each { csv << _1.values }
      end
    end

    # Calls render to convert the table to a string.
    def to_s
      StringIO.new.tap { render(_1) }.string
    end

    protected

    # we cnan do a bit more config checking now
    def sanity!
      %i[color_scales layout].each do |key|
        next if !config[key].is_a?(Hash)
        next if rows.empty? # ignore on empty data
        invalid = config[key].keys - data.column_names
        if !invalid.empty?
          raise ArgumentError, "#{key} columns `#{invalid.join(", ")}` not found in input data"
        end
      end
    end
  end

  class << self
    #
    # Welcome to TableManners! Use as follows:
    #
    # puts TableManners.new(array_of_hashes_or_records, options = {})
    #
    # See the README for details on options - _color_scales_, _color_,
    # _columns_, _debug_, _digits_, _layout_, _mark_, _placeholder_,
    # _row_numbers_, _save_, _search_, _strftime_, _theme_, _title_, _zebra_
    def new(*args, &block) = Table.new(*args, &block)
  end
end
