FROM debian:12.5 AS base

LABEL maintainers="pavel@wikiteq.com,alexey@wikiteq.com"
LABEL org.opencontainers.image.source=https://github.com/WikiTeq/Taqasta

ENV MW_VERSION=REL1_43 \
	MW_CORE_VERSION=1.43-alpha-3f9b466 \
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

FROM base AS core
# MediaWiki core
# Until a 1.43 tag is tagged, update --depth as needed to keep the checkout commit
# when new commits are added to the REL1_43 branch, or update the checkout commit
RUN set -x; \
	git clone --depth 1 -b REL1_43 https://gerrit.wikimedia.org/r/mediawiki/core.git $MW_HOME \
	&& cd $MW_HOME \
	&& git checkout -q e9d784aec5311435c1894c5f4d31222be15a1ad8 \
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

FROM base AS skins
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
	&& git checkout -q 918af88b911b5dfcb42cedd8cb28fc067fa5560e \
	# Modern
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Modern $MW_HOME/skins/Modern \
	&& cd $MW_HOME/skins/Modern \
	&& git checkout -q 2ab0a8068541352b0e26d216fb7bfc8456baf337 \
	# Pivot
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Pivot $MW_HOME/skins/pivot \
	&& cd $MW_HOME/skins/pivot \
	&& git checkout -q e95137969241c202baa452ac39e38cfecd57fc64 \
	# Refreshed
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed $MW_HOME/skins/Refreshed \
	&& cd $MW_HOME/skins/Refreshed \
	&& git checkout -q d83503aa41b70c927132dd17ba0313a3299e0ca7

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

FROM base AS extensions
# Extensions
#
# The following extensions are bundled into MediaWiki and do not need to be separately installed (though in some cases
# they are modified): AbuseFilter, CategoryTree, Cite, CiteThisPage, CodeEditor, ConfirmEdit, DiscussionTools, Echo,
# Gadgets, ImageMap, InputBox, Interwiki, Linter, LoginNotify, Math, MultimediaViewer, Nuke, OATHAuth, PageImages,
# ParserFunctions, PdfHandler, Poem, ReplaceText, Scribunto, SecureLinkFixer, SpamBlacklist, SyntaxHighlight_GeSHi
# TemplateData, TextExtracts, Thanks, TitleBlacklist, VisualEditor, WikiEditor
#
# The following extensions are downloaded via Composer and also do not need to be downloaded here: Bootstrap,
# BootstrapComponents, Maps, Mermaid, Semantic Breadcrumb Links, Semantic Compound Queries, Semantic Extra Special
# Properties, Semantic MediaWiki (along with all its helper library extensions, like DataValues), Semantic Result
# Formats, Semantic Scribunto, SimpleBatchUpload, SubPageList.

# A
RUN set -x; \
	mkdir $MW_HOME/extensions \
	&& cd $MW_HOME/extensions \
	# AdminLinks (v. 0.6.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/AdminLinks $MW_HOME/extensions/AdminLinks \
	&& cd $MW_HOME/extensions/AdminLinks \
	&& git checkout -q 60eda7201636218b80d83a637b70e5c753900e41 \
	# AdvancedSearch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AdvancedSearch $MW_HOME/extensions/AdvancedSearch \
	&& cd $MW_HOME/extensions/AdvancedSearch \
	&& git checkout -q 9f49f67c05c67460f6fdb6de3dcc2fa00b9694b0 \
	# AJAXPoll
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AJAXPoll $MW_HOME/extensions/AJAXPoll \
	&& cd $MW_HOME/extensions/AJAXPoll \
	&& git checkout -q ce2920a0d55933387f3cebea67ba19489ddd50a6 \
	# AntiSpoof
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AntiSpoof $MW_HOME/extensions/AntiSpoof \
	&& cd $MW_HOME/extensions/AntiSpoof \
	&& git checkout -q 4cb2da4a0fe37dff2e407589142bb96d07273e45 \
	# ApprovedRevs (v. 1.8.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/ApprovedRevs $MW_HOME/extensions/ApprovedRevs \
	&& cd $MW_HOME/extensions/ApprovedRevs \
	&& git checkout -q 53b67bf7e1e8ac3d20c2fd41ad2ab1c708c045a6 \
	# Arrays
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Arrays $MW_HOME/extensions/Arrays \
	&& cd $MW_HOME/extensions/Arrays \
	&& git checkout -q bea142c3a6b46218e4a499b8b1aed2cda5260a48

