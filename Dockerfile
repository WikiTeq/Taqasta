FROM debian:12.5 as base

LABEL maintainers="pavel@wikiteq.com,alexey@wikiteq.com"
LABEL org.opencontainers.image.source=https://github.com/WikiTeq/Taqasta

ENV MW_VERSION=REL1_41 \
	MW_CORE_VERSION=1.41.0 \
	WWW_ROOT=/var/www/mediawiki \
	MW_HOME=/var/www/mediawiki/w \
	MW_LOG=/var/log/mediawiki \
	MW_ORIGIN_FILES=/mw_origin_files \
	MW_VOLUME=/mediawiki \
	MW_IMPORT_VOLUME=/import \
	WWW_USER=www-data \
	WWW_GROUP=www-data \
	APACHE_LOG_DIR=/var/log/apache2

# System setup
RUN set x; \
	apt-get clean \
	&& apt-get update \
	&& apt-get --no-install-recommends install -y aptitude \
	&& aptitude -y upgrade \
	&& aptitude --without-recommends install -y \
	git \
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
	lsb-release \
	&& wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
	&& echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list \
	&& aptitude update \
	&& aptitude install -y \
	php8.1 \
	php8.1-mysql \
	php8.1-cli \
	php8.1-gd \
	php8.1-mbstring \
	php8.1-xml \
	php8.1-mysql \
	php8.1-intl \
	php8.1-opcache \
	php8.1-apcu \
	php8.1-redis \
	php8.1-curl \
	php8.1-tidy \
	php8.1-zip \
	php8.1-tideways \
# Lua sandbox
	php-pear \
	php8.1-dev \
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
	jq \
