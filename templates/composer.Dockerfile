# Copy core, skins and extensions
COPY --from=core $MW_HOME $MW_HOME
COPY --from=skins $MW_HOME/skins $MW_HOME/skins
COPY --from=extensions $MW_HOME/extensions $MW_HOME/extensions

# Composer dependencies
COPY _sources/configs/composer.wikiteq.json $MW_HOME/composer.local.json
# Run with secret mounted to /run/secrets/COMPOSER_TOKEN
# This is needed to bypass rate limits
RUN --mount=type=secret,id=COMPOSER_TOKEN cd $MW_HOME && \
	cp composer.json composer.json.bak && \
	cat composer.json.bak | jq '. + {"minimum-stability": "dev"}' > composer.json && \
	rm composer.json.bak && \
	cp composer.json composer.json.bak && \
	cat composer.json.bak | jq '. + {"prefer-stable": true}' > composer.json && \
	rm composer.json.bak && \
	composer clear-cache && \
	# configure auth
	if [ -f "/run/secrets/COMPOSER_TOKEN" ]; then composer config -g github-oauth.github.com $(cat /run/secrets/COMPOSER_TOKEN); fi && \
	composer update --no-dev --with-dependencies && \
	composer clear-cache && \
	# deauth
	composer config -g --unset github-oauth.github.com

# Move files around
RUN set -x; \
	# Move files to $MW_ORIGIN_FILES directory
	mv $MW_HOME/images $MW_ORIGIN_FILES/ && \
	mv $MW_HOME/cache $MW_ORIGIN_FILES/ && \
	# Create symlinks from $MW_VOLUME to the wiki root for images and cache directories
	ln -s $MW_VOLUME/images $MW_HOME/images && \
	ln -s $MW_VOLUME/cache $MW_HOME/cache
