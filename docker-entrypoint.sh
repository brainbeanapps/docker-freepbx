#!/bin/bash

terminate() {
  trap - SIGINT SIGTERM
  kill $$
}

ensure_process() {
  pid_length=`pidof $1|awk '{print length($0)}'`
  if [ "$pid_length" == "0" -a "$pid_length" != "" ]; then
    echo "Process '$1' not found, aborting!"
    terminate
  fi
}

start_cron() {
  crond -s
}

stop_cron() {
  kill `pidof crond`
}

start_mysql() {
  mysqld_safe > /dev/null 2>&1 &
  sleep 5
  ensure_process mysqld
}

stop_mysql() {
  mysqladmin --socket=/var/lib/mysql/mysql.sock shutdown
}

start_freepbx() {
  fwconsole start --no-interaction -vv
  sleep 5
  ensure_process asterisk
}

stop_freepbx() {
  fwconsole stop --immediate --maxwait=60 --no-interaction -vv
}

start_httpd() {
  httpd -k start
  sleep 5
  ensure_process httpd
}

stop_httpd() {
  httpd -k graceful-stop
}

on_exit() {
    echo "Stopping services..."

    stop_httpd
    stop_freepbx
    stop_mysql
    stop_cron

    echo "Shutting down..."

    terminate
}
trap on_exit SIGINT SIGTERM

echo "Starting services..."

start_cron
start_mysql
start_freepbx
start_httpd

echo "Services started"

fwconsole dbug &

sleep infinity
