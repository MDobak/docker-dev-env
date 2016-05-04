#!/usr/bin/env bash
service apache2 start
service php5-fpm start

while true; do sleep 100000; done