# B
RUN set -x; \
	cd $MW_HOME/extensions \
 	# BetaFeatures
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BetaFeatures $MW_HOME/extensions/BetaFeatures \
	&& cd $MW_HOME/extensions/BetaFeatures \
	&& git checkout -q 374213aad53eed4b828fa9f5bd1c0ee13592b21e \
	# BreadCrumbs2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BreadCrumbs2 $MW_HOME/extensions/BreadCrumbs2 \
	&& cd $MW_HOME/extensions/BreadCrumbs2 \
	&& git checkout -q 80c4ca26b3b018c25db05d81c5242a2a3608f2d9

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
	&& git checkout -q ed3843e59ddc7eab05382b1043c1fcadf16df256 \
	# CheckUser
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CheckUser $MW_HOME/extensions/CheckUser \
	&& cd $MW_HOME/extensions/CheckUser \
	&& git checkout -q 8d44089275bf37ac5c435d72d94df8d23cb878fa \
	# CirrusSearch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch $MW_HOME/extensions/CirrusSearch \
	&& cd $MW_HOME/extensions/CirrusSearch \
	&& git checkout -q dd2e6afccb7be4895b1a17278f1f040733cfe3bc \
	# CodeMirror
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror $MW_HOME/extensions/CodeMirror \
	&& cd $MW_HOME/extensions/CodeMirror \
	&& git checkout -q 9c13028f12fd057949462077d2900c346f4a47bc \
	# Collection
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Collection $MW_HOME/extensions/Collection \
	&& cd $MW_HOME/extensions/Collection \
	&& git checkout -q da44fbdeaff442ca7a6e9e6d6f7d4204c0afcac7 \
	# CommentStreams
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommentStreams $MW_HOME/extensions/CommentStreams \
	&& cd $MW_HOME/extensions/CommentStreams \
	&& git checkout -q b3528ae2485266aae620b801910c0eccc7bb7c09 \
	# CommonsMetadata
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommonsMetadata $MW_HOME/extensions/CommonsMetadata \
	&& cd $MW_HOME/extensions/CommonsMetadata \
	&& git checkout -q 80af24682eb760ff2865a591979b95efeefee0e0 \
	# ConfirmAccount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmAccount $MW_HOME/extensions/ConfirmAccount \
	&& cd $MW_HOME/extensions/ConfirmAccount \
	&& git checkout -q 4d86da401ec6205f5d07b6990dd4b6a1e3458000 \
	# ContactPage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContactPage $MW_HOME/extensions/ContactPage \
	&& cd $MW_HOME/extensions/ContactPage \
	&& git checkout -q bbf3609822b404022c6b6f419c0d439ec0c88d40 \
	# ContributionScores
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores $MW_HOME/extensions/ContributionScores \
	&& cd $MW_HOME/extensions/ContributionScores \
	&& git checkout -q e00a3b1c571ab52e1ae034bd0acef874c6220304 \
	# CookieWarning
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CookieWarning $MW_HOME/extensions/CookieWarning \
	&& cd $MW_HOME/extensions/CookieWarning \
	&& git checkout -q 8e6f97d934215748fafd1d9c29e2101a522cd7c9 \
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
	&& git checkout -q fbf19f63f752a7d2e5803ac1475b4da3850948d1 \
	# DeleteBatch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DeleteBatch $MW_HOME/extensions/DeleteBatch \
	&& cd $MW_HOME/extensions/DeleteBatch \
	&& git checkout -q c4b77dea7859a77e5d69a8cf9c477f300c0ba700 \
	# Description2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 $MW_HOME/extensions/Description2 \
	&& cd $MW_HOME/extensions/Description2 \
	&& git checkout -q e0fceb439ad465c40a373b95e9de57d2289012ac \
	# Disambiguator
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator $MW_HOME/extensions/Disambiguator \
	&& cd $MW_HOME/extensions/Disambiguator \
	&& git checkout -q f2cf1387f45e6bf0a84f26b5a62fa98bc6da2e86	 \
	# DismissableSiteNotice
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DismissableSiteNotice $MW_HOME/extensions/DismissableSiteNotice \
	&& cd $MW_HOME/extensions/DismissableSiteNotice \
	&& git checkout -q a3a019be4b87d414dfc07727fb9ca884c20835a1 \
	# DisplayTitle
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DisplayTitle $MW_HOME/extensions/DisplayTitle \
	&& cd $MW_HOME/extensions/DisplayTitle \
	&& git checkout -q 497dd93f850793b827122ef88f7e816b0ab1466b \
	# DynamicPageList3
	# TODO no 1.43 branch yet
	&& git clone --single-branch -b REL1_39 https://github.com/Universal-Omega/DynamicPageList3.git $MW_HOME/extensions/DynamicPageList3 \
	&& cd $MW_HOME/extensions/DynamicPageList3 \
	&& git checkout -q e4faf608b0f5a77c4a4c3576a2a28216c7d2bbbf

