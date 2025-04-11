# gems
require "csv"
require "ffi"
require "forwardable"
require "io/console"
require "memo_wise"
require "paint"
require "unicode/display_width"

# mixins must be at top
require "table_manners/util/inspectable"

require "table_manners/column"
require "table_manners/config"
require "table_manners/row"
require "table_manners/table_data"
require "table_manners/table"
require "table_manners/theme"

require "table_manners/stage/base"
require "table_manners/stage/format"
require "table_manners/stage/layout"
require "table_manners/stage/painter"
require "table_manners/stage/render"

require "table_manners/util/colors"
require "table_manners/util/scale"
require "table_manners/util/strings"
require "table_manners/util/termbg"
