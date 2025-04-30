#
# Welcome to TableTennis! Use as follows:
#
# puts TableTennis.new(array_of_hashes, options = {})
#

module TableTennis
  # Public API for TableTennis.
  class Table
    extend Forwardable
    include Util::Inspectable

    attr_reader :data
    def_delegators :data, *%i[column_names columns config rows]
    def_delegators :data, *%i[debug debug_if_slow]

    # Create a new table with options (see Config or README). This is typically
    # called using TableTennis.new.
    def initialize(rows, options = {}, &block)
      config = Config.new(options, &block)
      @data = TableData.new(config:, rows:)
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
        rows.each do |row|
          # strip hyperlinks
          row = row.map do |value|
            if value.is_a?(String) && (h = Util::Strings.hyperlink(value))
              value = h[1]
            end
            value
          end
          csv << row
        end
      end
    end

    # Calls render to convert the table to a string.
    def to_s
      StringIO.new.tap { render(_1) }.string
    end

    protected

    # we cnan do a bit more config checking now
    def sanity!
      %i[color_scales headers layout].each do |key|
        next if !config[key].is_a?(Hash)
        next if rows.empty? # ignore on empty data
        invalid = config[key].keys - data.column_names
        if !invalid.empty?
          raise ArgumentError, "#{key} columns `#{invalid.join(", ")}` not in (#{column_names})"
        end
      end
    end
  end

  class << self
    #
    # Welcome to TableTennis! Use as follows:
    #
    # puts TableTennis.new(array_of_hashes_or_records, options = {})
    #
    def new(*args, &block) = Table.new(*args, &block)
  end
end