# E
RUN set -x; \
	cd $MW_HOME/extensions \
	# Editcount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Editcount $MW_HOME/extensions/Editcount \
	&& cd $MW_HOME/extensions/Editcount \
	&& git checkout -q 991d86c21aec39868766e75024c29e2a5bf94d40 \
	# Elastica
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica $MW_HOME/extensions/Elastica \
	&& cd $MW_HOME/extensions/Elastica \
	&& git checkout -q 229e17e3b12df05d665cd731947be4d6cf51db4a \
	# EmailAuthorization
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EmailAuthorization $MW_HOME/extensions/EmailAuthorization \
	&& cd $MW_HOME/extensions/EmailAuthorization \
	&& git checkout -q 12dc605c71021427b4d3a1b3838cca96899f8152 \
	# EmbedVideo
	# (Canasta uses hydrawiki, but we switched to StarCitizenWiki's fork which
	# which is maintained, WE-286)
	&& git clone --single-branch -b master https://github.com/StarCitizenWiki/mediawiki-extensions-EmbedVideo.git $MW_HOME/extensions/EmbedVideo \
	&& cd $MW_HOME/extensions/EmbedVideo \
	&& git checkout -q 5c03c031070981730a0e01aa3cbc3e5cbd1b88c1 \
	# EventLogging
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventLogging $MW_HOME/extensions/EventLogging \
	&& cd $MW_HOME/extensions/EventLogging \
	&& git checkout -q f57f76c85552c1912bba638bcabe52a0b6d6e9b0 \
	# EventStreamConfig
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventStreamConfig $MW_HOME/extensions/EventStreamConfig \
	&& cd $MW_HOME/extensions/EventStreamConfig \
	&& git checkout -q 6e49baea9bf4e2aaad0d2fba8b21406e383ba1b2 \
	# ExternalData (v. 3.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/ExternalData $MW_HOME/extensions/ExternalData \
	&& cd $MW_HOME/extensions/ExternalData \
	&& git checkout -q 5d30e60a65ca53a3fb5b39826deb2e6917892e22

# F
RUN set -x; \
	cd $MW_HOME/extensions \
	# FlexDiagrams (v. 0.5)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/FlexDiagrams $MW_HOME/extensions/FlexDiagrams \
	&& cd $MW_HOME/extensions/FlexDiagrams \
	&& git checkout -q eefc9e29aedfc6d8ffaf4f4e50043b390ebd7adc

# G
RUN set -x; \
	cd $MW_HOME/extensions \
	# GlobalNotice
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GlobalNotice $MW_HOME/extensions/GlobalNotice \
	&& cd $MW_HOME/extensions/GlobalNotice \
	&& git checkout -q 4d22d2b51f232dfbf0edc98fdbb2b5d3b08d885c \
	# GoogleAnalyticsMetrics
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleAnalyticsMetrics $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& cd $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& git checkout -q 491335f8183cce94dfb2c4051a993df0ebe0dd25 \
	# GoogleDocCreator
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocCreator $MW_HOME/extensions/GoogleDocCreator \
	&& cd $MW_HOME/extensions/GoogleDocCreator \
	&& git checkout -q 1d1507250c43d23cefb6a26c832c63b562868526

# H
RUN set -x; \
	cd $MW_HOME/extensions \
	# HeaderFooter
	&& git clone -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeaderFooter $MW_HOME/extensions/HeaderFooter \
	&& cd $MW_HOME/extensions/HeaderFooter \
	&& git checkout -q 3a85ddb49832b07b2db066068012fea4cf03d27f \
	# HeaderTabs (v2.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/HeaderTabs $MW_HOME/extensions/HeaderTabs \
	&& cd $MW_HOME/extensions/HeaderTabs \
	&& git checkout -q 42aaabf1deeb0a228fc99e578ff7ec925e560dd7 \
	# HTMLTags
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HTMLTags $MW_HOME/extensions/HTMLTags \
	&& cd $MW_HOME/extensions/HTMLTags \
	&& git checkout -q 3c2756d234a1c2432c8c7051efc8ca685861c6cb

