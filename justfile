
# read gem version
gemver := `grep -Eo "[0-9]+\.[0-9]+\.[0-9]+" lib/table_manners/version.rb`

#
# dev
#

default:
  @just --list

check: lint test

ci: check

demo-watch *ARGS:
  @watchexec --stop-timeout=0 --clear clear table-manners-demo {{ARGS}}

format:
  @just banner format...
  bundle exec rubocop -a

image_optim:
  @bundle exec image_optim --allow-lossy --svgo-precision=1 -r .

lint:
  @just banner lint...
  bundle exec rubocop

pry:
  bundle exec pry -I lib -r table_manners.rb

test *ARGS:
  @just banner rake test {{ARGS}}
  @bundle exec rake test {{ARGS}}

test-watch *ARGS:
  @watchexec --stop-timeout=0 --clear clear just test "{{ARGS}}"

#
# coverage/profiling
#

coverage:
  COVERAGE=1 just test
  open /tmp/coverage/index.html

#
# gem tasks
#

# you can test locally from another project by dropping gem file into vendor/cache
gem-push: check-git-status
  @just banner gem build...
  gem build table_manners.gemspec
  @just banner tag...
  git tag -a "v{{gemver}}" -m "Tagging {{gemver}}"
  git push --tags
  @just banner gem push...
  gem push "table_manners-{{gemver}}.gem"

#
# util
#

banner *ARGS: (_banner BG_GREEN ARGS)
warning *ARGS: (_banner BG_YELLOW ARGS)
fatal *ARGS: (_banner BG_RED ARGS)
  @exit 1
_banner color *ARGS:
  @msg=$(printf "[%s] %s" $(date +%H:%M:%S) "{{ARGS}}") ; \
  printf "{{color+BOLD+WHITE}}%-72s{{ NORMAL }}\n" "$msg"

check-git-status:
  @if [ ! -z "$(git status --porcelain)" ]; then just fatal "git status is dirty, bailing."; fi
