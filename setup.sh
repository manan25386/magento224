#!/bin/bash

#[ "$DEBUG" = "true" ] && set -eo pipefail
#[ "$DEBUG" = "true" ] && set -x
set -e

COMMAND="$@"

# Measure the time it takes to bootstrap the container
START=`date +%s`

# Set the base Magento command to bin/magento
CMD_MAGENTO="bin/magento" && chmod +x $CMD_MAGENTO

echo "Working Directoryy"
pwd

#php composer.phar self-update --2

php composer.phar --version

echo "Compose Install"
php -d memory_limit=-1 composer.phar install

echo "Running upgrade.."
$CMD_MAGENTO se:up

#echo "Set Production Mode"
$CMD_MAGENTO deploy:mode:set production --skip-compilation

#echo "Code compilation"
#$CMD_MAGENTO se:di:compile

echo "Deploying static content"
$CMD_MAGENTO s:s:d -f

echo "Code compilation"
$CMD_MAGENTO se:d:c

echo "Cache Clean"
$CMD_MAGENTO c:clean

echo "Cache Flush"
$CMD_MAGENTO c:flush

find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;

chmod u+x bin/magento

find var/page_cache var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var/page_cache var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

#echo "Give Permission to pub/static"
chmod -R 0777 pub/static/

#echo "Give Permission to var"
chmod -R 0777 var/

#echo "Give Permission to pub/media"
chmod -R 0777 pub/media/

#echo "Give Permission to vendor"
chmod -R 0777 vendor/

#echo "Give Permission to var log import folder"
#chmod -R 0777 pub/media/log/import/

#echo "Give Permission to var log import folder"
#chmod -R 0777 var/log/import/

END=`date +%s`
RUNTIME=$((END-START))
echo "Startup preparation finished in ${RUNTIME} seconds"