#    xvfb \ + 14.9 MB
#    lilypond \ + 301 MB
	&& pecl -d php_suffix=8.1 install luasandbox \
	&& aptitude -y remove php-pear php8.1-dev liblua5.1-0-dev \
	&& aptitude clean \
	&& rm -rf /var/lib/apt/lists/*

# FORCE USING PHP 8.1 (same for phar)
# For some reason sury provides other versions, see
# https://github.com/oerdnj/deb.sury.org/wiki/Frequently-Asked-Questions
RUN set -x; \
	update-alternatives --set php /usr/bin/php8.1 \
	&& update-alternatives --set phar /usr/bin/phar8.1 \
	&& update-alternatives --set phar.phar /usr/bin/phar.phar8.1

# Post install configuration
RUN set -x; \
	# Remove default config
	rm /etc/apache2/sites-enabled/000-default.conf \
	&& rm /etc/apache2/sites-available/000-default.conf \
	&& rm -rf /var/www/html \
	# Enable rewrite module
	&& a2enmod rewrite \
	# Create directories
	&& mkdir -p $MW_HOME \
	&& mkdir -p $MW_LOG \
	&& mkdir -p $MW_ORIGIN_FILES \
	&& mkdir -p $MW_VOLUME

# Composer
RUN set -x; \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
	&& composer self-update 2.1.3

FROM base as core
# MediaWiki core
RUN set -x; \
	git clone --depth 1 -b $MW_CORE_VERSION https://gerrit.wikimedia.org/r/mediawiki/core.git $MW_HOME \
	&& cd $MW_HOME \
	&& git submodule update --init --recursive

# Add Bootstrap to LocalSettings.php if the web installer added the Chameleon skin
COPY _sources/patches/core-local-settings-generator.patch /tmp/core-local-settings-generator.patch
RUN set -x; \
	cd $MW_HOME \
	&& git apply /tmp/core-local-settings-generator.patch

# Patch composer
RUN set -x; \
	sed -i 's="monolog/monolog": "2.2.0",="monolog/monolog": "^2.2",=g' $MW_HOME/composer.json

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME \
	&& find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

FROM base as skins
# Skins
# The Minerva Neue, MonoBook, Timeless, Vector and Vector 2022 skins are bundled into MediaWiki and do not need to be
# separately installed.
# The Chameleon skin is downloaded via Composer and also does not need to be installed.
RUN set -x; \
	mkdir $MW_HOME/skins \
	&& cd $MW_HOME/skins \
	# CologneBlue
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/CologneBlue $MW_HOME/skins/CologneBlue \
	&& cd $MW_HOME/skins/CologneBlue \
	&& git checkout -q fe6c7d9fb263f4fb7253e0fc0c9291f9f212170c \
	# Modern
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Modern $MW_HOME/skins/Modern \
	&& cd $MW_HOME/skins/Modern \
	&& git checkout -q fcf8856aeaffb89eb5f58beec410bd629873223a \
	# Pivot
	&& git clone -b v2.3.0 https://github.com/wikimedia/mediawiki-skins-Pivot $MW_HOME/skins/pivot \
	&& cd $MW_HOME/skins/pivot \
	&& git checkout -q c8096030792a90b9cc3703d9128cdbd78e04e1bf \
	# Refreshed
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed $MW_HOME/skins/Refreshed \
	&& cd $MW_HOME/skins/Refreshed \
	&& git checkout -q b111ee5e480de4c2e9a7812ce7fa4025d8c4cb4d

# TODO send to upstream, see https://wikiteq.atlassian.net/browse/MW-64 and https://wikiteq.atlassian.net/browse/MW-81
COPY _sources/patches/skin-refreshed.patch /tmp/skin-refreshed.patch
COPY _sources/patches/skin-refreshed-737080.diff /tmp/skin-refreshed-737080.diff
RUN set -x; \
	cd $MW_HOME/skins/Refreshed \
	&& patch -u -b includes/RefreshedTemplate.php -i /tmp/skin-refreshed.patch \
	# TODO remove me when https://gerrit.wikimedia.org/r/c/mediawiki/skins/Refreshed/+/737080 merged
	# Fix PHP Warning in RefreshedTemplate::makeElementWithIconHelper()
	&& git apply /tmp/skin-refreshed-737080.diff

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/skins \
	&& find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

FROM base as extensions
# Extensions
#
# The following extensions are bundled into MediaWiki and do not need to be separately installed (though in some cases
# they are modified): AbuseFilter, CategoryTree, Cite, CiteThisPage, CodeEditor, ConfirmEdit, DiscussionTools,
# Echo, Gadgets, ImageMap, InputBox, Interwiki, Linter, LoginNotify, Math, MultimediaViewer, Nuke, OATHAuth,
# PageImages, ParserFunctions, PdfHandler, Poem, ReplaceText, Scribunto, SecureLinkFixer, SpamBlacklist,
# SyntaxHighlight_GeSHi, TemplateData, TextExtracts, Thanks, TitleBlacklist, VisualEditor, WikiEditor
#
# The following extensions are downloaded via Composer and also do not need to be downloaded here: Bootstrap,
# BootstrapComponents, Maps, Mermaid, Semantic Breadcrumb Links, Semantic Compound Queries, Semantic Extra Special
# Properties, Semantic MediaWiki (along with all its helper library extensions, like DataValues), Semantic Result
# Formats, Semantic Scribunto, SimpleBatchUpload, SubPageList.

# A
RUN set -x; \
	mkdir $MW_HOME/extensions \
	&& cd $MW_HOME/extensions \
	# AdminLinks (v. 0.6.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/AdminLinks $MW_HOME/extensions/AdminLinks \
	&& cd $MW_HOME/extensions/AdminLinks \
	&& git checkout -q 42c3589e1c1f7f11704da2c22c82819b2b0aa7c9 \
	# AdvancedSearch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AdvancedSearch $MW_HOME/extensions/AdvancedSearch \
	&& cd $MW_HOME/extensions/AdvancedSearch \
	&& git checkout -q 38265547dce9d4cb6b6533437d9648080a8ee7cd \
	# AJAXPoll
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AJAXPoll $MW_HOME/extensions/AJAXPoll \
	&& cd $MW_HOME/extensions/AJAXPoll \
	&& git checkout -q 8d6e7726c15bbe4b1bdb392e1f56a100786247e0 \
	# AntiSpoof
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AntiSpoof $MW_HOME/extensions/AntiSpoof \
	&& cd $MW_HOME/extensions/AntiSpoof \
	&& git checkout -q 516f58e4c427b4520d22de8319c17c4bbc8f8379 \
	# ApprovedRevs (v. 2.0)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/ApprovedRevs $MW_HOME/extensions/ApprovedRevs \
	&& cd $MW_HOME/extensions/ApprovedRevs \
	&& git checkout -q 32bb8e08a7f2cc91007ad68baa21659697d9f960 \
	# Arrays
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Arrays $MW_HOME/extensions/Arrays \
	&& cd $MW_HOME/extensions/Arrays \
	&& git checkout -q 5945b6cee9f78c81534787adc6ee2cd92eb23d02

# B
RUN set -x; \
	cd $MW_HOME/extensions \
 	# BetaFeatures
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BetaFeatures $MW_HOME/extensions/BetaFeatures \
	&& cd $MW_HOME/extensions/BetaFeatures \
	&& git checkout -q 09a28fa7d56278cfd032f545f93256382cd12858 \
	# BreadCrumbs2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BreadCrumbs2 $MW_HOME/extensions/BreadCrumbs2 \
	&& cd $MW_HOME/extensions/BreadCrumbs2 \
	&& git checkout -q 6eb08e358aea2bef025c54dec87ecf0b4a49d009

# C
RUN set -x; \
	cd $MW_HOME/extensions \
	# Cargo (v. 3.5.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/Cargo $MW_HOME/extensions/Cargo \
	&& cd $MW_HOME/extensions/Cargo \
	&& git checkout -q a2865938165c1389d852df762f8c85073859e5dd \
	# CharInsert
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CharInsert $MW_HOME/extensions/CharInsert \
	&& cd $MW_HOME/extensions/CharInsert \
	&& git checkout -q 266ed2a0f5f4e9a2df6f2b6b1cffa60a62601a0b \
	# CheckUser
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CheckUser $MW_HOME/extensions/CheckUser \
	&& cd $MW_HOME/extensions/CheckUser \
	&& git checkout -q 89708a8892a9dffd8e74d342d2c6b94aa789a295 \
	# CirrusSearch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch $MW_HOME/extensions/CirrusSearch \
	&& cd $MW_HOME/extensions/CirrusSearch \
	&& git checkout -q 205ff14dd91597822b90c9bf3985b4187f8c37c6 \
	# CodeMirror
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror $MW_HOME/extensions/CodeMirror \
	&& cd $MW_HOME/extensions/CodeMirror \
	&& git checkout -q f833cc4e370c8caff8922c59f92ad7f5d0926ef4 \
	# Collection
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Collection $MW_HOME/extensions/Collection \
	&& cd $MW_HOME/extensions/Collection \
	&& git checkout -q 1107e64570497ba9fc139fded698ac1ded7f96d0 \
	# CommentStreams
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommentStreams $MW_HOME/extensions/CommentStreams \
	&& cd $MW_HOME/extensions/CommentStreams \
	&& git checkout -q 72652e1d7a1d65d497131194988b2973593b3f2c \
	# CommonsMetadata
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommonsMetadata $MW_HOME/extensions/CommonsMetadata \
	&& cd $MW_HOME/extensions/CommonsMetadata \
	&& git checkout -q 915e8b135ae70377a4fecf6908d36ab5af377289 \
	# ConfirmAccount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmAccount $MW_HOME/extensions/ConfirmAccount \
	&& cd $MW_HOME/extensions/ConfirmAccount \
	&& git checkout -q 039ed86754ec8178a3b2add32114d6d08bef405e \
	# ContactPage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContactPage $MW_HOME/extensions/ContactPage \
	&& cd $MW_HOME/extensions/ContactPage \
	&& git checkout -q b275bebad79670fd4662494e62eed58b17b8ed52 \
	# ContributionScores
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores $MW_HOME/extensions/ContributionScores \
	&& cd $MW_HOME/extensions/ContributionScores \
	&& git checkout -q 645c9459940e88125cc1685cb65cd391b7f58ac8 \
	# CookieWarning
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CookieWarning $MW_HOME/extensions/CookieWarning \
	&& cd $MW_HOME/extensions/CookieWarning \
	&& git checkout -q 291d086660c6c99a39673f80b929fa818dd9bfbe \
	# Cloudflare
	&& git clone --single-branch -b master https://github.com/harugon/mediawiki-extensions-cloudflare.git $MW_HOME/extensions/Cloudflare \
	&& cd $MW_HOME/extensions/Cloudflare \
	&& git checkout -q fc17309a510b4d9b2eb5cc215b83b258958c8ada

# D
RUN set -x; \
	cd $MW_HOME/extensions \
	# DataTransfer
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DataTransfer $MW_HOME/extensions/DataTransfer \
	&& cd $MW_HOME/extensions/DataTransfer \
	&& git checkout -q 7f0050b0d2f2088a21f2a193ffce725042a8cdc5 \
	# DeleteBatch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DeleteBatch $MW_HOME/extensions/DeleteBatch \
	&& cd $MW_HOME/extensions/DeleteBatch \
	&& git checkout -q 4ccc6d5b6f3c43770c554fa26b4f6bf2035ece1f \
	# Description2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 $MW_HOME/extensions/Description2 \
	&& cd $MW_HOME/extensions/Description2 \
	&& git checkout -q 0f5bf6147f967ce82a0c3f1ef3248b91e5b4b884 \
	# Disambiguator
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator $MW_HOME/extensions/Disambiguator \
	&& cd $MW_HOME/extensions/Disambiguator \
	&& git checkout -q a7fe9ee7c170428ca1242091d25ba08ba29225a8 \
	# DismissableSiteNotice
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DismissableSiteNotice $MW_HOME/extensions/DismissableSiteNotice \
	&& cd $MW_HOME/extensions/DismissableSiteNotice \
	&& git checkout -q d2c440817c9fa3e8b8ef167127b556c7249b4f56 \
	# DisplayTitle
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DisplayTitle $MW_HOME/extensions/DisplayTitle \
	&& cd $MW_HOME/extensions/DisplayTitle \
	&& git checkout -q c485a2a89a1fd9cb6a4eda4f821de86b2a034f70 \
	# DynamicPageList3
	&& git clone --single-branch -b master https://github.com/Universal-Omega/DynamicPageList3.git $MW_HOME/extensions/DynamicPageList3 \
	&& cd $MW_HOME/extensions/DynamicPageList3 \
	&& git checkout -q 25c9fd08e68b558e40e089e17bd7ad15eb07f98b

# E
RUN set -x; \
	cd $MW_HOME/extensions \
	# Editcount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Editcount $MW_HOME/extensions/Editcount \
	&& cd $MW_HOME/extensions/Editcount \
	&& git checkout -q 0192d876745aea08b6b32e03813ff3250f0bf9dc \
	# Elastica
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica $MW_HOME/extensions/Elastica \
	&& cd $MW_HOME/extensions/Elastica \
	&& git checkout -q 324bd77d2f57bad12580230829c3df844aa8345e \
	# EmailAuthorization
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EmailAuthorization $MW_HOME/extensions/EmailAuthorization \
	&& cd $MW_HOME/extensions/EmailAuthorization \
	&& git checkout -q 8930a20a390eb6feb511c1960de8169c5899d7cf \
	# EmbedVideo
	# (Canasta uses hydrawiki, but we switched to StarCitizenWiki's fork which
	# which is maintained, WE-286)
	&& git clone --single-branch -b master https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo.git $MW_HOME/extensions/EmbedVideo \
	&& cd $MW_HOME/extensions/EmbedVideo \
	&& git checkout -q 5c03c031070981730a0e01aa3cbc3e5cbd1b88c1 \
	# EventLogging
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventLogging $MW_HOME/extensions/EventLogging \
	&& cd $MW_HOME/extensions/EventLogging \
	&& git checkout -q 93a7534999520fec8569f70b5083ee4883a6b5f8 \
	# EventStreamConfig
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventStreamConfig $MW_HOME/extensions/EventStreamConfig \
	&& cd $MW_HOME/extensions/EventStreamConfig \
	&& git checkout -q 295c58dcff3d49d2bfc6ad1292fc3dcb93952a96 \
	# ExternalData (v. 3.3)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/ExternalData $MW_HOME/extensions/ExternalData \
	&& cd $MW_HOME/extensions/ExternalData \
	&& git checkout -q 564932ba8606390f339291a626b67340af536c68

# F
RUN set -x; \
	cd $MW_HOME/extensions \
	# FlexDiagrams (v. 0.5.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/FlexDiagrams $MW_HOME/extensions/FlexDiagrams \
	&& cd $MW_HOME/extensions/FlexDiagrams \
	&& git checkout -q ccc362a614f43b68ff273cb5ff06aa6e9a0d4fa1

# G
RUN set -x; \
	cd $MW_HOME/extensions \
	# GlobalNotice
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GlobalNotice $MW_HOME/extensions/GlobalNotice \
	&& cd $MW_HOME/extensions/GlobalNotice \
	&& git checkout -q 131ded7af356ac7c7b75bf18c3690821a7d329ec \
	# GoogleAnalyticsMetrics
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleAnalyticsMetrics $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& cd $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& git checkout -q e1a2ebeec21e67fdafed7730a53cfaf2eccd5852 \
	# GoogleDocCreator
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocCreator $MW_HOME/extensions/GoogleDocCreator \
	&& cd $MW_HOME/extensions/GoogleDocCreator \
	&& git checkout -q 798571dda37236476a95be155d4f13af9a365f23 \
	# Graph
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Graph $MW_HOME/extensions/Graph \
	&& cd $MW_HOME/extensions/Graph \
	&& git checkout -q 4becc87a6098e669b750a162bedd5b2dbde4862f

# H
RUN set -x; \
	cd $MW_HOME/extensions \
	# HeaderFooter
	&& git clone --single-branch -b $MW_VERSION https://github.com/wikimedia/mediawiki-extensions-HeaderFooter.git $MW_HOME/extensions/HeaderFooter \
	&& cd $MW_HOME/extensions/HeaderFooter \
	&& git checkout -q b24ece3f921391df11ed0f446026cb264f20b69b \
	# HeaderTabs (v2.2.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/HeaderTabs $MW_HOME/extensions/HeaderTabs \
	&& cd $MW_HOME/extensions/HeaderTabs \
	&& git checkout -q be689b6f8cecb87483a35cf4b11c32e6d666df3e \
	# HTMLTags
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HTMLTags $MW_HOME/extensions/HTMLTags \
	&& cd $MW_HOME/extensions/HTMLTags \
	&& git checkout -q 3eac09e1e6da4edcc20d0e7fcfdbb2176435d11b

# L
RUN set -x; \
	cd $MW_HOME/extensions \
	# LabeledSectionTransclusion
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LabeledSectionTransclusion $MW_HOME/extensions/LabeledSectionTransclusion \
	&& cd $MW_HOME/extensions/LabeledSectionTransclusion \
	&& git checkout -q ceae22eb19e3191c982a49266ef889ed129b1b83 \
	# LDAPAuthentication2
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPAuthentication2 $MW_HOME/extensions/LDAPAuthentication2 \
	&& cd $MW_HOME/extensions/LDAPAuthentication2 \
	&& git checkout -q 6d596ff9da28d96f9e0f9ded63a1fcada44c647a \
	# LDAPAuthorization
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPAuthorization $MW_HOME/extensions/LDAPAuthorization \
	&& cd $MW_HOME/extensions/LDAPAuthorization \
	&& git checkout -q 97fa73a5859746fbfed79117c757142a3a991827 \
	# LDAPProvider
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPProvider $MW_HOME/extensions/LDAPProvider \
	&& cd $MW_HOME/extensions/LDAPProvider \
	&& git checkout -q 5aaddbb6adcbd7289efb2e83d7d5219da0ca87cd \
	# Lingo
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Lingo $MW_HOME/extensions/Lingo \
	&& cd $MW_HOME/extensions/Lingo \
	&& git checkout -q 49d089e4201cdfbd819c03aca6cd88c3421fcd25 \
	# LinkSuggest
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkSuggest $MW_HOME/extensions/LinkSuggest \
	&& cd $MW_HOME/extensions/LinkSuggest \
	&& git checkout -q 32f02acf38d49234060adc0699f8866074743aad \
	# LinkTarget
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkTarget $MW_HOME/extensions/LinkTarget \
	&& cd $MW_HOME/extensions/LinkTarget \
	&& git checkout -q d2edfc3fbdebbe0f301eb33e1264170e63b21c54 \
	# LockAuthor
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LockAuthor $MW_HOME/extensions/LockAuthor \
	&& cd $MW_HOME/extensions/LockAuthor \
	&& git checkout -q bfe34d64cafedbfc7e147c71f0909c0febde635e \
	# Lockdown
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Lockdown $MW_HOME/extensions/Lockdown \
	&& cd $MW_HOME/extensions/Lockdown \
	&& git checkout -q 7ec3f8b5cb04350addba0edf0f046a3992bca671 \
	# LookupUser
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LookupUser $MW_HOME/extensions/LookupUser \
	&& cd $MW_HOME/extensions/LookupUser \
	&& git checkout -q 60eb5101c627bc75db7d4f45c4ea4f5aba7c33af \
	# Loops
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Loops $MW_HOME/extensions/Loops \
	&& cd $MW_HOME/extensions/Loops \
	&& git checkout -q 809ef85440e4dd8031cf850fd57dc2bdb99ac717 \
    # LuaCache
    && git clone --single-branch -b master https://github.com/HydraWiki/LuaCache.git $MW_HOME/extensions/LuaCache \
    && cd $MW_HOME/extensions/LuaCache \
    && git checkout -q c654dacff3ae177d8ffc3dfd8c4f5e1e1ca7cb2f

# M
RUN set -x; \
	cd $MW_HOME/extensions \
	# MagicNoCache
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MagicNoCache $MW_HOME/extensions/MagicNoCache \
	&& cd $MW_HOME/extensions/MagicNoCache \
	&& git checkout -q 2bdb07072d3b8db465731f77b34debfe0eeb3216 \
	# MassMessage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessage $MW_HOME/extensions/MassMessage \
	&& cd $MW_HOME/extensions/MassMessage \
	&& git checkout -q 6acba6e7add00a6f1035e17074f6e3ca306966ca \
	# MassMessageEmail
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessageEmail $MW_HOME/extensions/MassMessageEmail \
	&& cd $MW_HOME/extensions/MassMessageEmail \
	&& git checkout -q 675a1003e0a1b18ed9860b385c04f7f689067def \
	# MediaUploader
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MediaUploader $MW_HOME/extensions/MediaUploader \
	&& cd $MW_HOME/extensions/MediaUploader \
	&& git checkout -q d51e2b321b4de9e0cc067030645288b65d9862f7 \
	# MintyDocs (1.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/MintyDocs $MW_HOME/extensions/MintyDocs \
	&& cd $MW_HOME/extensions/MintyDocs \
	&& git checkout -q 129f1ea37f13c3b68e8cc87a84633c571980e250 \
	# MobileFrontend
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend $MW_HOME/extensions/MobileFrontend \
	&& cd $MW_HOME/extensions/MobileFrontend \
	&& git checkout -q 717435a08b51c345b34052b70269acc160476b40 \
	# MsUpload
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MsUpload $MW_HOME/extensions/MsUpload \
	&& cd $MW_HOME/extensions/MsUpload \
	&& git checkout -q 67d84cda35864907d33aa07e622852b864b703d5 \
	# MyVariables
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MyVariables $MW_HOME/extensions/MyVariables \
	&& cd $MW_HOME/extensions/MyVariables \
	&& git checkout -q b7c43b33f17a7d3987dc75d50067977af7082991

# N
RUN set -x; \
	cd $MW_HOME/extensions \
	# NCBITaxonomyLookup
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/NCBITaxonomyLookup $MW_HOME/extensions/NCBITaxonomyLookup \
	&& cd $MW_HOME/extensions/NCBITaxonomyLookup \
	&& git fetch https://gerrit.wikimedia.org/r/mediawiki/extensions/NCBITaxonomyLookup refs/changes/52/916452/1 \
	&& git checkout FETCH_HEAD \
	# NewUserMessage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/NewUserMessage $MW_HOME/extensions/NewUserMessage \
	&& cd $MW_HOME/extensions/NewUserMessage \
	&& git checkout -q c875fdddf8689eb4b5dc40f563986bcda24eff70 \
	# NumerAlpha
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/NumerAlpha $MW_HOME/extensions/NumerAlpha \
	&& cd $MW_HOME/extensions/NumerAlpha \
	&& git checkout -q d34cfebba7160a468ae431cbe52bbc397250970e

# O
RUN set -x; \
	cd $MW_HOME/extensions \
	# OpenGraphMeta
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenGraphMeta $MW_HOME/extensions/OpenGraphMeta \
	&& cd $MW_HOME/extensions/OpenGraphMeta \
	&& git checkout -q 3516c05ae68acdad008894cb249d298c662a3ef9 \
	# OpenIDConnect
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenIDConnect $MW_HOME/extensions/OpenIDConnect \
	&& cd $MW_HOME/extensions/OpenIDConnect \
	&& git checkout -q 7aa039e0789c9d83c2df3d7baed33ccdb9d11cd0

# P
RUN set -x; \
	cd $MW_HOME/extensions \
	# PageExchange
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PageExchange $MW_HOME/extensions/PageExchange \
	&& cd $MW_HOME/extensions/PageExchange \
	&& git checkout -q d4e3cc20a4a6802afb7b217d8956adc5e2dc82f8 \
	# PageForms (v. 5.6.3)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms $MW_HOME/extensions/PageForms \
	&& cd $MW_HOME/extensions/PageForms \
	&& git checkout -q a17165713eeebfc6fcc125eb2d1bd3a371b4d303 \
	# PluggableAuth
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PluggableAuth $MW_HOME/extensions/PluggableAuth \
	&& cd $MW_HOME/extensions/PluggableAuth \
	&& git checkout -q d5b3ad8f03b65d3746e025cdd7fe3254ad6e4026 \
	# Popups
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups $MW_HOME/extensions/Popups \
	&& cd $MW_HOME/extensions/Popups \
	&& git checkout -q 33b38b338c7e08b7c9838c6d363da8062b4a4512 \
	# PagePort
	&& git clone --single-branch -b master https://github.com/WikiTeq/PagePort.git $MW_HOME/extensions/PagePort \
	&& cd $MW_HOME/extensions/PagePort \
	&& git checkout -q a6b800c9b3f58c151cdda4ec2f1aa396536c3a7d

# R
RUN set -x; \
	cd $MW_HOME/extensions \
	# RegularTooltips
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RegularTooltips $MW_HOME/extensions/RegularTooltips \
	&& cd $MW_HOME/extensions/RegularTooltips \
	&& git checkout -q 72cd62cfc82aab6b548e426d9ba621f3bd3f332f \
	# RevisionSlider
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RevisionSlider $MW_HOME/extensions/RevisionSlider \
	&& cd $MW_HOME/extensions/RevisionSlider \
	&& git checkout -q e91bb7a0cc453466bbe9f229705f36be30a19318 \
	# RottenLinks
	&& git clone --single-branch -b master https://github.com/miraheze/RottenLinks.git $MW_HOME/extensions/RottenLinks \
	&& cd $MW_HOME/extensions/RottenLinks \
	&& git checkout -q 56e4017c0af0d78464caba2ac6ed5771f1286774

# S
RUN set -x; \
	cd $MW_HOME/extensions \
	# SandboxLink
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SandboxLink $MW_HOME/extensions/SandboxLink \
	&& cd $MW_HOME/extensions/SandboxLink \
	&& git checkout -q 6ddfd9382c9616ca90bc132e740c473d9af9e1d1 \
	# SaveSpinner
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SaveSpinner $MW_HOME/extensions/SaveSpinner \
	&& cd $MW_HOME/extensions/SaveSpinner \
	&& git checkout -q fc21cc3ea6b940f7be644f18385d4e5e116472cb \
	# SemanticDependencyUpdater (WikiTeq fork)
	&& git clone --single-branch -b old-master https://github.com/WikiTeq/SemanticDependencyUpdater.git $MW_HOME/extensions/SemanticDependencyUpdater \
	&& cd $MW_HOME/extensions/SemanticDependencyUpdater \
	&& git checkout -q 3eedd54d4b4d4bfb6f15c2f56162b38095ebdb4c \
	# SemanticDrilldown
	&& git clone --single-branch -b master https://github.com/SemanticMediaWiki/SemanticDrilldown.git $MW_HOME/extensions/SemanticDrilldown \
	&& cd $MW_HOME/extensions/SemanticDrilldown \
	&& git checkout -q 064258ff204d76cd4f1f647708b03b3dc535ba14 \
	# SimpleChanges
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SimpleChanges $MW_HOME/extensions/SimpleChanges \
	&& cd $MW_HOME/extensions/SimpleChanges \
	&& git checkout -q b0694bc8c98da445a8fa3e80934a90240f2398aa \
	# SimpleMathJax
	&& git clone --single-branch https://github.com/jmnote/SimpleMathJax.git $MW_HOME/extensions/SimpleMathJax \
	&& cd $MW_HOME/extensions/SimpleMathJax \
	&& git checkout -q 7c9de84d219d15243aa153867339ac1a9c1a22e5 \
	# SkinPerPage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerPage $MW_HOME/extensions/SkinPerPage \
	&& cd $MW_HOME/extensions/SkinPerPage \
	&& git checkout -q 7430efac54457a096197219f8509efdba397776f \
	# SmiteSpam
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SmiteSpam $MW_HOME/extensions/SmiteSpam \
	&& cd $MW_HOME/extensions/SmiteSpam \
	&& git checkout -q 22637266e398ce229bc0b912dedc1f85f0effe29

# T
RUN set -x; \
	cd $MW_HOME/extensions \
	# TemplateStyles
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles $MW_HOME/extensions/TemplateStyles \
	&& cd $MW_HOME/extensions/TemplateStyles \
	&& git checkout -q 5166acaf9feb97e1276f4cce5ae48da9d619c410 \
	# TemplateWizard
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateWizard $MW_HOME/extensions/TemplateWizard \
	&& cd $MW_HOME/extensions/TemplateWizard \
	&& git checkout -q d9980e638e63b79c0986027599e5474c7fb5b8cc \
	# TimedMediaHandler
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TimedMediaHandler $MW_HOME/extensions/TimedMediaHandler \
	&& cd $MW_HOME/extensions/TimedMediaHandler \
	&& git checkout -q 84d508f84350fbc9fab301b20e27a6a15055b8b0 \
	# TinyMCE
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TinyMCE $MW_HOME/extensions/TinyMCE \
	&& cd $MW_HOME/extensions/TinyMCE \
	&& git checkout -q 969404c499caf99302e34eaa0cf1d5245ec8a94d \
	# TitleIcon
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TitleIcon $MW_HOME/extensions/TitleIcon \
	&& cd $MW_HOME/extensions/TitleIcon \
	&& git checkout -q 371a14833dcf11ff5fa2704eea5364ea669b15d0

# U
RUN set -x; \
	cd $MW_HOME/extensions \
	# UniversalLanguageSelector
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UniversalLanguageSelector $MW_HOME/extensions/UniversalLanguageSelector \
	&& cd $MW_HOME/extensions/UniversalLanguageSelector \
	&& git checkout -q cd5ab3bc5f111dc77a4d45d37738d9486f756087 \
	# UploadWizard
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UploadWizard $MW_HOME/extensions/UploadWizard \
	&& cd $MW_HOME/extensions/UploadWizard \
	&& git checkout -q 336d97f3a652bdc177c3fda74dc913038d924d57 \
	# UrlGetParameters
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UrlGetParameters $MW_HOME/extensions/UrlGetParameters \
	&& cd $MW_HOME/extensions/UrlGetParameters \
	&& git checkout -q 7794b4dc79076a210ea9c93af11ddb766ba43e15 \
	# UserFunctions
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserFunctions $MW_HOME/extensions/UserFunctions \
	&& cd $MW_HOME/extensions/UserFunctions \
	&& git checkout -q cb247ee6374b0e32d16b6c442437b030b3049ee3 \
	# UserMerge
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge $MW_HOME/extensions/UserMerge \
	&& cd $MW_HOME/extensions/UserMerge \
	&& git checkout -q 25db10897179f0a4f47b7543bea5d0bb150c06ed \
	# UserPageViewTracker (v. 0.8)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/UserPageViewTracker $MW_HOME/extensions/UserPageViewTracker \
	&& cd $MW_HOME/extensions/UserPageViewTracker \
	&& git checkout -q 4461bad480f2d2739bbc641ffc15bd7c6001abda

# V
RUN set -x; \
	cd $MW_HOME/extensions \
	# Variables
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Variables $MW_HOME/extensions/Variables \
	&& cd $MW_HOME/extensions/Variables \
	&& git checkout -q b6a028db9c997ed5d2ac9944505c3ef8cb0310d1 \
	# VEForAll (v. 0.5.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/VEForAll $MW_HOME/extensions/VEForAll \
	&& cd $MW_HOME/extensions/VEForAll \
	&& git checkout -q 85a4b8e57bd61c81fbf810e4f858d3a220181b4f \
	# VoteNY
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY $MW_HOME/extensions/VoteNY \
	&& cd $MW_HOME/extensions/VoteNY \
	&& git checkout -q f1b42561d977368e7f3c8216a371d73ecd793d9e

# W
RUN set -x; \
	cd $MW_HOME/extensions \
	# WatchAnalytics (v. 4.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/WatchAnalytics $MW_HOME/extensions/WatchAnalytics \
	&& cd $MW_HOME/extensions/WatchAnalytics \
	&& git checkout -q 6d5bf61979686f480873ad39594e2ed7e3747eaf \
	# WhoIsWatching
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WhoIsWatching $MW_HOME/extensions/WhoIsWatching \
	&& cd $MW_HOME/extensions/WhoIsWatching \
	&& git checkout -q 4c2000d683c03c8a7e0117decd3de1cc27bad208 \
	# Widgets
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets $MW_HOME/extensions/Widgets \
	&& cd $MW_HOME/extensions/Widgets \
	&& git checkout -q 805cebd671c1bcab46d5f6a671b6190edf3932ea \
	# WikiForum
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiForum $MW_HOME/extensions/WikiForum \
	&& cd $MW_HOME/extensions/WikiForum \
	&& git checkout -q 693b2398aadac29d64a383eacf21f66f274ec868 \
	# WikiSEO
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiSEO $MW_HOME/extensions/WikiSEO \
	&& cd $MW_HOME/extensions/WikiSEO \
	&& git checkout -q cff698080e52788a66fa032f20ce704fc5383edd \
	# WSOAuth
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WSOAuth $MW_HOME/extensions/WSOAuth \
	&& cd $MW_HOME/extensions/WSOAuth \
	&& git checkout -q b53d5e57eb48f5807c30a08e038bfd5036935e12

#### WikiTeq extensions ####

# B
RUN set -x; \
	cd $MW_HOME/extensions \
	# Buggy
	&& git clone --single-branch -b $MW_VERSION https://github.com/wikimedia/mediawiki-extensions-Buggy.git $MW_HOME/extensions/Buggy \
	&& cd $MW_HOME/extensions/Buggy \
	&& git checkout -q e8d9b73a20cf3f71c5e6af4748a989a87b1e73dd

# C
RUN set -x; \
	cd $MW_HOME/extensions \
  	# ChangeAuthor
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ChangeAuthor $MW_HOME/extensions/ChangeAuthor \
	&& cd $MW_HOME/extensions/ChangeAuthor \
	&& git checkout -q 4645fa601e6aaac92c010e4de02f78ea22a7c0cd \
	# Citoid
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Citoid $MW_HOME/extensions/Citoid \
	&& cd $MW_HOME/extensions/Citoid \
	&& git checkout -q bf079532465437573233237bd70e6bd603916cda

# E
RUN set -x; \
	cd $MW_HOME/extensions \
   	# EditAccount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EditAccount $MW_HOME/extensions/EditAccount \
	&& cd $MW_HOME/extensions/EditAccount \
	&& git checkout -q e53b7e579b8d084ca054fc4ce93ef5533a6c1f1b \
	# Flow
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Flow $MW_HOME/extensions/Flow \
	&& cd $MW_HOME/extensions/Flow \
	&& git checkout -q 83a39146e21919605ac5e7c1582a0205d02c7094

# G
RUN set -x; \
	cd $MW_HOME/extensions \
  	# GoogleDocTag
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocTag $MW_HOME/extensions/GoogleDocTag \
	&& cd $MW_HOME/extensions/GoogleDocTag \
	&& git checkout -q 516e6ac5ef1741632fc7810895e609716d6bdde3 \
	# GTag
	&& git clone https://github.com/SkizNet/mediawiki-GTag.git $MW_HOME/extensions/GTag \
	&& cd $MW_HOME/extensions/GTag \
	&& git checkout -q 3ac02ef2923684a8b2930250e5d7923380de012c

# H
RUN set -x; \
	cd $MW_HOME/extensions \
   	# HeadScript
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeadScript $MW_HOME/extensions/HeadScript \
	&& cd $MW_HOME/extensions/HeadScript \
	&& git checkout -q b11cfe6b41f803cafcf9ac9a0cfa3d1ebf1f03ae

# I
RUN set -x; \
	cd $MW_HOME/extensions \
   	# IframePage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/IframePage $MW_HOME/extensions/IframePage \
	&& cd $MW_HOME/extensions/IframePage \
	&& git checkout -q d136c7c29aeb7c5ddef53d9e4f3ed015f5dd94e2

# L
RUN set -x; \
	cd $MW_HOME/extensions \
  	# Lazyload
	# TODO change me when https://github.com/mudkipme/mediawiki-lazyload/pull/15 will be merged
	&& git clone https://github.com/mudkipme/mediawiki-lazyload.git $MW_HOME/extensions/Lazyload \
	&& cd $MW_HOME/extensions/Lazyload \
	&& git checkout -b $MW_VERSION 30a01cc149822353c9404ec178ec01848bae65c5 \
	# LiquidThreads
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LiquidThreads $MW_HOME/extensions/LiquidThreads \
	&& cd $MW_HOME/extensions/LiquidThreads \
	&& git checkout -q b98e36b382cf28ffcb7580cabcb5a9dfd1861eb6

# M
RUN set -x; \
	cd $MW_HOME/extensions \
   	# MassPasswordReset
	&& cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/MassPasswordReset.git \
	&& cd MassPasswordReset \
	&& git checkout -b $MW_VERSION 04b7e765db994d41f5ca3a910e18f77105218d94 \
	# MobileDetect
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileDetect $MW_HOME/extensions/MobileDetect \
	&& cd $MW_HOME/extensions/MobileDetect \
	&& git checkout -q 5e92e4b855c7d546ba4acfa036caf32c4c0a4131 \
	# Mpdf
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Mpdf.git $MW_HOME/extensions/Mpdf \
	&& cd $MW_HOME/extensions/Mpdf \
	&& git checkout -q 1b24ccee1a7a076313afdfdba779b9e67a19697f

# P
RUN set -x; \
	cd $MW_HOME/extensions \
   	# PageSchemas
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PageSchemas $MW_HOME/extensions/PageSchemas \
	&& cd $MW_HOME/extensions/PageSchemas \
	&& git checkout -q 100db6d80a036b152b27161678ae4d2d380c2026 \
	# PDFEmbed
	&& git clone https://github.com/WolfgangFahl/PDFEmbed.git $MW_HOME/extensions/PDFEmbed \
	&& cd $MW_HOME/extensions/PDFEmbed \
	&& git checkout -q f38758156639b34317ffc6a9e8b5b2624aebae8b \
	# PubmedParser
	&& cd $MW_HOME/extensions \
	&& git clone https://github.com/bovender/PubmedParser.git \
	&& cd PubmedParser \
	&& git checkout -b $MW_VERSION 509c9a26b5c07fbc476448bd34b38cd8f5ec01b5

# S
RUN set -x; \
	cd $MW_HOME/extensions \
  	# Scopus
	&& git clone https://github.com/nischayn22/Scopus.git $MW_HOME/extensions/Scopus \
	&& cd $MW_HOME/extensions/Scopus \
	&& git checkout -b $MW_VERSION 4fe8048459d9189626d82d9d93a0d5f906c43746 \
	# SelectCategory
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SelectCategory $MW_HOME/extensions/SelectCategory \
	&& cd $MW_HOME/extensions/SelectCategory \
	&& git checkout -q bef7c28489de79fbd6ecf5235a8d712dc93e5d86 \
	# SemanticQueryInterface
	&& git clone https://github.com/vedmaka/SemanticQueryInterface.git $MW_HOME/extensions/SemanticQueryInterface \
	&& cd $MW_HOME/extensions/SemanticQueryInterface \
	&& git checkout -b $MW_VERSION 0016305a95ecbb6ed4709bfa3fc6d9995d51336f \
	&& mv SemanticQueryInterface/* . \
	&& rmdir SemanticQueryInterface \
	&& ln -s SQI.php SemanticQueryInterface.php \
	&& rm -fr .git \
	# Sentry (WikiTeq fork that uses sentry/sentry 3.x)
	&& git clone --single-branch -b master https://github.com/WikiTeq/mediawiki-extensions-Sentry.git $MW_HOME/extensions/Sentry \
	&& cd $MW_HOME/extensions/Sentry \
	&& git checkout -q 9d9162d83f921b66f6c14ed354d20607ecafa030 \
	# ShowMe
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ShowMe $MW_HOME/extensions/ShowMe \
	&& cd $MW_HOME/extensions/ShowMe \
	&& git checkout -q 576ad3a87c427031234a51d4e9cf3c1b0bbe0bca \
	# SimpleTooltip
	&& git clone https://github.com/Universal-Omega/SimpleTooltip.git $MW_HOME/extensions/SimpleTooltip \
	&& cd $MW_HOME/extensions/SimpleTooltip \
	&& git checkout -b $MW_VERSION 29672ebe171615cf1f4c39ab34502722fbd367c3 \
	# SimpleTippy
	&& git clone https://github.com/vedmaka/mediawiki-extension-SimpleTippy.git $MW_HOME/extensions/SimpleTippy \
	&& cd $MW_HOME/extensions/SimpleTippy \
	&& git checkout -b $MW_VERSION 271d5e3340e63627058081acc641ec2623eee9dd \
	# Skinny
	&& git clone https://github.com/tinymighty/skinny.git $MW_HOME/extensions/Skinny \
	&& cd $MW_HOME/extensions/Skinny \
	&& git checkout -b $MW_VERSION 38e381fdba990f850ac45ecb555f771e386952e6 \
	# SkinPerNamespace
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerNamespace $MW_HOME/extensions/SkinPerNamespace \
	&& cd $MW_HOME/extensions/SkinPerNamespace \
	&& git checkout -q f0d2384e801c93b742440be63209ead6a171807e \
	# Survey
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Survey $MW_HOME/extensions/Survey \
	&& cd $MW_HOME/extensions/Survey \
	&& git checkout -q 1d2ea568c6b4b13620858a0eacbe304cc57ff27a

# T
RUN set -x; \
	cd $MW_HOME/extensions \
   	# Tabber
	&& git clone https://gitlab.com/hydrawiki/extensions/Tabber.git $MW_HOME/extensions/Tabber \
	&& cd $MW_HOME/extensions/Tabber \
	&& git checkout -b $MW_VERSION 6c67baf4d18518fa78e07add4c032d62dd384b06 \
	# TabberNeue
	&& git clone https://github.com/StarCitizenTools/mediawiki-extensions-TabberNeue.git $MW_HOME/extensions/TabberNeue \
	&& cd $MW_HOME/extensions/TabberNeue \
	&& git checkout -b $MW_VERSION 1805d9738beba0b96e685012c02a1d05d946ca69 \
	# Tabs
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Tabs $MW_HOME/extensions/Tabs \
	&& cd $MW_HOME/extensions/Tabs \
	&& git checkout -q 74dc13ac96127ba6b16f483d16fb15e83246f380 \
	# TwitterTag
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TwitterTag $MW_HOME/extensions/TwitterTag \
	&& cd $MW_HOME/extensions/TwitterTag \
	&& git checkout -q 1573d67de949a6d151a346b09f9d4ee7a5ea2993

# U
RUN set -x; \
	cd $MW_HOME/extensions \
   	# UploadWizardExtraButtons
	&& git clone https://github.com/vedmaka/mediawiki-extension-UploadWizardExtraButtons.git $MW_HOME/extensions/UploadWizardExtraButtons \
	&& cd $MW_HOME/extensions/UploadWizardExtraButtons \
	&& git checkout -b $MW_VERSION accba1b9b6f50e67d709bd727c9f4ad6de78c0c0

# Y
RUN set -x; \
	cd $MW_HOME/extensions \
   	# YouTube
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/YouTube $MW_HOME/extensions/YouTube \
	&& cd $MW_HOME/extensions/YouTube \
	&& git checkout -q e5fb16a5d2c783765588c649f9edfcecb1830822

# G
RUN set -x; \
	cd $MW_HOME/extensions \
   	# GoogleLogin
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleLogin $MW_HOME/extensions/GoogleLogin \
	&& cd $MW_HOME/extensions/GoogleLogin \
	&& git checkout -q b42600f85cdb5cd2ee888032e41cb689c180f2bc

# V
RUN set -x; \
	cd $MW_HOME/extensions \
   	# VariablesLue
	&& git clone --single-branch -b master https://github.com/Liquipedia/VariablesLua.git $MW_HOME/extensions/VariablesLua \
	&& cd $MW_HOME/extensions/VariablesLua \
	&& git checkout -q dced585ef5ddcfbaa49c510c49c3b398ecc6f1c6

# W
RUN set -x; \
    cd $MW_HOME/extensions \
    # WSSlots
    && git clone --single-branch -b master https://github.com/Open-CSP/WSSlots.git $MW_HOME/extensions/WSSlots \
    && cd $MW_HOME/extensions/WSSlots \
    && git checkout -q dfdcd6adea3fae512c4469704ef93accff83937f

# J
RUN set -x; \
	cd $MW_HOME/extensions \
	# JWTAuth
	&& git clone --single-branch -b main https://github.com/jeffw16/JWTAuth.git $MW_HOME/extensions/JWTAuth \
	&& cd $MW_HOME/extensions/JWTAuth \
	&& git checkout -q c7c0730160a84d6b60e3e1b6b108d790972f0f15 # Upgrade carefully, we had a problem with version 2.0, see MITE-50

# WikiTeq removes/fixes the extensions with issues in Canasta docker image, remove it if fixed in Canasta
RUN set -x; \
	# SimpleMathJax add Fix path to ext.SimpleMathJax.js in ResourceModules \
	rm -fr $MW_HOME/extensions/SimpleMathJax \
	&& git clone --single-branch -b master https://github.com/WikiTeq/SimpleMathJax.git $MW_HOME/extensions/SimpleMathJax \
	&& cd $MW_HOME/extensions/SimpleMathJax \
	&& git checkout -q 1ef413553dca4143294842fac99b56425d815396 \
	# does not work? see WIK-702?focusedCommentId=41955
	&& rm -fr $MW_HOME/extensions/TimedMediaHandler \
	# missed in Canasta
	&& cd $MW_HOME/extensions/EmailAuthorization \
	&& git submodule update --init --recursive

################# Patches #################

# WikiTeq AL-12
COPY _sources/patches/FlexDiagrams.0.4.fix.diff /tmp/FlexDiagrams.0.4.fix.diff
RUN set -x; \
	cd $MW_HOME/extensions/FlexDiagrams \
	&& git apply /tmp/FlexDiagrams.0.4.fix.diff

# PageForms WLDR-319, WLDR-318
COPY _sources/patches/PF.5.6.usedisplaytitle.autocomplete.forminput.diff /tmp/PF.5.6.usedisplaytitle.autocomplete.forminput.diff
RUN set -x; \
    cd $MW_HOME/extensions/PageForms \
    && git apply /tmp/PF.5.6.usedisplaytitle.autocomplete.forminput.diff \
    # WLDR-303
    && GIT_COMMITTER_EMAIL=docker@docker.invalid git cherry-pick -x 94ceca65c23a2894da1a26445077c786671aef0c

# Fixes PHP parsoid errors when user replies on a flow message, see https://phabricator.wikimedia.org/T260648#6645078
COPY _sources/patches/flow-conversion-utils.patch /tmp/flow-conversion-utils.patch
RUN set -x; \
	cd $MW_HOME/extensions/Flow \
	&& git apply /tmp/flow-conversion-utils.patch

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/extensions \
	&& find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

FROM base as composer

# Copy core, skins and extensions
COPY --from=core $MW_HOME $MW_HOME
COPY --from=skins $MW_HOME/skins $MW_HOME/skins
COPY --from=extensions $MW_HOME/extensions $MW_HOME/extensions

# Composer dependencies
COPY _sources/configs/composer.wikiteq.json $MW_HOME/composer.local.json
# Run with secret mounted to /run/secrets/COMPOSER_TOKEN
# This is needed to bypass rate limits
RUN --mount=type=secret,id=COMPOSER_TOKEN cd $MW_HOME \
	&& cp composer.json composer.json.bak \
	&& cat composer.json.bak | jq '. + {"minimum-stability": "dev"}' > composer.json \
	&& rm composer.json.bak \
	&& cp composer.json composer.json.bak \
	&& cat composer.json.bak | jq '. + {"prefer-stable": true}' > composer.json \
	&& rm composer.json.bak \
	&& composer clear-cache \
	# configure auth
	&& if [ -f "/run/secrets/COMPOSER_TOKEN" ]; then composer config -g github-oauth.github.com $(cat /run/secrets/COMPOSER_TOKEN); fi \
	&& composer update --no-dev --with-dependencies \
	&& composer clear-cache \
    # deauth
    && composer config -g --unset github-oauth.github.com

# Move files around
RUN set -x; \
	# Move files to $MW_ORIGIN_FILES directory
	mv $MW_HOME/images $MW_ORIGIN_FILES/ \
	&& mv $MW_HOME/cache $MW_ORIGIN_FILES/ \
	# Create symlinks from $MW_VOLUME to the wiki root for images and cache directories
	&& ln -s $MW_VOLUME/images $MW_HOME/images \
	&& ln -s $MW_VOLUME/cache $MW_HOME/cache

FROM base as final

COPY --from=composer $MW_HOME $MW_HOME
COPY --from=composer $MW_ORIGIN_FILES $MW_ORIGIN_FILES

# Default values
ENV MW_AUTOUPDATE=true \
	MW_MAINTENANCE_UPDATE=0 \
	MW_ENABLE_EMAIL=0 \
	MW_ENABLE_USER_EMAIL=0 \
	MW_ENABLE_UPLOADS=0 \
	MW_USE_IMAGE_MAGIC=0 \
	MW_USE_INSTANT_COMMONS=0 \
	MW_EMERGENCY_CONTACT=apache@invalid \
	MW_PASSWORD_SENDER=apache@invalid \
	MW_MAIN_CACHE_TYPE=CACHE_NONE \
	MW_DB_TYPE=mysql \
	MW_DB_SERVER=db \
	MW_DB_NAME=mediawiki \
	MW_DB_USER=root \
	MW_DB_INSTALLDB_USER=root \
	MW_REDIS_SERVERS=redis:6379 \
	MW_CIRRUS_SEARCH_SERVERS=elasticsearch \
	MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG=2 \
	MW_MAINTENANCE_CIRRUSSEARCH_FORCEINDEX=2 \
	MW_ENABLE_JOB_RUNNER=true \
	MW_JOB_RUNNER_PAUSE=2 \
	MW_JOB_RUNNER_MEMORY_LIMIT=512M \
	MW_ENABLE_TRANSCODER=true \
	MW_JOB_TRANSCODER_PAUSE=60 \
	MW_MAP_DOMAIN_TO_DOCKER_GATEWAY=0 \
	MW_ENABLE_SITEMAP_GENERATOR=false \
	MW_SITEMAP_PAUSE_DAYS=1 \
	MW_SITEMAP_SUBDIR="" \
	MW_SITEMAP_IDENTIFIER="mediawiki" \
	MW_CONFIG_DIR=/mediawiki/config \
	PHP_UPLOAD_MAX_FILESIZE=10M \
	PHP_POST_MAX_SIZE=10M \
	PHP_MEMORY_LIMIT=128M \
	PHP_MAX_INPUT_VARS=1000 \
	PHP_MAX_EXECUTION_TIME=60 \
	PHP_MAX_INPUT_TIME=60 \
	LOG_FILES_COMPRESS_DELAY=3600 \
	LOG_FILES_REMOVE_OLDER_THAN_DAYS=10 \
	MEDIAWIKI_MAINTENANCE_AUTO_ENABLED=false \
	MW_SENTRY_DSN="" \
	MW_USE_CACHE_DIRECTORY=1 \
	APACHE_REMOTE_IP_HEADER=X-Forwarded-For

COPY _sources/configs/msmtprc /etc/
COPY _sources/configs/mediawiki.conf /etc/apache2/sites-enabled/
COPY _sources/configs/status.conf /etc/apache2/mods-available/
COPY _sources/configs/scan.conf /etc/clamd.d/scan.conf
COPY _sources/configs/php_*.ini /etc/php/8.1/cli/conf.d/
COPY _sources/configs/php_*.ini /etc/php/8.1/apache2/conf.d/
COPY _sources/scripts/*.sh /
COPY _sources/scripts/*.php $MW_HOME/maintenance/
COPY _sources/configs/robots.php $WWW_ROOT/
COPY _sources/configs/robots.txt $WWW_ROOT/
COPY _sources/configs/.htaccess $WWW_ROOT/
COPY _sources/images/favicon.ico $WWW_ROOT/
COPY _sources/canasta/DockerSettings.php $MW_HOME/
COPY _sources/canasta/getMediawikiSettings.php /
COPY _sources/configs/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN set -x; \
	chmod -v +x /*.sh \
	# Sitemap directory
	&& mkdir -p $MW_ORIGIN_FILES/sitemap \
	&& ln -s $MW_VOLUME/sitemap $MW_HOME/sitemap \
	# Comment out ErrorLog and CustomLog parameters, we use rotatelogs in mediawiki.conf for the log files
	&& sed -i 's/^\(\s*ErrorLog .*\)/# \1/g' /etc/apache2/apache2.conf \
	&& sed -i 's/^\(\s*CustomLog .*\)/# \1/g' /etc/apache2/apache2.conf \
	# Make web installer work with Canasta
	&& cp "$MW_HOME/includes/NoLocalSettings.php" "$MW_HOME/includes/CanastaNoLocalSettings.php" \
	&& sed -i 's/MW_CONFIG_FILE/CANASTA_CONFIG_FILE/g' "$MW_HOME/includes/CanastaNoLocalSettings.php" \
	# Modify config
	&& sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
	&& a2enmod expires remoteip \
	&& a2disconf other-vhosts-access-log \
	# For Widgets extension
	&& mkdir -p $MW_ORIGIN_FILES/extensions/Widgets \
	&& mv $MW_HOME/extensions/Widgets/compiled_templates $MW_ORIGIN_FILES/extensions/Widgets/ \
	&& ln -s $MW_VOLUME/extensions/Widgets/compiled_templates $MW_HOME/extensions/Widgets/compiled_templates

COPY _sources/images/Powered-by-Canasta.png /var/www/mediawiki/w/resources/assets/

EXPOSE 80
WORKDIR $MW_HOME

HEALTHCHECK --interval=1m --timeout=10s \
	CMD wget -q --method=HEAD localhost/w/api.php

CMD ["/run-apache.sh"]
