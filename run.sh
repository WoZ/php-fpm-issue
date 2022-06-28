#!/usr/bin/env bash

set -e

# Styles
IC="\e[34m" # - info
SC="\e[32m" # - success
EC="\e[31m" # - error
AC="\e[33m" # - alert
CC="\e[0m"  #  - END (marker)

function help() {
  echo -e "${IC}Commands:${CC}"
  echo -e "  ${SC}help              ${CC}- Show all information about available commands."
  echo -e "  ${SC}reload.nginx      ${CC}- Send reload signal to nginx"
  echo -e "  ${SC}reload.php-fpm    ${CC}- Send reload signal to php-fpm"
  echo -e "  ${SC}sh.php-fpm        ${CC}- Gives shell in the php-fpm container"
  echo -e "  ${SC}log.php-fpm       ${CC}- Makes tail -f of the log file specified in the php-fpm error_log directive"
}

reload.nginx() {
  docker-compose exec nginx nginx -s reload
}

reload.php-fpm() {
  docker-compose exec php-fpm sh -c 'kill -USR2 `cat /usr/local/var/run/php-fpm.pid`'
}

log.php-fpm() {
  docker-compose exec php-fpm tail -f /usr/local/var/log/php-fpm.log
}

sh.php-fpm() {
  docker-compose exec php-fpm sh
}

if [ "$(type -t $1)" = "function" ]; then
  $@
else
  help
fi