# L
RUN set -x; \
	cd $MW_HOME/extensions \
	# LabeledSectionTransclusion
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LabeledSectionTransclusion $MW_HOME/extensions/LabeledSectionTransclusion \
	&& cd $MW_HOME/extensions/LabeledSectionTransclusion \
	&& git checkout -q 695a5e05a883cc2299414add71e0021b2707c2de \
	# LDAPAuthentication2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPAuthentication2 $MW_HOME/extensions/LDAPAuthentication2 \
	&& cd $MW_HOME/extensions/LDAPAuthentication2 \
	&& git checkout -q c628fbe71b3c276f77cd96aa65ac0a27c70eaa68 \
	# LDAPAuthorization
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPAuthorization $MW_HOME/extensions/LDAPAuthorization \
	&& cd $MW_HOME/extensions/LDAPAuthorization \
	&& git checkout -q ea324c3d6e871f442162d3320fef7c98c5b82748 \
	# LDAPProvider
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPProvider $MW_HOME/extensions/LDAPProvider \
	&& cd $MW_HOME/extensions/LDAPProvider \
	&& git checkout -q 7a2747ed5f9682fd261d69b28fa259b1d70f2337 \
	# Lingo
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/Lingo $MW_HOME/extensions/Lingo \
	&& cd $MW_HOME/extensions/Lingo \
	&& git checkout -q 173efe9bf715988f9aa4b95ea401613f72774f2a \
	# LinkSuggest
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkSuggest $MW_HOME/extensions/LinkSuggest \
	&& cd $MW_HOME/extensions/LinkSuggest \
	&& git checkout -q f3afa1c88f6f541043591cb9d1d8351e7ea9ee27 \
	# LinkTarget
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkTarget $MW_HOME/extensions/LinkTarget \
	&& cd $MW_HOME/extensions/LinkTarget \
	&& git checkout -q 12d288d8050f8b97f3c955f6d9a65e3305b5c4ed \
	# LockAuthor
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LockAuthor $MW_HOME/extensions/LockAuthor \
	&& cd $MW_HOME/extensions/LockAuthor \
	&& git checkout -q 3dca9ee1b91547c8f15a2e6aef80a67acb7d2b4d \
	# Lockdown
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Lockdown $MW_HOME/extensions/Lockdown \
	&& cd $MW_HOME/extensions/Lockdown \
	&& git checkout -q 1f284421afcc3ada40177c5362404d7de28e2394 \
	# LookupUser
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LookupUser $MW_HOME/extensions/LookupUser \
	&& cd $MW_HOME/extensions/LookupUser \
	&& git checkout -q 9e46dc863a54bd3b61f0e3a5b42069b9605e50ce \
	# Loops
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Loops $MW_HOME/extensions/Loops \
	&& cd $MW_HOME/extensions/Loops \
	&& git checkout -q f2bff84ee1701c609607829e76a590d1d05c8a07 \
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
	&& git checkout -q 3d32e452cdf72effd024f9c8b7d568753423e2d4 \
	# MassMessage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessage $MW_HOME/extensions/MassMessage \
	&& cd $MW_HOME/extensions/MassMessage \
	&& git checkout -q 67b957c858d098cc8075ab64f60e68ab15c08b50 \
	# MassMessageEmail
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessageEmail $MW_HOME/extensions/MassMessageEmail \
	&& cd $MW_HOME/extensions/MassMessageEmail \
	&& git checkout -q ab7bc116ca948339c27810803f9bffb0c7457df6 \
	# MediaUploader
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MediaUploader $MW_HOME/extensions/MediaUploader \
	&& cd $MW_HOME/extensions/MediaUploader \
	&& git checkout -q 544ee0e3c7e70dc2d823652009f46ec142d3221f \
	# MintyDocs (1.0)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/MintyDocs $MW_HOME/extensions/MintyDocs \
	&& cd $MW_HOME/extensions/MintyDocs \
	&& git checkout -q 4496e33ce71d2c364b16599619c961a1a330bf14 \
	# MobileFrontend
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend $MW_HOME/extensions/MobileFrontend \
	&& cd $MW_HOME/extensions/MobileFrontend \
	&& git checkout -q d75f1756b6831ea9fc1febaed98a89d92668627f \
	# MsUpload
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MsUpload $MW_HOME/extensions/MsUpload \
	&& cd $MW_HOME/extensions/MsUpload \
	&& git checkout -q 2cbd8034bbc80c81735d5aac09f0c56a8c2a0933 \
	# MyVariables
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MyVariables $MW_HOME/extensions/MyVariables \
	&& cd $MW_HOME/extensions/MyVariables \
	&& git checkout -q 502023337c484483fbf775eae930b30b95f5b298

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
	&& git checkout -q cf6f0d8dbbb30b9aa4b2de61bca791bc144884bd \
	# NumerAlpha
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/NumerAlpha $MW_HOME/extensions/NumerAlpha \
	&& cd $MW_HOME/extensions/NumerAlpha \
	&& git checkout -q f792da2842527b4f1ea1c12fd3618b0e288276d2

# O
RUN set -x; \
	cd $MW_HOME/extensions \
	# OpenGraphMeta
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenGraphMeta $MW_HOME/extensions/OpenGraphMeta \
	&& cd $MW_HOME/extensions/OpenGraphMeta \
	&& git checkout -q 818911ce2dc5b32be88624440c01a552fc2c31c8 \
	# OpenIDConnect
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenIDConnect $MW_HOME/extensions/OpenIDConnect \
	&& cd $MW_HOME/extensions/OpenIDConnect \
	&& git checkout -q 6302f7564032857cbb341c44cf6e93bcc757d3d7
# P
RUN set -x; \
	cd $MW_HOME/extensions \
	# PageExchange
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PageExchange $MW_HOME/extensions/PageExchange \
	&& cd $MW_HOME/extensions/PageExchange \
	&& git checkout -q b6fe54d43af5691203e5136d6cf7952002c199b1 \
	# PageForms (v. 5.6.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms $MW_HOME/extensions/PageForms \
	&& cd $MW_HOME/extensions/PageForms \
	&& git checkout -q f90d67ecc2c111e82db454c71592c83384ff9704 \
	# PluggableAuth
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PluggableAuth $MW_HOME/extensions/PluggableAuth \
	&& cd $MW_HOME/extensions/PluggableAuth \
	&& git checkout -q 48f66a44c48167c7d2fd85130b23cfc162396085 \
	# Popups
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups $MW_HOME/extensions/Popups \
	&& cd $MW_HOME/extensions/Popups \
	&& git checkout -q 7b7063ed4805d9d737e656b38a2b34f62e28ad49 \
	# PagePort
	&& git clone --single-branch -b master https://github.com/WikiTeq/PagePort.git $MW_HOME/extensions/PagePort \
	&& cd $MW_HOME/extensions/PagePort \
	&& git checkout -q d4d734c26c215ed7306be8cd1edc4b0cd8d561cd

