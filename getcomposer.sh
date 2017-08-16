#!/bin/sh

PHP=${1:-`which php`}

EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
$PHP -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$($PHP -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

$PHP composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
RESULT=$?

rm composer-setup.php
exit $RESULT
