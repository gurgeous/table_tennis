# show recipes
default:
  @just --list

# check repo - lint & test
check: lint test

# for ci
ci: check

# check test coverage
coverage:
  COVERAGE=1 just test
  open /tmp/coverage/index.html

# format with rubocop
format: (lint "-a")

gem-local:
  @just _banner rake install:local...
  bundle exec rake install:local

# this will tag, build and push to rubygems
gem-push: check
  @just rake release...
  rake release

# optimize images
image_optim:
  @# advpng/pngout are slow. consider --verbose as well
  @bundle exec image_optim --allow-lossy --svgo-precision=1 --no-advpng --no-pngout -r .

# lint with rubocop
lint *ARGS:
  @just _banner lint...
  bundle exec rubocop {{ARGS}}

# start pry with the lib loaded
pry:
  bundle exec pry -I lib -r table_tennis.rb

# run tennis repeatedly
tennis-watch *ARGS:
  @watchexec --stop-timeout=0 --clear clear tennis {{ARGS}}

# run tests
test *ARGS:
  @just _banner rake test {{ARGS}}
  @bundle exec rake test {{ARGS}}

# run tests repeatedly
test-watch *ARGS:
  watchexec --stop-timeout=0 --clear clear just test "{{ARGS}}"

#
# util
#

_banner *ARGS: (_message BG_GREEN ARGS)
_warning *ARGS: (_message BG_YELLOW ARGS)
_fatal *ARGS: (_message BG_RED ARGS)
  @exit 1
_message color *ARGS:
  @msg=$(printf "[%s] %s" $(date +%H:%M:%S) "{{ARGS}}") ; \
  printf "{{color+BOLD+WHITE}}%-72s{{ NORMAL }}\n" "$msg"