# R
RUN set -x; \
	cd $MW_HOME/extensions \
	# RegularTooltips
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RegularTooltips $MW_HOME/extensions/RegularTooltips \
	&& cd $MW_HOME/extensions/RegularTooltips \
	&& git checkout -q 3d17eae871ad7daeb54870122a1e3383962a91c4 \
	# RevisionSlider
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RevisionSlider $MW_HOME/extensions/RevisionSlider \
	&& cd $MW_HOME/extensions/RevisionSlider \
	&& git checkout -q 4f4efd1f1d7365577c53ee9e42217374541b0c94 \
	# RottenLinks
	&& git clone --single-branch -b master https://github.com/miraheze/RottenLinks.git $MW_HOME/extensions/RottenLinks \
	&& cd $MW_HOME/extensions/RottenLinks \
	&& git checkout -q a96e99d0a61a42d59587a67db0720ce245a7ee46

# S
RUN set -x; \
	cd $MW_HOME/extensions \
	# SandboxLink
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SandboxLink $MW_HOME/extensions/SandboxLink \
	&& cd $MW_HOME/extensions/SandboxLink \
	&& git checkout -q 435da8e26a0f47902a23e7ab904baf7cf0452dc2 \
	# SaveSpinner
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SaveSpinner $MW_HOME/extensions/SaveSpinner \
	&& cd $MW_HOME/extensions/SaveSpinner \
	&& git checkout -q cb180f25978b9b287d9155bb3aa8ae32ac45a887 \
	# SemanticDependencyUpdater (WikiTeq fork)
	&& git clone --single-branch -b old-master https://github.com/WikiTeq/SemanticDependencyUpdater.git $MW_HOME/extensions/SemanticDependencyUpdater \
	&& cd $MW_HOME/extensions/SemanticDependencyUpdater \
	&& git checkout -q 3eedd54d4b4d4bfb6f15c2f56162b38095ebdb4c \
	# SimpleChanges
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SimpleChanges $MW_HOME/extensions/SimpleChanges \
	&& cd $MW_HOME/extensions/SimpleChanges \
	&& git checkout -q 8dcaff95604fb9a982c77ca87614ccae3d382b61 \
	# SimpleMathJax
	&& git clone --single-branch https://github.com/jmnote/SimpleMathJax.git $MW_HOME/extensions/SimpleMathJax \
	&& cd $MW_HOME/extensions/SimpleMathJax \
	&& git checkout -q 3757e9b1cf235b2e2c62e7d208d52206e185b28e \
	# SkinPerPage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerPage $MW_HOME/extensions/SkinPerPage \
	&& cd $MW_HOME/extensions/SkinPerPage \
	&& git checkout -q fd1ae80e25a84c8a33b2eda7b5adecc2a7772025 \
	# SmiteSpam
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SmiteSpam $MW_HOME/extensions/SmiteSpam \
	&& cd $MW_HOME/extensions/SmiteSpam \
	&& git checkout -q ab1f75d896283d3144c14333114d919b1e6c9bbc

# T
RUN set -x; \
	cd $MW_HOME/extensions \
	# TemplateStyles
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles $MW_HOME/extensions/TemplateStyles \
	&& cd $MW_HOME/extensions/TemplateStyles \
	&& git checkout -q f8062128bf418c0590d1e2245cbf9edd7543b4d9 \
	# TemplateWizard
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateWizard $MW_HOME/extensions/TemplateWizard \
	&& cd $MW_HOME/extensions/TemplateWizard \
	&& git checkout -q 18b6ca143638ec9f32fe2af691803f753096c585 \
	# TimedMediaHandler
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TimedMediaHandler $MW_HOME/extensions/TimedMediaHandler \
	&& cd $MW_HOME/extensions/TimedMediaHandler \
	&& git checkout -q 23d802660d6730a2d6bc1a286606607ebb95ed9a \
	# TinyMCE
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TinyMCE $MW_HOME/extensions/TinyMCE \
	&& cd $MW_HOME/extensions/TinyMCE \
	&& git checkout -q ef37540d2d44038e860e040a33e935e5e57e2192 \
	# TitleIcon
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TitleIcon $MW_HOME/extensions/TitleIcon \
	&& cd $MW_HOME/extensions/TitleIcon \
	&& git checkout -q 9fea6799d72ea8c36874a50e974c50dd0e99ca54

