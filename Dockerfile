FROM wordpress:6.8.1-fpm-alpine

COPY ./scripts/utils/wp-docker-utils.sh ./wp-docker-utils.sh
RUN chmod +x ./wp-docker-utils.sh
RUN bash ./wp-docker-utils.sh