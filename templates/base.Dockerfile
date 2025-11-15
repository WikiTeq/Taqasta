ENV MW_VERSION=REL1_43 \
	MW_CORE_VERSION=1.43.5 \
	WWW_ROOT=/var/www/mediawiki \
	MW_HOME=/var/www/mediawiki/w \
	MW_LOG=/var/log/mediawiki \
	MW_ORIGIN_FILES=/mw_origin_files \
	MW_VOLUME=/mediawiki \
	MW_IMPORT_VOLUME=/import \
	WWW_USER=www-data \
	WWW_GROUP=www-data \
	APACHE_LOG_DIR=/var/log/apache2

# Apt and Aptitude setup
RUN set x; \
	apt-get clean && \
	apt-get update && \
	apt-get --no-install-recommends install -y aptitude && \
	aptitude -y upgrade

# System setup
RUN set x; \
	aptitude --without-recommends install -y \
	git \
	inotify-tools \
	apache2 \
	software-properties-common \
	gpg \
	apt-transport-https \
	ca-certificates \
	wget \
	imagemagick  \
	librsvg2-bin \
	python3-pygments \
	msmtp \
	msmtp-mta \
	patch \
	vim \
	mc \
	nano \
	ffmpeg \
	curl \
	iputils-ping \
	unzip \
	gnupg \
	default-mysql-client \
	rsync \
	lynx \
	poppler-utils \
	lsb-release

RUN set x; \
	wget -q -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list && \
	aptitude update && \
	aptitude install -y \
	php8.3 \
	php8.3-mysql \
	php8.3-cli \
	php8.3-gd \
	php8.3-mbstring \
	php8.3-xml \
	php8.3-mysql \
	php8.3-intl \
	php8.3-opcache \
	php8.3-apcu \
	php8.3-redis \
	php8.3-curl \
	php8.3-tidy \
	php8.3-zip \
	php8.3-xhprof \
	# Lua sandbox
	php-pear \
	php8.3-dev \
	liblua5.1-0 \
	liblua5.1-0-dev \
	monit \
	zip \
	weasyprint \
	pandoc \
	clamav \
	exiv2 \
	libimage-exiftool-perl \
	ploticus \
	djvulibre-bin \
	fonts-hosny-amiri \
	jq && \
	#	xvfb \ + 14.9 MB
	#	lilypond \ + 301 MB
	pecl -d php_suffix=8.3 install luasandbox && \
	pecl -d php_suffix=8.3 install excimer

RUN set x; \
	aptitude -y remove php-pear php8.3-dev liblua5.1-0-dev && \
	aptitude clean && \
	rm -rf /var/lib/apt/lists/*

# FORCE USING PHP 8.3 (same for phar)
# For some reason sury provides other versions, see
# https://github.com/oerdnj/deb.sury.org/wiki/Frequently-Asked-Questions
RUN set -x; \
	update-alternatives --set php /usr/bin/php8.3 && \
	update-alternatives --set phar /usr/bin/phar8.3 && \
	update-alternatives --set phar.phar /usr/bin/phar.phar8.3

# Post install configuration
RUN set -x; \
	# Remove default config
	rm /etc/apache2/sites-enabled/000-default.conf && \
	rm /etc/apache2/sites-available/000-default.conf && \
	rm -rf /var/www/html && \
	# Enable rewrite module
	a2enmod rewrite && \
	# Create directories
	mkdir -p $MW_HOME && \
	mkdir -p $MW_LOG && \
	mkdir -p $MW_ORIGIN_FILES && \
	mkdir -p $MW_VOLUME

# Composer
RUN set -x; \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
	composer self-update 2.1.3