# U
RUN set -x; \
	cd $MW_HOME/extensions \
	# UniversalLanguageSelector
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UniversalLanguageSelector $MW_HOME/extensions/UniversalLanguageSelector \
	&& cd $MW_HOME/extensions/UniversalLanguageSelector \
	&& git checkout -q 800a1b6df6408d5c4841187764e9754235092eec \
	# UploadWizard
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UploadWizard $MW_HOME/extensions/UploadWizard \
	&& cd $MW_HOME/extensions/UploadWizard \
	&& git checkout -q 86d482639381aa898036852802a3be370e910efb \
	# UrlGetParameters
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UrlGetParameters $MW_HOME/extensions/UrlGetParameters \
	&& cd $MW_HOME/extensions/UrlGetParameters \
	&& git checkout -q 913d6bde612aa5115a1f7f2e7960a750f6e3a69d \
	# UserFunctions
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserFunctions $MW_HOME/extensions/UserFunctions \
	&& cd $MW_HOME/extensions/UserFunctions \
	&& git checkout -q 84d16acba42cff9066f8b131b1d2aaef5bf39cc0 \
	# UserMerge
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge $MW_HOME/extensions/UserMerge \
	&& cd $MW_HOME/extensions/UserMerge \
	&& git checkout -q c665fedc8021fc629a84456f65954ae35ac918bd \
	# UserPageViewTracker (v. 0.7)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/UserPageViewTracker $MW_HOME/extensions/UserPageViewTracker \
	&& cd $MW_HOME/extensions/UserPageViewTracker \
	&& git checkout -q f4b7c20c372165541164d449c12df1e74e98ed0b

# V
RUN set -x; \
	cd $MW_HOME/extensions \
	# Variables
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Variables $MW_HOME/extensions/Variables \
	&& cd $MW_HOME/extensions/Variables \
	&& git checkout -q fe29b81db571c7ae640096b09dbdd535c05a966d \
	# VEForAll (v. 0.5.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/VEForAll $MW_HOME/extensions/VEForAll \
	&& cd $MW_HOME/extensions/VEForAll \
	&& git checkout -q 85a4b8e57bd61c81fbf810e4f858d3a220181b4f \
	# VoteNY
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY $MW_HOME/extensions/VoteNY \
	&& cd $MW_HOME/extensions/VoteNY \
	&& git checkout -q dcc95f9e3ca6ec58d40145b607f0603229b17995

# W
RUN set -x; \
	cd $MW_HOME/extensions \
	# WatchAnalytics (v. 4.1.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/WatchAnalytics $MW_HOME/extensions/WatchAnalytics \
	&& cd $MW_HOME/extensions/WatchAnalytics \
	&& git checkout -q 72b70a667a26bbde0a3cf93fc79747aae08fca32 \
	# WhoIsWatching
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WhoIsWatching $MW_HOME/extensions/WhoIsWatching \
	&& cd $MW_HOME/extensions/WhoIsWatching \
	&& git checkout -q f645bba33f5a81c92b7e05abe1ba6d72bf260ed5 \
	# Widgets
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets $MW_HOME/extensions/Widgets \
	&& cd $MW_HOME/extensions/Widgets \
	&& git checkout -q 7726030308f299374aa6acb7142761be890d1d66 \
	# WikiForum
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiForum $MW_HOME/extensions/WikiForum \
	&& cd $MW_HOME/extensions/WikiForum \
	&& git checkout -q d9dbec739f3ab57cd1ffa949c32a528970398937 \
	# WikiSEO
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiSEO $MW_HOME/extensions/WikiSEO \
	&& cd $MW_HOME/extensions/WikiSEO \
	&& git checkout -q 21331c57f39e3082f52d8be1666203b6caeaa4c4 \
	# WSOAuth
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WSOAuth $MW_HOME/extensions/WSOAuth \
	&& cd $MW_HOME/extensions/WSOAuth \
	&& git checkout -q 5084a6f6a3640e16940a2de15c8deef4d89b9b6c

#### WikiTeq extensions ####

# B
RUN set -x; \
	cd $MW_HOME/extensions \
	# Buggy
	&& git clone --single-branch -b $MW_VERSION https://github.com/wikimedia/mediawiki-extensions-Buggy.git $MW_HOME/extensions/Buggy \
	&& cd $MW_HOME/extensions/Buggy \
	&& git checkout -q 3660baa690db11d63a780b7aa2d8f684fe0519ef

# C
RUN set -x; \
	cd $MW_HOME/extensions \
  	# ChangeAuthor
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ChangeAuthor $MW_HOME/extensions/ChangeAuthor \
	&& cd $MW_HOME/extensions/ChangeAuthor \
	&& git checkout -q af6966798acd33e56dee66a80df68056bd572a9c \
	# Citoid
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Citoid $MW_HOME/extensions/Citoid \
	&& cd $MW_HOME/extensions/Citoid \
	&& git checkout -q 0c16f1b6b2f561d013918ed13f6e3b7d718d555e

# E
RUN set -x; \
	cd $MW_HOME/extensions \
   	# EditAccount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EditAccount $MW_HOME/extensions/EditAccount \
	&& cd $MW_HOME/extensions/EditAccount \
	&& git checkout -q 9f09ba09384f9095d908b1468fe316f36fc66d59 \
	# Flow
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Flow $MW_HOME/extensions/Flow \
	&& cd $MW_HOME/extensions/Flow \
	&& git checkout -q 554e2b21f006a30cc4784ad770444b22411b7755

