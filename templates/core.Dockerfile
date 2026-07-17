# MediaWiki core
RUN set -x; \
	git clone --depth 1 -b $MW_CORE_VERSION https://github.com/wikimedia/mediawiki.git $MW_HOME && \
	cd $MW_HOME && \
	git submodule update --init --recursive

# Add Bootstrap to LocalSettings.php if the web installer added the Chameleon skin
COPY _sources/patches/core-local-settings-generator.patch /tmp/core-local-settings-generator.patch
RUN set -x; \
	cd $MW_HOME && \
	git apply /tmp/core-local-settings-generator.patch

# Make Rest\RequestFromGlobals::getUri() compatible with guzzlehttp/psr7 >= 2.12.3
# strict authority validation (GHSA-c2w2-prh8-qm98), which otherwise breaks the
# core PHPUnit default suite (RequestFromGlobalsTest::testGetUri2) [WIK-2532]
COPY _sources/patches/core-rest-request-uri-psr7.patch /tmp/core-rest-request-uri-psr7.patch
RUN set -x; \
	cd $MW_HOME && \
	git apply /tmp/core-rest-request-uri-psr7.patch

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME && \
	find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +
