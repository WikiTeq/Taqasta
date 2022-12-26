FROM debian:11.5 as base

LABEL maintainers="pastakhov@yandex.ru,alexey@wikiteq.com"
LABEL org.opencontainers.image.source=https://github.com/WikiTeq/Taqasta

ARG COMPOSER_TOKEN

ENV MW_VERSION=REL1_39 \
	MW_CORE_VERSION=1.39.1 \
	WWW_ROOT=/var/www/mediawiki \
	MW_HOME=/var/www/mediawiki/w \
	MW_LOG=/var/log/mediawiki \
	MW_ORIGIN_FILES=/mw_origin_files \
	MW_VOLUME=/mediawiki \
	WWW_USER=www-data \
	WWW_GROUP=www-data \
	APACHE_LOG_DIR=/var/log/apache2 \
	COMPOSER_TOKEN=$COMPOSER_TOKEN

# System setup
RUN set x; \
	apt-get clean \
	&& apt-get update \
	&& apt-get install -y aptitude \
	&& aptitude -y upgrade \
	&& aptitude install -y \
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
	ffmpeg \
	curl \
	iputils-ping \
	unzip \
	gnupg \
	default-mysql-client \
	rsync \
	lynx \
	poppler-utils \
	&& aptitude update \
	&& aptitude install -y \
	php7.4 \
	php7.4-mysql \
	php7.4-cli \
	php7.4-gd \
	php7.4-mbstring \
	php7.4-xml \
	php7.4-mysql \
	php7.4-intl \
	php7.4-opcache \
	php7.4-apcu \
	php7.4-redis \
	php7.4-curl \
	php7.4-tidy \
	php7.4-zip \
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
	&& aptitude clean \
	&& rm -rf /var/lib/apt/lists/*

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

FROM base as source

# MediaWiki Core
RUN set -x; \
	git clone --depth 1 -b $MW_CORE_VERSION https://gerrit.wikimedia.org/r/mediawiki/core.git $MW_HOME \
	&& cd $MW_HOME \
	&& git submodule update --init --recursive

# Skins
# The MonoBook, Timeless and Vector skins are bundled into MediaWiki and do not need to be separately installed.
# The Chameleon skin is downloaded via Composer and also does not need to be installed.
RUN set -x; \
	cd $MW_HOME/skins \
	# CologneBlue
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/CologneBlue $MW_HOME/skins/CologneBlue \
	&& cd $MW_HOME/skins/CologneBlue \
	&& git checkout -q 4d588eb78d7e64e574f631c5897579537305437d \
	# MinervaNeue
	#&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue $MW_HOME/skins/MinervaNeue \
	#&& cd $MW_HOME/skins/MinervaNeue \
	#&& git checkout -q e4741ff2c4375c2befee0d9f350aff6eb6e1a4da \
	# Modern
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Modern $MW_HOME/skins/Modern \
	&& cd $MW_HOME/skins/Modern \
	&& git checkout -q fb6c2831b5f150e9b82d98d661710695a2d0f8f2 \
	# Pivot
	&& git clone -b v2.3.0 https://github.com/wikimedia/mediawiki-skins-Pivot $MW_HOME/skins/pivot \
	&& cd $MW_HOME/skins/pivot \
	&& git checkout -q d79af7514347eb5272936243d4013118354c85c1 \
	# Refreshed
	&& git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed $MW_HOME/skins/Refreshed \
	&& cd $MW_HOME/skins/Refreshed \
	&& git checkout -q 86f33620f25335eb62289aa18d342ff3b980d8b8

# Extensions
# The following extensions are bundled into MediaWiki and do not need to be separately installed (though in some cases
# they are modified): AbuseFilter, CategoryTree, Cite, CiteThisPage, CodeEditor, ConfirmEdit, Gadgets, ImageMap,
# InputBox, Interwiki, LocalisationUpdate, Math, MultimediaViewer, Nuke, OATHAuth, PageImages, ParserFunctions,
# PdfHandler, Poem, Renameuser, Replace Text, Scribunto, SecureLinkFixer, SpamBlacklist, SyntaxHighlight, TemplateData,
# TextExtracts, TitleBlacklist, VisualEditor, WikiEditor.
# The following extensions are downloaded via Composer and also do not need to be downloaded here: Bootstrap,
# BootstrapComponents, Maps, Semantic Breadcrumb Links, Semantic Compound Queries, Semantic Extra Special Properties,
# Semantic MediaWiki (along with all its helper library extensions, like DataValues), Semantic Result Formats, Semantic
# Scribunto, SimpleBatchUpload, SubPageList.
RUN set -x; \
	cd $MW_HOME/extensions \
	# AdminLinks
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AdminLinks $MW_HOME/extensions/AdminLinks \
	&& cd $MW_HOME/extensions/AdminLinks \
	&& git checkout -q ad7805941ee29378484d1ef3595041f7d2c15913 \
	# AdvancedSearch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AdvancedSearch $MW_HOME/extensions/AdvancedSearch \
	&& cd $MW_HOME/extensions/AdvancedSearch \
	&& git checkout -q 1a44eafc93a17938333b74a37cb4deff2192e50a \
	# AJAXPoll
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AJAXPoll $MW_HOME/extensions/AJAXPoll \
	&& cd $MW_HOME/extensions/AJAXPoll \
	&& git checkout -q 8429d8d4cba5be6df04e3fec17b0daabbf10cfa7 \
	# AntiSpoof
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AntiSpoof $MW_HOME/extensions/AntiSpoof \
	&& cd $MW_HOME/extensions/AntiSpoof \
	&& git checkout -q 01cf89a678d5bab6610d24e07d3534356a5880cb \
	# ApprovedRevs (v. 1.8)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/ApprovedRevs $MW_HOME/extensions/ApprovedRevs \
	&& cd $MW_HOME/extensions/ApprovedRevs \
	&& git checkout -q 6e9c957f2f7951f19054ecae8745e55c0425941f \
	# Arrays
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Arrays $MW_HOME/extensions/Arrays \
	&& cd $MW_HOME/extensions/Arrays \
	&& git checkout -q 338f661bf0ab377f70e029079f2c5c5b370219df \
	# BetaFeatures
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BetaFeatures $MW_HOME/extensions/BetaFeatures \
	&& cd $MW_HOME/extensions/BetaFeatures \
	&& git checkout -q 09cca44341f9695446c4e9fc9e8fec3fdcb197b0 \
	# BreadCrumbs2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BreadCrumbs2 $MW_HOME/extensions/BreadCrumbs2 \
	&& cd $MW_HOME/extensions/BreadCrumbs2 \
	&& git checkout -q d53357a6839e94800a617de4fc451b6c64d0a1c8 \
	# Cargo (v. 3.3.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/Cargo $MW_HOME/extensions/Cargo \
	&& cd $MW_HOME/extensions/Cargo \
	&& git checkout -q dac6b0da0e3cb5a4226601ebccf1689dbaa6bec7 \
	# CharInsert
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CharInsert $MW_HOME/extensions/CharInsert \
	&& cd $MW_HOME/extensions/CharInsert \
	&& git checkout -q 54c0f0ca9119a3ce791fb5d53edd4ec32035a5c5 \
	# CheckUser
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CheckUser $MW_HOME/extensions/CheckUser \
	&& cd $MW_HOME/extensions/CheckUser \
	&& git checkout -q 9e2b6d3e928855247700146273d8131e025de918 \
	# CirrusSearch
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch $MW_HOME/extensions/CirrusSearch \
	&& cd $MW_HOME/extensions/CirrusSearch \
	&& git checkout -q 8296300873aaffe815800cf05c84fa04c8cbd2c0 \
	# CodeMirror
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror $MW_HOME/extensions/CodeMirror \
	&& cd $MW_HOME/extensions/CodeMirror \
	&& git checkout -q 27efed79972ca181a194d17f4a94f4192fd5a493 \
	# Collection
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Collection $MW_HOME/extensions/Collection \
	&& cd $MW_HOME/extensions/Collection \
	&& git checkout -q e00e70c6fcec963c8876e410e52c83c75ed60827 \
	# CommentStreams
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommentStreams $MW_HOME/extensions/CommentStreams \
	&& cd $MW_HOME/extensions/CommentStreams \
	&& git checkout -q 274bb10bc2d39fd137650dbc0dfc607c766d1aaa \
	# CommonsMetadata
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommonsMetadata $MW_HOME/extensions/CommonsMetadata \
	&& cd $MW_HOME/extensions/CommonsMetadata \
	&& git checkout -q 8ee30de3b1cabbe55c484839127493fd5fa5d076 \
	# ConfirmAccount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmAccount $MW_HOME/extensions/ConfirmAccount \
	&& cd $MW_HOME/extensions/ConfirmAccount \
	&& git checkout -q c06d5dfb43811a2dee99099476c57af2b6d762c4 \
	# ContactPage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContactPage $MW_HOME/extensions/ContactPage \
	&& cd $MW_HOME/extensions/ContactPage \
	&& git checkout -q f509796056ae1fc597b6e3c3c268fac35bf66636 \
	# ContributionScores
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContributionScores $MW_HOME/extensions/ContributionScores \
	&& cd $MW_HOME/extensions/ContributionScores \
	&& git checkout -q e307850555ef313f623dde6e2f1d5d2a43663730 \
	# CookieWarning
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CookieWarning $MW_HOME/extensions/CookieWarning \
	&& cd $MW_HOME/extensions/CookieWarning \
	&& git checkout -q bc991e93133bd69fe45e07b3d4554225decc7dae \
	# DataTransfer
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DataTransfer $MW_HOME/extensions/DataTransfer \
	&& cd $MW_HOME/extensions/DataTransfer \
	&& git checkout -q 2f9f949f71f0bb7d1bd8b6b97c795b9428bb1c71 \
	# Description2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 $MW_HOME/extensions/Description2 \
	&& cd $MW_HOME/extensions/Description2 \
	&& git checkout -q d2a5322a44f940de873050573e35fba4eb3063f8 \
	# Disambiguator
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator $MW_HOME/extensions/Disambiguator \
	&& cd $MW_HOME/extensions/Disambiguator \
	&& git checkout -q b7e7fad5f9f3dccfb902a3cbfd3bf2b16df91871 \
	# DismissableSiteNotice
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DismissableSiteNotice $MW_HOME/extensions/DismissableSiteNotice \
	&& cd $MW_HOME/extensions/DismissableSiteNotice \
	&& git checkout -q 88129f80f077ec9e4932148056c8cfc1ed0361c7 \
	# DisplayTitle
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DisplayTitle $MW_HOME/extensions/DisplayTitle \
	&& cd $MW_HOME/extensions/DisplayTitle \
	&& git checkout -q a14c406cc273c73a12957b55a27c095ad98d1795 \
	# Echo
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Echo $MW_HOME/extensions/Echo \
	&& cd $MW_HOME/extensions/Echo \
	&& git checkout -q fdbc2cafdc412dc60d4345511defe9ee393efecf \
	# Editcount
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Editcount $MW_HOME/extensions/Editcount \
	&& cd $MW_HOME/extensions/Editcount \
	&& git checkout -q 41544ffceb1356f91575dc6772a48b172751d7cc \
	# Elastica
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica $MW_HOME/extensions/Elastica \
	&& cd $MW_HOME/extensions/Elastica \
	&& git checkout -q e4ead38b71ed4f3df8dc689fe448b749771b4ed4 \
	# EmailAuthorization
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EmailAuthorization $MW_HOME/extensions/EmailAuthorization \
	&& cd $MW_HOME/extensions/EmailAuthorization \
	&& git checkout -q 2016da1b354f741d89b5dc207d4a84e11ffe9bce \
	&& git submodule update --init --recursive \
	# EmbedVideo
	&& git clone --single-branch -b master https://gitlab.com/hydrawiki/extensions/EmbedVideo.git $MW_HOME/extensions/EmbedVideo \
	&& cd $MW_HOME/extensions/EmbedVideo \
	&& git checkout -q 954af96d3744d8adc7ff6458a05e579784f2d991 \
	# EventLogging
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventLogging $MW_HOME/extensions/EventLogging \
	&& cd $MW_HOME/extensions/EventLogging \
	&& git checkout -q 2740dbcd139be279ca2a4db039739b4f796b4178 \
	# EventStreamConfig
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventStreamConfig $MW_HOME/extensions/EventStreamConfig \
	&& cd $MW_HOME/extensions/EventStreamConfig \
	&& git checkout -q 1aae8cb6c312e49f0126091a59a453cb224657f9 \
	# ExternalData (v. 3.2)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/ExternalData $MW_HOME/extensions/ExternalData \
	&& cd $MW_HOME/extensions/ExternalData \
	&& git checkout -q 5d30e60a65ca53a3fb5b39826deb2e6917892e22 \
	# FlexDiagrams
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/FlexDiagrams $MW_HOME/extensions/FlexDiagrams \
	&& cd $MW_HOME/extensions/FlexDiagrams \
	&& git checkout -q 550d0de3e2525d42952d7bc9d291b26455fe07ce \
	# GlobalNotice
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GlobalNotice $MW_HOME/extensions/GlobalNotice \
	&& cd $MW_HOME/extensions/GlobalNotice \
	&& git checkout -q 15a40bff4641f00a5a8dda3d36795b1c659c19a7 \
	# GoogleAnalyticsMetrics
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleAnalyticsMetrics $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& cd $MW_HOME/extensions/GoogleAnalyticsMetrics \
	&& git checkout -q 82a08cc63ec58698f144be7c2fb1a6f861cb57bd \
	# GoogleDocCreator
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocCreator $MW_HOME/extensions/GoogleDocCreator \
	&& cd $MW_HOME/extensions/GoogleDocCreator \
	&& git checkout -q 9e53ecfa4149688a2352a7898c2a2005632e1b7d \
	# Graph
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Graph $MW_HOME/extensions/Graph \
	&& cd $MW_HOME/extensions/Graph \
	&& git checkout -q 9c229eafdf406c95a4a666a6b7f2a9d0d3d682e4 \
	# HeaderFooter
	&& git clone https://github.com/enterprisemediawiki/HeaderFooter.git $MW_HOME/extensions/HeaderFooter \
	&& cd $MW_HOME/extensions/HeaderFooter \
	&& git checkout -q eee7d2c1a3373c7d6b326fd460e5d4859dd22c40 \
	# HeaderTabs
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeaderTabs $MW_HOME/extensions/HeaderTabs \
	&& cd $MW_HOME/extensions/HeaderTabs \
	&& git checkout -q b3d96193f3cacef5ac2637f197f0b2822597925e \
	# HTMLTags
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HTMLTags $MW_HOME/extensions/HTMLTags \
	&& cd $MW_HOME/extensions/HTMLTags \
	&& git checkout -q b8cb3131c5e76f5c037c8474fe14e51f2e877f03 \
	# LabeledSectionTransclusion
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LabeledSectionTransclusion $MW_HOME/extensions/LabeledSectionTransclusion \
	&& cd $MW_HOME/extensions/LabeledSectionTransclusion \
	&& git checkout -q 187abfeaafbad35eed4254f7a7ee0638980e932a \
	# LDAPAuthentication2
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPAuthentication2 $MW_HOME/extensions/LDAPAuthentication2 \
	&& cd $MW_HOME/extensions/LDAPAuthentication2 \
	&& git checkout -q 6bc584893d3157d5180e0e3ed93c3dbbc5b93056 \
	# LDAPAuthorization
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPAuthorization $MW_HOME/extensions/LDAPAuthorization \
	&& cd $MW_HOME/extensions/LDAPAuthorization \
	&& git checkout -q e6815d29c22f4b4eb85f868372a729ad49d7d3c8 \
	# LDAPProvider
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LDAPProvider $MW_HOME/extensions/LDAPProvider \
	&& cd $MW_HOME/extensions/LDAPProvider \
	&& git checkout -q 80f8cc8156b0cd250d0dfacd9378ed0db7c2091d \
	# Lingo
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Lingo $MW_HOME/extensions/Lingo \
	&& cd $MW_HOME/extensions/Lingo \
	&& git checkout -q a291fa25822097a4a2aefff242a876edadb535a4 \
	# LinkSuggest
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkSuggest $MW_HOME/extensions/LinkSuggest \
	&& cd $MW_HOME/extensions/LinkSuggest \
	&& git checkout -q 6005d191e35d1d6bed5a4e7bd1bedc5fa0030bf1 \
	# LinkTarget
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkTarget $MW_HOME/extensions/LinkTarget \
	&& cd $MW_HOME/extensions/LinkTarget \
	&& git checkout -q e5d592dcc72a00e06604ee3f65dfb8f99977c156 \
	# Linter
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Linter $MW_HOME/extensions/Linter \
	&& cd $MW_HOME/extensions/Linter \
	&& git checkout -q 8bc1727955da7468f096aa5c5b5790923db43d20 \
	# LockAuthor
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LockAuthor $MW_HOME/extensions/LockAuthor \
	&& cd $MW_HOME/extensions/LockAuthor \
	&& git checkout -q 4ebc4f221a0987b64740014a9380e9c3522f271d \
	# Lockdown
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Lockdown $MW_HOME/extensions/Lockdown \
	&& cd $MW_HOME/extensions/Lockdown \
	&& git checkout -q ffcb6e8892ad35bb731fad1dc24712a245ab86d0 \
	# LookupUser
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LookupUser $MW_HOME/extensions/LookupUser \
	&& cd $MW_HOME/extensions/LookupUser \
	&& git checkout -q 5fa17d449b6bedb3e8cee5b239af6cadae31da70 \
	# Loops
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Loops $MW_HOME/extensions/Loops \
	&& cd $MW_HOME/extensions/Loops \
	&& git checkout -q 0eb05a81b9b53f5381eefb4f8b6959b6dcdec1d8 \
	# MagicNoCache
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MagicNoCache $MW_HOME/extensions/MagicNoCache \
	&& cd $MW_HOME/extensions/MagicNoCache \
	&& git checkout -q 93534c12dac0e821c46c94b21053d274a6e557de \
	# MassMessage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessage $MW_HOME/extensions/MassMessage \
	&& cd $MW_HOME/extensions/MassMessage \
	&& git checkout -q d6a86291bb975c3dc7778f370006f1145cc834bd \
	# MassMessageEmail
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessageEmail $MW_HOME/extensions/MassMessageEmail \
	&& cd $MW_HOME/extensions/MassMessageEmail \
	&& git checkout -q edd96f14c6d108d56bcecb18b5bb7b3355437732 \
	# MediaUploader
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MediaUploader $MW_HOME/extensions/MediaUploader \
	&& cd $MW_HOME/extensions/MediaUploader \
	&& git checkout -q 1edd91c506c1c0319e7b9a3e71d639130760b1fd \
	# MintyDocs
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MintyDocs $MW_HOME/extensions/MintyDocs \
	&& cd $MW_HOME/extensions/MintyDocs \
	&& git checkout -q 7d5562dd5564eeb4c3b907a9eecd84a2f7654dd1 \
	# MobileFrontend
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend $MW_HOME/extensions/MobileFrontend \
	&& cd $MW_HOME/extensions/MobileFrontend \
	&& git checkout -q f0bed5588f76b827038fb9af73fb9677e5804077 \
	# MsUpload
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MsUpload $MW_HOME/extensions/MsUpload \
	&& cd $MW_HOME/extensions/MsUpload \
	&& git checkout -q dac2376a2fac6ddf4b2038db9b4bc06092ecaa15 \
	# MyVariables
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MyVariables $MW_HOME/extensions/MyVariables \
	&& cd $MW_HOME/extensions/MyVariables \
	&& git checkout -q 8b45be10c9b0a484824c55d8cc48399290384260 \
	# NewUserMessage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/NewUserMessage $MW_HOME/extensions/NewUserMessage \
	&& cd $MW_HOME/extensions/NewUserMessage \
	&& git checkout -q 206f32880fa7bf70b191d33ed80b8626bca39efe \
	# NumerAlpha
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/NumerAlpha $MW_HOME/extensions/NumerAlpha \
	&& cd $MW_HOME/extensions/NumerAlpha \
	&& git checkout -q 93c0869735581006a3f510096738e262d49f4107 \
	# OpenGraphMeta
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenGraphMeta $MW_HOME/extensions/OpenGraphMeta \
	&& cd $MW_HOME/extensions/OpenGraphMeta \
	&& git checkout -q d319702cd4ceda1967c233ef8e021b67b3fc355f \
	# OpenIDConnect
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/OpenIDConnect $MW_HOME/extensions/OpenIDConnect \
	&& cd $MW_HOME/extensions/OpenIDConnect \
	&& git checkout -q 0824f3cf3800f63e930abf0f03baf1a7c755a270 \
	# PageExchange
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PageExchange $MW_HOME/extensions/PageExchange \
	&& cd $MW_HOME/extensions/PageExchange \
	&& git checkout -q 28482410564e38d2b97ab7321e99c4281c6e5877 \
	# PageForms (v. 5.5.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms $MW_HOME/extensions/PageForms \
	&& cd $MW_HOME/extensions/PageForms \
	&& git checkout -q 74ebc5de5d1b515aeb59c848c3a9e3425da13114 \
	# PluggableAuth
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PluggableAuth $MW_HOME/extensions/PluggableAuth \
	&& cd $MW_HOME/extensions/PluggableAuth \
	&& git checkout -q 4be1e402e1862d165a4feb003c492ddc9525057e \
	# Popups
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups $MW_HOME/extensions/Popups \
	&& cd $MW_HOME/extensions/Popups \
	&& git checkout -q ff4d2156e1f7f4c11f7396cb0cd70d387abd8187 \
	# RegularTooltips
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RegularTooltips $MW_HOME/extensions/RegularTooltips \
	&& cd $MW_HOME/extensions/RegularTooltips \
	&& git checkout -q 1af807bb6d5cfbd1e471e38bf70d6a392fb7eda2 \
	# RevisionSlider
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RevisionSlider $MW_HOME/extensions/RevisionSlider \
	&& cd $MW_HOME/extensions/RevisionSlider \
	&& git checkout -q 3cae51a322a5ca0f359e83efcb5fac38e73e346e \
	# RottenLinks
	&& git clone --single-branch -b master https://github.com/miraheze/RottenLinks.git $MW_HOME/extensions/RottenLinks \
	&& cd $MW_HOME/extensions/RottenLinks \
	&& git checkout -q a96e99d0a61a42d59587a67db0720ce245a7ee46 \
	# SandboxLink
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SandboxLink $MW_HOME/extensions/SandboxLink \
	&& cd $MW_HOME/extensions/SandboxLink \
	&& git checkout -q 9ab23288a010c3894c59cd5ba3096d93d57c15c5 \
	# SaveSpinner
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SaveSpinner $MW_HOME/extensions/SaveSpinner \
	&& cd $MW_HOME/extensions/SaveSpinner \
	&& git checkout -q 1e819e2fff7fad6999bafe71d866c3af50836c42 \
	# SemanticDrilldown
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SemanticDrilldown $MW_HOME/extensions/SemanticDrilldown \
	&& cd $MW_HOME/extensions/SemanticDrilldown \
	&& git checkout -q e960979ec5a3b1e662b3742cee7e7ef4056f9a46 \
	# SimpleChanges
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SimpleChanges $MW_HOME/extensions/SimpleChanges \
	&& cd $MW_HOME/extensions/SimpleChanges \
	&& git checkout -q 5352de89dfaf043f646a44582b26f07822f02be7 \
	# SimpleMathJax
	&& git clone --single-branch https://github.com/jmnote/SimpleMathJax.git $MW_HOME/extensions/SimpleMathJax \
	&& cd $MW_HOME/extensions/SimpleMathJax \
	&& git checkout -q 3757e9b1cf235b2e2c62e7d208d52206e185b28e \
	# SkinPerPage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerPage $MW_HOME/extensions/SkinPerPage \
	&& cd $MW_HOME/extensions/SkinPerPage \
	&& git checkout -q 2793602b37c33aa4c769834feac0b88f385ccef9 \
	# SmiteSpam
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SmiteSpam $MW_HOME/extensions/SmiteSpam \
	&& cd $MW_HOME/extensions/SmiteSpam \
	&& git checkout -q 268f212b7e366711d8e7b54c7faf5b750fa014ad \
	# SocialProfile
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SocialProfile $MW_HOME/extensions/SocialProfile \
	&& cd $MW_HOME/extensions/SocialProfile \
	&& git checkout -q 74fcf9bead948ec0419eea10800c9331bcc1273e \
	# TemplateStyles
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles $MW_HOME/extensions/TemplateStyles \
	&& cd $MW_HOME/extensions/TemplateStyles \
	&& git checkout -q 2a93b56e370ab8b8e020ed29c507104b56f1d11a \
	# Thanks
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Thanks $MW_HOME/extensions/Thanks \
	&& cd $MW_HOME/extensions/Thanks \
	&& git checkout -q 03b6a52f263604c819e69b78c157f6ef5adb053e \
	# TimedMediaHandler
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TimedMediaHandler $MW_HOME/extensions/TimedMediaHandler \
	&& cd $MW_HOME/extensions/TimedMediaHandler \
	&& git checkout -q 2e64302c68e58693650e91b7869fa5aecf1aaf23 \
	# TinyMCE
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TinyMCE $MW_HOME/extensions/TinyMCE \
	&& cd $MW_HOME/extensions/TinyMCE \
	&& git checkout -q 06436ec3a53c6cd53c458e4e8ab3ec8d1a23029b \
	# UniversalLanguageSelector
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UniversalLanguageSelector $MW_HOME/extensions/UniversalLanguageSelector \
	&& cd $MW_HOME/extensions/UniversalLanguageSelector \
	&& git checkout -q 8216e434c38ddeba74e5ad758bfbbcc83861fa60 \
	# UploadWizard
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UploadWizard $MW_HOME/extensions/UploadWizard \
	&& cd $MW_HOME/extensions/UploadWizard \
	&& git checkout -q 847413694b519c76da7196023651c8d584137d2f \
	# UrlGetParameters
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UrlGetParameters $MW_HOME/extensions/UrlGetParameters \
	&& cd $MW_HOME/extensions/UrlGetParameters \
	&& git checkout -q d36f92810c762b301035ff1b4f42792ed9a1018b \
	# UserFunctions
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserFunctions $MW_HOME/extensions/UserFunctions \
	&& cd $MW_HOME/extensions/UserFunctions \
	&& git checkout -q b532b1047080c3738327ee2f3b541e563e06ca19 \
	# UserMerge
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge $MW_HOME/extensions/UserMerge \
	&& cd $MW_HOME/extensions/UserMerge \
	&& git checkout -q 183bb7a8f78cbe365bec0fbd4b3ecdd4fae1a359 \
	# UserPageViewTracker (v. 0.7)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/UserPageViewTracker $MW_HOME/extensions/UserPageViewTracker \
	&& cd $MW_HOME/extensions/UserPageViewTracker \
	&& git checkout -q f4b7c20c372165541164d449c12df1e74e98ed0b \
	# Variables
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Variables $MW_HOME/extensions/Variables \
	&& cd $MW_HOME/extensions/Variables \
	&& git checkout -q b4a9063f16a928567e3b6788cda9246c2e94797f \
	# VEForAll (v. 0.4.1)
	&& git clone --single-branch -b master https://gerrit.wikimedia.org/r/mediawiki/extensions/VEForAll $MW_HOME/extensions/VEForAll \
	&& cd $MW_HOME/extensions/VEForAll \
	&& git checkout -q 2f1f08eca7fbf61198e5f4ccf2d627a6c9ef7b64 \
	# VoteNY
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY $MW_HOME/extensions/VoteNY \
	&& cd $MW_HOME/extensions/VoteNY \
	&& git checkout -q 11c103f4b9167a8d8d5e850d8a781c6f49b249c1 \
	# WhoIsWatching
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WhoIsWatching $MW_HOME/extensions/WhoIsWatching \
	&& cd $MW_HOME/extensions/WhoIsWatching \
	&& git checkout -q 836a31018e26ab7c993088c4cca31a89efec2ee5 \
	# Widgets
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets $MW_HOME/extensions/Widgets \
	&& cd $MW_HOME/extensions/Widgets \
	&& git checkout -q 583c4f5e1829d2f78fb4a6e1f22bc9de4cf4d3a8 \
	# WikiForum
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiForum $MW_HOME/extensions/WikiForum \
	&& cd $MW_HOME/extensions/WikiForum \
	&& git checkout -q a2685b60af86890f199a5f3b6581918369e6a571 \
	# WikiSEO
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiSEO $MW_HOME/extensions/WikiSEO \
	&& cd $MW_HOME/extensions/WikiSEO \
	&& git checkout -q 610cffa3345333b53d4dda7b55b2012fbfcee9de \
	# WSOAuth
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WSOAuth $MW_HOME/extensions/WSOAuth \
	&& cd $MW_HOME/extensions/WSOAuth \
	&& git checkout -q 3c54c4899dd63989bc3214273bf1c5807c7ac5db

# WikiTeq extensions \
RUN set -x; \
	cd $MW_HOME/extensions \
	# Buggy
	&& git clone --single-branch -b $MW_VERSION https://github.com/wikimedia/mediawiki-extensions-Buggy.git $MW_HOME/extensions/Buggy \
	&& cd $MW_HOME/extensions/Buggy \
    && git checkout -q 768d2ec62de692ab62fc0c9f1820e22058d09d4b \
	# ChangeAuthor
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ChangeAuthor $MW_HOME/extensions/ChangeAuthor \
	&& cd $MW_HOME/extensions/ChangeAuthor \
	&& git checkout -q c297a88407c6dea60dfa03b1a7d5f4cd78d9e0c9 \
	# Citoid
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Citoid $MW_HOME/extensions/Citoid \
	&& cd $MW_HOME/extensions/Citoid \
	&& git checkout -q 1e605c7d89368c334cbe83b4da8e1b6d72ae9c33 \
	# DebugMode, see https://www.mediawiki.org/wiki/Extension:DebugMode
	&& git clone --single-branch -b $MW_VERSION https://github.com/wikimedia/mediawiki-extensions-DebugMode.git $MW_HOME/extensions/DebugMode \
	&& cd $MW_HOME/extensions/DebugMode \
	&& git checkout -q 5e2dc96feeb441c9bd6199321e52073128a629c7 \
	# EncryptedUploads
	&& cd $MW_HOME/extensions \
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EncryptedUploads \
	&& cd EncryptedUploads \
	&& git checkout -q bbb538554c3b4358703c726b7b48ca9da8a64113 \
	# Favorites
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Favorites $MW_HOME/extensions/Favorites \
	&& cd $MW_HOME/extensions/Favorites \
	&& git checkout -q d7f27b7e758e162e8d21ca2ba40b3027df4dc5f3 \
	# FixedHeaderTable
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/FixedHeaderTable $MW_HOME/extensions/FixedHeaderTable \
	&& cd $MW_HOME/extensions/FixedHeaderTable \
	&& git checkout -q ea04739f12f53d2825f6716034a428a7d55c9c1a \
	# Flow
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Flow $MW_HOME/extensions/Flow \
	&& cd $MW_HOME/extensions/Flow \
	&& git checkout -q fc6af96ab80e9c4da4b4cb8dde313f1d718f71b5 \
	# googleAnalytics
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/googleAnalytics $MW_HOME/extensions/googleAnalytics \
	&& cd $MW_HOME/extensions/googleAnalytics \
	&& git checkout -q 03aca3b940f32b9c22a2032c3b430982683bf9d0 \
	# GoogleDocTag
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocTag $MW_HOME/extensions/GoogleDocTag \
	&& cd $MW_HOME/extensions/GoogleDocTag \
	&& git checkout -q b71c875b033f79e17a54e6fccd2bfde26bff9163 \
    # GTag
    && git clone https://github.com/SkizNet/mediawiki-GTag.git $MW_HOME/extensions/GTag \
    && cd $MW_HOME/extensions/GTag \
    && git checkout -q 5b3ac10946e8242da5d63d981875e4dad3e14f9d \
	# HeadScript
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeadScript $MW_HOME/extensions/HeadScript \
	&& cd $MW_HOME/extensions/HeadScript \
	&& git checkout -q 168f588f5f7895b1ebe99a14e4eeb97bb03c8b6b \
	# IframePage
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/IframePage $MW_HOME/extensions/IframePage \
	&& cd $MW_HOME/extensions/IframePage \
	&& git checkout -q 8010e02bab480ccecf2db828c187d90ed027c563 \
	# Lazyload
	# TODO change me when https://github.com/mudkipme/mediawiki-lazyload/pull/15 will be merged
	&& git clone https://github.com/mudkipme/mediawiki-lazyload.git $MW_HOME/extensions/Lazyload \
	&& cd $MW_HOME/extensions/Lazyload \
	&& git checkout -b $MW_VERSION 30a01cc149822353c9404ec178ec01848bae65c5 \
	# LiquidThreads
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LiquidThreads $MW_HOME/extensions/LiquidThreads \
	&& cd $MW_HOME/extensions/LiquidThreads \
	&& git checkout -q 00d4cfb74c18e6524dc2c16347229fffef7043f7 \
	# MassPasswordReset
	&& cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/MassPasswordReset.git \
	&& cd MassPasswordReset \
	&& git checkout -b $MW_VERSION 04b7e765db994d41f5ca3a910e18f77105218d94 \
	# Math
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Math $MW_HOME/extensions/Math \
	&& cd $MW_HOME/extensions/Math \
	&& git checkout -q 106bb1ea4d5fc43e09f59311bdd28b26fef83711 \
	# Mendeley
	&& git clone https://github.com/nischayn22/Mendeley.git $MW_HOME/extensions/Mendeley \
	&& cd $MW_HOME/extensions/Mendeley \
	&& git checkout -b $MW_VERSION b866c3608ada025ce8a3e161e4605cd9106056c4 \
	# MobileDetect
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileDetect $MW_HOME/extensions/MobileDetect \
	&& cd $MW_HOME/extensions/MobileDetect \
	&& git checkout -q ccb0bdd7fa77d33adcfd2401c69e771c942df639 \
	# Mpdf
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Mpdf.git $MW_HOME/extensions/Mpdf \
	&& cd $MW_HOME/extensions/Mpdf \
	&& git checkout -q 1c1a5a4b0caba3164d765c7e893610dccbe33c96 \
	# NCBITaxonomyLookup
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/NCBITaxonomyLookup $MW_HOME/extensions/NCBITaxonomyLookup \
	&& cd $MW_HOME/extensions/NCBITaxonomyLookup \
	&& git checkout -q 46a8571234c62b8d86c7e33934b8f7ec0b6f6a5d \
	# PageSchemas
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/PageSchemas $MW_HOME/extensions/PageSchemas \
	&& cd $MW_HOME/extensions/PageSchemas \
	&& git checkout -q a8d117c111f08869f542b6a6b15ba7ca4e93d8b5 \
	# PDFEmbed
	&& git clone https://github.com/WolfgangFahl/PDFEmbed.git $MW_HOME/extensions/PDFEmbed \
	&& cd $MW_HOME/extensions/PDFEmbed \
	&& git checkout -q 2b07a1c18cef4794f4cb2429baa2d55fdb2beed3 \
	# PubmedParser
	&& cd $MW_HOME/extensions \
	&& git clone https://github.com/WikiTeq/PubmedParser.git \
	&& cd PubmedParser \
	&& git checkout -b $MW_VERSION f2b04c7094aedfefb6096e88117ae1a947a2acd2 \
	# RandomInCategory
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/RandomInCategory $MW_HOME/extensions/RandomInCategory \
	&& cd $MW_HOME/extensions/RandomInCategory \
	&& git checkout -q ea4c8ad59df4732be25c1cd51ef2fe56c3e58d18 \
	# Scopus
	&& git clone https://github.com/nischayn22/Scopus.git $MW_HOME/extensions/Scopus \
	&& cd $MW_HOME/extensions/Scopus \
	&& git checkout -b $MW_VERSION 4fe8048459d9189626d82d9d93a0d5f906c43746 \
	# SelectCategory
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SelectCategory $MW_HOME/extensions/SelectCategory \
	&& cd $MW_HOME/extensions/SelectCategory \
	&& git checkout -q 072f7a5df0346f4f4fccaf54510641e0a0ce2922 \
	# SemanticExternalQueryLookup (WikiTeq's fork)
	&& git clone https://github.com/WikiTeq/SemanticExternalQueryLookup.git $MW_HOME/extensions/SemanticExternalQueryLookup \
	&& cd $MW_HOME/extensions/SemanticExternalQueryLookup \
	&& git checkout -b $MW_VERSION dd7810061f2f1a9eef7be5ee09da999cbf9ecd8a \
	# SemanticQueryInterface
	&& git clone https://github.com/vedmaka/SemanticQueryInterface.git $MW_HOME/extensions/SemanticQueryInterface \
	&& cd $MW_HOME/extensions/SemanticQueryInterface \
	&& git checkout -b $MW_VERSION 0016305a95ecbb6ed4709bfa3fc6d9995d51336f \
	&& mv SemanticQueryInterface/* . \
	&& rmdir SemanticQueryInterface \
	&& ln -s SQI.php SemanticQueryInterface.php \
	&& rm -fr .git \
	# Sentry
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Sentry $MW_HOME/extensions/Sentry \
	&& cd $MW_HOME/extensions/Sentry \
	&& git checkout -q 92c1ccc21c7bf45d723c604b52efdb2464057844 \
	# ShowMe
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ShowMe $MW_HOME/extensions/ShowMe \
	&& cd $MW_HOME/extensions/ShowMe \
	&& git checkout -q 4190783befb0d440bb61149728cd7399a862c0fc \
	# SimpleTooltip
	&& git clone https://github.com/Universal-Omega/SimpleTooltip.git $MW_HOME/extensions/SimpleTooltip \
	&& cd $MW_HOME/extensions/SimpleTooltip \
	&& git checkout -b $MW_VERSION a918f4a6f095e9d8cc9fde0efad7acef472d2e94 \
	# Skinny
	&& git clone https://github.com/tinymighty/skinny.git Skinny $MW_HOME/extensions/Skinny \
	&& cd $MW_HOME/extensions/Skinny \
	&& git checkout -b $MW_VERSION 512e07818556e9b9baa07154371dab3201bfb435 \
	# SkinPerNamespace
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerNamespace $MW_HOME/extensions/SkinPerNamespace \
	&& cd $MW_HOME/extensions/SkinPerNamespace \
	&& git checkout -q 14762eadecd791904886aa15fa5a2f845dc005f0 \
	# SoundManager2Button
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SoundManager2Button $MW_HOME/extensions/SoundManager2Button \
	&& cd $MW_HOME/extensions/SoundManager2Button \
	&& git checkout -q 89b477d952cad892792263f3097077111d1b7844 \
	# SRFEventCalendarMod
	&& git clone https://github.com/vedmaka/mediawiki-extension-SRFEventCalendarMod.git $MW_HOME/extensions/SRFEventCalendarMod \
	&& cd $MW_HOME/extensions/SRFEventCalendarMod \
	&& git checkout -b $MW_VERSION e0dfa797af0709c90f9c9295d217bbb6d564a7a8 \
	# Survey
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Survey $MW_HOME/extensions/Survey \
	&& cd $MW_HOME/extensions/Survey \
	&& git checkout -q a723508305d618623615f324f90755c4a8b74bbf \
	# Sync
	&& git clone https://github.com/nischayn22/Sync.git $MW_HOME/extensions/Sync \
	&& cd $MW_HOME/extensions/Sync \
	&& git checkout -b $MW_VERSION f56b956521f383221737261ad68aef2367466b76 \
	# Tabber
	&& git clone https://gitlab.com/hydrawiki/extensions/Tabber.git $MW_HOME/extensions/Tabber \
	&& cd $MW_HOME/extensions/Tabber \
	&& git checkout -b $MW_VERSION 6c67baf4d18518fa78e07add4c032d62dd384b06 \
	# TabberNeue
	&& git clone https://github.com/StarCitizenTools/mediawiki-extensions-TabberNeue.git $MW_HOME/extensions/TabberNeue \
	&& cd $MW_HOME/extensions/TabberNeue \
	&& git checkout -b $MW_VERSION 7f04013085a2d80304849b978fc94bb472bf0b36 \
	# Tabs
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Tabs $MW_HOME/extensions/Tabs \
	&& cd $MW_HOME/extensions/Tabs \
	&& git checkout -q f2187a37d14d67543380576366f1f07a26078ddd \
	# TwitterTag
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TwitterTag $MW_HOME/extensions/TwitterTag \
	&& cd $MW_HOME/extensions/TwitterTag \
	&& git checkout -q 0f22e65539d0e96a71c1e4694614d7c14860f524 \
	# UploadWizardExtraButtons
	&& git clone https://github.com/vedmaka/mediawiki-extension-UploadWizardExtraButtons.git $MW_HOME/extensions/UploadWizardExtraButtons \
	&& cd $MW_HOME/extensions/UploadWizardExtraButtons \
	&& git checkout -b $MW_VERSION accba1b9b6f50e67d709bd727c9f4ad6de78c0c0 \
	# Wiretap
	&& git clone https://github.com/enterprisemediawiki/Wiretap.git $MW_HOME/extensions/Wiretap \
	&& cd $MW_HOME/extensions/Wiretap \
	&& git checkout -q a97b708c3093ea66e7cf625859b1b38178526bab \
	# YouTube
	&& git clone --single-branch -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/YouTube $MW_HOME/extensions/YouTube \
	&& cd $MW_HOME/extensions/YouTube \
	&& git checkout -q 7ed328ab60779938eb1557d54d7d8454012df08c

## GoogleAnalyticsMetrics: Resolve composer conflicts, so placed before the composer install statement!
#COPY _sources/patches/core-fix-composer-for-GoogleAnalyticsMetrics.diff /tmp/core-fix-composer-for-GoogleAnalyticsMetrics.diff
#RUN set -x; \
#	cd $MW_HOME \
#	&& git apply /tmp/core-fix-composer-for-GoogleAnalyticsMetrics.diff

# Patch composer
RUN set -x; \
    sed -i 's="monolog/monolog": "2.2.0",="monolog/monolog": "^2.2",=g' $MW_HOME/composer.json

# WikiTeq AL-12
COPY _sources/patches/FlexDiagrams.0.4.fix.diff /tmp/FlexDiagrams.0.4.fix.diff
RUN set -x; \
    cd $MW_HOME/extensions/FlexDiagrams \
    && git apply /tmp/FlexDiagrams.0.4.fix.diff

## Fix composer dependencies for MassPasswordReset extension
## TODO: remove when PR merged https://github.com/nischayn22/MassPasswordReset/pull/1
#COPY _sources/patches/MassPasswordReset.patch /tmp/MassPasswordReset.patch
#RUN set -x; \
#	cd $MW_HOME/extensions/MassPasswordReset \
#	&& git apply /tmp/MassPasswordReset.patch

# WikiTeq WLDR-242
COPY _sources/patches/PageForms.Adds_semantic_query_param.fb9511c.diff /tmp/PageForms.Adds_semantic_query_param.fb9511c.diff
RUN set -x; \
    cd $MW_HOME/extensions/PageForms \
    && git apply /tmp/PageForms.Adds_semantic_query_param.fb9511c.diff

# Composer dependencies
COPY _sources/configs/composer.canasta.json $MW_HOME/composer.local.json
RUN set -x; \
	cd $MW_HOME \
	&& cp composer.json composer.json.bak \
	&& cat composer.json.bak | jq '. + {"minimum-stability": "dev"}' > composer.json \
	&& rm composer.json.bak \
	&& cp composer.json composer.json.bak \
	&& cat composer.json.bak | jq '. + {"prefer-stable": true}' > composer.json \
	&& rm composer.json.bak \
	&& composer clear-cache \
	# configure auth
	&& [ "$COMPOSER_TOKEN" != "" ] && composer config -g github-oauth.github.com $COMPOSER_TOKEN \
	&& composer update --no-dev --with-dependencies \
	&& composer clear-cache

################# Patches #################

# WLDR-92, WLDR-125, probably need to be removed if there will be a similar
# change of UserGroupManager on future wiki releases
COPY _sources/patches/ugm.patch /tmp/ugm.patch
RUN set -x; \
	cd $MW_HOME \
	&& git apply /tmp/ugm.patch

## Parsoid assertValidUTF8 back-port from 0.13.1
#COPY _sources/patches/parsoid.0.12.1.diff /tmp/parsoid.0.12.1.diff
#RUN set -x; \
#	cd $MW_HOME/vendor/wikimedia/parsoid/src/Utils/ \
#	&& patch --verbose --ignore-whitespace --fuzz 3 PHPUtils.php /tmp/parsoid.0.12.1.diff

# Add Bootstrap to LocalSettings.php if the web installer added the Chameleon skin
COPY _sources/patches/core-local-settings-generator.patch /tmp/core-local-settings-generator.patch
RUN set -x; \
	cd $MW_HOME \
	&& git apply /tmp/core-local-settings-generator.patch

# TODO send to upstream, see https://wikiteq.atlassian.net/browse/MW-64 and https://wikiteq.atlassian.net/browse/MW-81
#COPY _sources/patches/skin-refreshed.patch /tmp/skin-refreshed.patch
#RUN set -x; \
#	cd $MW_HOME/skins/Refreshed \
#	&& patch -u -b includes/RefreshedTemplate.php -i /tmp/skin-refreshed.patch

# WikiTeq's patch allowing to manage fields visibility site-wide
#COPY _sources/patches/SocialProfile-disable-fields.patch /tmp/SocialProfile-disable-fields.patch
#RUN set -x; \
#    cd $MW_HOME/extensions/SocialProfile \
#    && git apply /tmp/SocialProfile-disable-fields.patch

#COPY _sources/patches/bootstrap-path.patch /tmp/bootstrap-path.patch
#RUN set -x; \
#    cd $MW_HOME/extensions/Bootstrap \
#    && patch -p1 < /tmp/bootstrap-path.patch

#COPY _sources/patches/chameleon-path.patch /tmp/chameleon-path.patch
#RUN set -x; \
#    cd $MW_HOME/skins/chameleon \
#    && git apply /tmp/chameleon-path.patch

# SemanticResultFormats, see https://github.com/WikiTeq/SemanticResultFormats/compare/master...WikiTeq:fix1_35
COPY _sources/patches/semantic-result-formats.patch /tmp/semantic-result-formats.patch
RUN set -x; \
	cd $MW_HOME/extensions/SemanticResultFormats \
	&& patch < /tmp/semantic-result-formats.patch

# Fixes PHP parsoid errors when user replies on a flow message, see https://phabricator.wikimedia.org/T260648#6645078
COPY _sources/patches/flow-conversion-utils.patch /tmp/flow-conversion-utils.patch
RUN set -x; \
	cd $MW_HOME/extensions/Flow \
	&& git checkout d37f94241d8cb94ac96c7946f83c1038844cf7e6 \
	&& git apply /tmp/flow-conversion-utils.patch

# SWM maintenance page returns 503 (Service Unavailable) status code, PR: https://github.com/SemanticMediaWiki/SemanticMediaWiki/pull/4967
#COPY _sources/patches/smw-maintenance-503.patch /tmp/smw-maintenance-503.patch
#RUN set -x; \
#	cd $MW_HOME/extensions/SemanticMediaWiki \
#	&& patch -u -b src/SetupCheck.php -i /tmp/smw-maintenance-503.patch

# TODO send to upstream, see https://wikiteq.atlassian.net/browse/MW-64 and https://wikiteq.atlassian.net/browse/MW-81
COPY _sources/patches/skin-refreshed.patch /tmp/skin-refreshed.patch
COPY _sources/patches/skin-refreshed-737080.diff /tmp/skin-refreshed-737080.diff
RUN set -x; \
	cd $MW_HOME/skins/Refreshed \
	&& patch -u -b includes/RefreshedTemplate.php -i /tmp/skin-refreshed.patch \
	# TODO remove me when https://gerrit.wikimedia.org/r/c/mediawiki/skins/Refreshed/+/737080 merged
	# Fix PHP Warning in RefreshedTemplate::makeElementWithIconHelper()
	&& git apply /tmp/skin-refreshed-737080.diff

# TODO: remove for 1.36+, see https://phabricator.wikimedia.org/T281043
COPY _sources/patches/social-profile-REL1_35.44b4f89.diff /tmp/social-profile-REL1_35.44b4f89.diff
RUN set -x; \
	cd $MW_HOME/extensions/SocialProfile \
	&& git apply /tmp/social-profile-REL1_35.44b4f89.diff

# WikiTeq's patch allowing to manage fields visibility site-wide
COPY _sources/patches/SocialProfile-disable-fields.patch /tmp/SocialProfile-disable-fields.patch
RUN set -x; \
	cd $MW_HOME/extensions/SocialProfile \
	&& git apply /tmp/SocialProfile-disable-fields.patch

#COPY _sources/patches/CommentStreams.REL1_35.core.hook.37a9e60.diff /tmp/CommentStreams.REL1_35.core.hook.37a9e60.diff
## TODO: the Hooks is added in REL1_38, remove the patch once the core is updated to 1.38
#RUN set -x; \
#	cd $MW_HOME \
#	&& git apply /tmp/CommentStreams.REL1_35.core.hook.37a9e60.diff

COPY _sources/patches/DisplayTitleHooks.fragment.master.patch /tmp/DisplayTitleHooks.fragment.master.patch
RUN set -x; \
	cd $MW_HOME/extensions/DisplayTitle \
	&& git apply /tmp/DisplayTitleHooks.fragment.master.patch

COPY _sources/patches/Mendeley.notices.patch /tmp/Mendeley.notices.patch
RUN set -x; \
	cd $MW_HOME/extensions/Mendeley \
	&& git apply /tmp/Mendeley.notices.patch

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME \
	&& find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

# Generate list of installed extensions
RUN set -x; \
	cd $MW_HOME/extensions \
	&& for i in $(ls -d */); do echo "#cfLoadExtension('${i%%/}');"; done > $MW_ORIGIN_FILES/installedExtensions.txt \
	# Dirty hack for SemanticMediawiki
	&& sed -i "s/#cfLoadExtension('SemanticMediaWiki');/#enableSemantics('localhost');/g" $MW_ORIGIN_FILES/installedExtensions.txt \
	&& cd $MW_HOME/skins \
	&& for i in $(ls -d */); do echo "#cfLoadSkin('${i%%/}');"; done > $MW_ORIGIN_FILES/installedSkins.txt \
	#Loads Vector skin by default in the LocalSettings.php
	&& sed -i "s/#cfLoadSkin('Vector');/cfLoadSkin('Vector');/" $MW_ORIGIN_FILES/installedSkins.txt