# G
RUN set -x; \
	cd $MW_HOME/extensions \
  	# GoogleDocTag
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocTag $MW_HOME/extensions/GoogleDocTag \
	&& cd $MW_HOME/extensions/GoogleDocTag \
	&& git checkout -q f2e46e9bee836ac06e9d172c25e7edc567af16ce \
	# GTag
	&& git clone https://github.com/SkizNet/mediawiki-GTag.git $MW_HOME/extensions/GTag \
	&& cd $MW_HOME/extensions/GTag \
	&& git checkout -q 5b3ac10946e8242da5d63d981875e4dad3e14f9d

# H
RUN set -x; \
	cd $MW_HOME/extensions \
   	# HeadScript
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeadScript $MW_HOME/extensions/HeadScript \
	&& cd $MW_HOME/extensions/HeadScript \
	&& git checkout -q f3b4c14e98847e4cb5696830c8012a3ffe79fc2e

# I
RUN set -x; \
	cd $MW_HOME/extensions \
   	# IframePage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/IframePage $MW_HOME/extensions/IframePage \
	&& cd $MW_HOME/extensions/IframePage \
	&& git checkout -q d59b62a2b3463c0e429e04ac53abe9e6d38aa5d5

# L
RUN set -x; \
	cd $MW_HOME/extensions \
  	# Lazyload
	&& git clone https://github.com/mudkipme/mediawiki-lazyload.git $MW_HOME/extensions/Lazyload \
	&& cd $MW_HOME/extensions/Lazyload \
	&& git checkout -b $MW_VERSION 30a01cc149822353c9404ec178ec01848bae65c5 \
	# LiquidThreads
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LiquidThreads $MW_HOME/extensions/LiquidThreads \
	&& cd $MW_HOME/extensions/LiquidThreads \
	&& git checkout -q d4bd7f30a7be60301bab02dd460d60b2cf359e64

# M
RUN set -x; \
	cd $MW_HOME/extensions \
   	# MassPasswordReset
	# No 1.43 yet
	&& cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/MassPasswordReset.git \
	&& cd MassPasswordReset \
	&& git checkout -b REL1_39 04b7e765db994d41f5ca3a910e18f77105218d94 \
	# MobileDetect
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileDetect $MW_HOME/extensions/MobileDetect \
	&& cd $MW_HOME/extensions/MobileDetect \
	&& git checkout -q 0df26d2d7b6b8dd307cbb005655dca97465132fa \
	# Mpdf
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Mpdf.git $MW_HOME/extensions/Mpdf \
	&& cd $MW_HOME/extensions/Mpdf \
	&& git checkout -q 239d467b1f7f9cd4be5f124cfe000c89478c9d0a

# P
RUN set -x; \
	cd $MW_HOME/extensions \
   	# PageSchemas
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PageSchemas $MW_HOME/extensions/PageSchemas \
	&& cd $MW_HOME/extensions/PageSchemas \
	&& git checkout -q c2ee07edd0dba64dffe3cff2faf861f67c1025a3 \
	# PDFEmbed
	&& git clone https://github.com/WolfgangFahl/PDFEmbed.git $MW_HOME/extensions/PDFEmbed \
	&& cd $MW_HOME/extensions/PDFEmbed \
	&& git checkout -q 2b07a1c18cef4794f4cb2429baa2d55fdb2beed3 \
	# PubmedParser
	# No 1.43 yet
	&& cd $MW_HOME/extensions \
	&& git clone https://github.com/bovender/PubmedParser.git \
	&& cd PubmedParser \
	&& git checkout -b REL1_39 b77635651cc8ef2d39fd0f04fe73285c4ea3cd19

