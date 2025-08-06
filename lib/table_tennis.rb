# gems
require "csv"
require "ffi"
require "forwardable"
require "io/console"
require "memo_wise"
require "paint"
require "unicode/display_width"

# mixins must be at top
require "table_tennis/util/inspectable"
require "table_tennis/util/magic_options"

require "table_tennis/column"
require "table_tennis/config"
require "table_tennis/row"
require "table_tennis/table_data"
require "table_tennis/table"
require "table_tennis/theme"

require "table_tennis/stage/base"
require "table_tennis/stage/format"
require "table_tennis/stage/layout"
require "table_tennis/stage/painter"
require "table_tennis/stage/render"

require "table_tennis/util/colors"
require "table_tennis/util/console"
require "table_tennis/util/identify"
require "table_tennis/util/scale"
require "table_tennis/util/strings"
require "table_tennis/util/termbg"
