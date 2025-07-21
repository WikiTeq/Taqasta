# Copy core, skins and extensions
COPY --from=core $MW_HOME $MW_HOME
COPY --from=skins $MW_HOME/skins $MW_HOME/skins

# Copy from extensions stages
{{- $allExtensions := (ds "values").extensions -}}
{{- $extensions := coll.Slice -}}
{{- range $ext := $allExtensions -}}
  {{- range $name, $details := $ext -}}
    {{- if not (index $details "bundled") -}}
      {{- $extensions = $extensions | append $ext -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $groupSize := 30 -}}
{{- $total := len $extensions -}}
{{- $groupCount := div (add $total (sub $groupSize 1)) $groupSize -}}
{{- range $groupIndex := seq 0 (sub $groupCount 1) -}}
  {{- $start := mul $groupIndex $groupSize -}}
  {{- $end := add $start $groupSize -}}
  {{- if gt $end $total -}}
    {{- $end = $total -}}
  {{- end }}
# Extensions group {{ add $groupIndex 1 }} ({{ add $start 1 }}-{{ $end }})
COPY --from=extensions{{ add $start 1 }}-{{ $end }} $MW_HOME/extensions/ $MW_HOME/extensions/
{{- end }}

################# Patches #################

# WikiTeq AL-12
COPY _sources/patches/FlexDiagrams.0.4.fix.diff /tmp/FlexDiagrams.0.4.fix.diff
RUN set -x; \
	cd $MW_HOME/extensions/FlexDiagrams && \
	git apply /tmp/FlexDiagrams.0.4.fix.diff

# GoogleLogin gerrit patches 1070987 and 1074530 applied to REL1_43
COPY _sources/patches/GoogleLogin-fixes.patch /tmp/GoogleLogin-fixes.patch
RUN set -x; \
	cd $MW_HOME/extensions/GoogleLogin && \
	git apply /tmp/GoogleLogin-fixes.patch

# GoogleAnalyticsMetrics pins google/apiclient to 2.12.6, relax it
COPY _sources/patches/GoogleAnalyticsMetrics-relax-pin.patch /tmp/GoogleAnalyticsMetrics-relax-pin.patch
RUN set -x; \
	cd $MW_HOME/extensions/GoogleAnalyticsMetrics && \
	git apply /tmp/GoogleAnalyticsMetrics-relax-pin.patch

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/extensions && \
	find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

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