# S
RUN set -x; \
	cd $MW_HOME/extensions \
  	# Scopus
	# No 1.43 yet
	&& git clone https://github.com/nischayn22/Scopus.git $MW_HOME/extensions/Scopus \
	&& cd $MW_HOME/extensions/Scopus \
	&& git checkout -b REL1_39 4fe8048459d9189626d82d9d93a0d5f906c43746 \
	# SelectCategory
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SelectCategory $MW_HOME/extensions/SelectCategory \
	&& cd $MW_HOME/extensions/SelectCategory \
	&& git checkout -q 1f351647af2e235e11139aa8f1b70c19a3556c61 \
	# SemanticQueryInterface
	&& git clone https://github.com/vedmaka/SemanticQueryInterface.git $MW_HOME/extensions/SemanticQueryInterface \
	&& cd $MW_HOME/extensions/SemanticQueryInterface \
	&& git checkout -q 0016305a95ecbb6ed4709bfa3fc6d9995d51336f \
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
	&& git checkout -q e08d7bdda66d97eb22d241156f3b13423acafaa5 \
	# SimpleTooltip
	# No 1.43 yet
	&& git clone https://github.com/Universal-Omega/SimpleTooltip.git $MW_HOME/extensions/SimpleTooltip \
	&& cd $MW_HOME/extensions/SimpleTooltip \
	&& git checkout -b REL1_39 a918f4a6f095e9d8cc9fde0efad7acef472d2e94 \
	# SimpleTippy
	&& git clone https://github.com/vedmaka/mediawiki-extension-SimpleTippy.git $MW_HOME/extensions/SimpleTippy \
	&& cd $MW_HOME/extensions/SimpleTippy \
	&& git checkout -q 271d5e3340e63627058081acc641ec2623eee9dd \
	# Skinny
	&& git clone https://github.com/tinymighty/skinny.git $MW_HOME/extensions/Skinny \
	&& cd $MW_HOME/extensions/Skinny \
	&& git checkout -q 512e07818556e9b9baa07154371dab3201bfb435 \
	# SkinPerNamespace
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerNamespace $MW_HOME/extensions/SkinPerNamespace \
	&& cd $MW_HOME/extensions/SkinPerNamespace \
	&& git checkout -q da9ebd039dc64d71653394cdfcf035a1f1da36ce \
	# Survey
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Survey $MW_HOME/extensions/Survey \
	&& cd $MW_HOME/extensions/Survey \
	&& git checkout -q d7cc11998742285448d7d9036da245052683211b

# T
RUN set -x; \
	cd $MW_HOME/extensions \
   	# Tabber
	&& git clone https://gitlab.com/hydrawiki/extensions/Tabber.git $MW_HOME/extensions/Tabber \
	&& cd $MW_HOME/extensions/Tabber \
	&& git checkout -q 6c67baf4d18518fa78e07add4c032d62dd384b06 \
	# TabberNeue
	&& git clone https://github.com/StarCitizenTools/mediawiki-extensions-TabberNeue.git $MW_HOME/extensions/TabberNeue \
	&& cd $MW_HOME/extensions/TabberNeue \
	&& git checkout -q 7f04013085a2d80304849b978fc94bb472bf0b36 \
	# Tabs
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Tabs $MW_HOME/extensions/Tabs \
	&& cd $MW_HOME/extensions/Tabs \
	&& git checkout -q d99cd0c47111ed5c8cdc44821f4a269a547687a1 \
	# TwitterTag
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TwitterTag $MW_HOME/extensions/TwitterTag \
	&& cd $MW_HOME/extensions/TwitterTag \
	&& git checkout -q 52f95843ac33ba4df73a312305838e37fc6cd658

# U
RUN set -x; \
	cd $MW_HOME/extensions \
   	# UploadWizardExtraButtons
	&& git clone https://github.com/vedmaka/mediawiki-extension-UploadWizardExtraButtons.git $MW_HOME/extensions/UploadWizardExtraButtons \
	&& cd $MW_HOME/extensions/UploadWizardExtraButtons \
	&& git checkout -q accba1b9b6f50e67d709bd727c9f4ad6de78c0c0

# Y
RUN set -x; \
	cd $MW_HOME/extensions \
   	# YouTube
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/YouTube $MW_HOME/extensions/YouTube \
	&& cd $MW_HOME/extensions/YouTube \
	&& git checkout -q 99a668210d8a5020f27c52b0c32381105c9ee19c

# G
RUN set -x; \
	cd $MW_HOME/extensions \
   	# GoogleLogin
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleLogin $MW_HOME/extensions/GoogleLogin \
	&& cd $MW_HOME/extensions/GoogleLogin \
	&& git checkout -q d15d480a753aa433a5e024c5ca1ea78999947fe2

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
    && git clone --single-branch -b REL1_43 https://github.com/WikiTeq/WSSlots.git $MW_HOME/extensions/WSSlots \
    && cd $MW_HOME/extensions/WSSlots \
    && git checkout -q a46d1309ab11034aa7e3a762e392346c1b0ecd67

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

# GoogleLogin gerrit patches 1070987 and 1074530 applied to REL1_43
COPY _sources/patches/GoogleLogin-fixes.patch /tmp/GoogleLogin-fixes.patch
RUN set -x; \
	cd $MW_HOME/extensions/GoogleLogin \
	&& git apply /tmp/GoogleLogin-fixes.patch

# GoogleAnalyticsMetrics pins google/apiclient to 2.12.6, relax it
COPY _sources/patches/GoogleAnalyticsMetrics-relax-pin.patch /tmp/GoogleAnalyticsMetrics-relax-pin.patch
RUN set -x; \
	cd $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& git apply /tmp/GoogleAnalyticsMetrics-relax-pin.patch

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/extensions \
	&& find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

FROM base AS composer

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

FROM base AS final

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
	APACHE_REMOTE_IP_HEADER=X-Forwarded-For \
	MW_AUTO_IMPORT=1

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
	&& cp "$MW_HOME/includes/Output/NoLocalSettings.php" "$MW_HOME/includes/CanastaNoLocalSettings.php" \
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