# Move files around
RUN set -x; \
	# Move files to $MW_ORIGIN_FILES directory
	mv $MW_HOME/images $MW_ORIGIN_FILES/ \
	&& mv $MW_HOME/cache $MW_ORIGIN_FILES/ \
	# Create symlinks from $MW_VOLUME to the wiki root for images and cache directories
	&& ln -s $MW_VOLUME/images $MW_HOME/images \
	&& ln -s $MW_VOLUME/cache $MW_HOME/cache

FROM base as final

COPY --from=source $MW_HOME $MW_HOME
COPY --from=source $MW_ORIGIN_FILES $MW_ORIGIN_FILES

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
	MW_DB_USER=root \
	MW_CIRRUS_SEARCH_SERVERS=elasticsearch \
	MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG=1 \
	MW_MAINTENANCE_CIRRUSSEARCH_FORCEINDEX=1 \
	MW_ENABLE_JOB_RUNNER=true \
	MW_JOB_RUNNER_PAUSE=2 \
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
	MW_DEBUG_MODE=false \
	MW_SENTRY_DSN=""

COPY _sources/configs/msmtprc /etc/
COPY _sources/configs/mediawiki.conf /etc/apache2/sites-enabled/
COPY _sources/configs/status.conf /etc/apache2/mods-available/
COPY _sources/configs/scan.conf /etc/clamd.d/scan.conf
COPY _sources/configs/php_xdebug.ini _sources/configs/php_memory_limit.ini _sources/configs/php_error_reporting.ini _sources/configs/php_upload_max_filesize.ini /etc/php/7.4/cli/conf.d/
COPY _sources/configs/php_xdebug.ini _sources/configs/php_memory_limit.ini _sources/configs/php_error_reporting.ini _sources/configs/php_upload_max_filesize.ini /etc/php/7.4/apache2/conf.d/
COPY _sources/configs/php_max_input_vars.ini _sources/configs/php_max_input_vars.ini /etc/php/7.4/apache2/conf.d/
COPY _sources/configs/php_timeouts.ini /etc/php/7.4/apache2/conf.d/
COPY _sources/scripts/*.sh /
COPY _sources/scripts/*.php $MW_HOME/maintenance/
COPY _sources/configs/robots.txt $WWW_ROOT/
COPY _sources/configs/.htaccess $WWW_ROOT/
COPY _sources/images/favicon.ico $WWW_ROOT/
COPY _sources/canasta/DockerSettings.php $MW_HOME/
COPY _sources/canasta/getMediawikiSettings.php /
COPY _sources/configs/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN set -x; \
	chmod -v +x /*.sh \
	# Sitemap directory
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
