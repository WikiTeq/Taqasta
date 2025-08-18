# MediaWiki core
RUN set -x; \
	git clone --depth 1 -b $MW_CORE_VERSION https://gerrit.wikimedia.org/r/mediawiki/core.git $MW_HOME && \
	cd $MW_HOME && \
	git submodule update --init --recursive

# Add Bootstrap to LocalSettings.php if the web installer added the Chameleon skin
COPY _sources/patches/core-local-settings-generator.patch /tmp/core-local-settings-generator.patch
RUN set -x; \
	cd $MW_HOME && \
	git apply /tmp/core-local-settings-generator.patch

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME && \
	find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +
