module TableTennis
  module Stage
    # Base class for each stage of the rendering pipeline, mostly here just to
    # delegate to TableData.
    class Base
      extend Forwardable
      prepend MemoWise
      include Util::Inspectable

      attr_reader :data
      def_delegators :data, *%i[column_names columns config input_rows rows theme]
      def_delegators :data, *%i[debug debug_if_slow]

      def initialize(data) = @data = data
    end
  end
end
