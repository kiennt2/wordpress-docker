#!/bin/bash

# Install Composer
#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
#php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
#php composer-setup.php
#php -r "unlink('composer-setup.php');"
#chmod a+x composer.phar
#mv composer.phar /usr/local/bin/composer
curl https://getcomposer.org/composer.phar --output composer
chmod a+x composer
mv composer /usr/local/bin/composer

# Install PhpRedis
apk add autoconf build-base
yes '' | pecl install redis
bash -c "echo extension=redis.so > /usr/local/etc/php/conf.d/redis.ini"