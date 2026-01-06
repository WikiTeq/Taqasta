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

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/extensions && \
	find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

# Composer dependencies
COPY _sources/configs/composer.wikiteq.json $MW_HOME/composer.local.json

# Temporary workaround to unblock upgrading composer in WIK-2245 - ignore
# the current security warnings from phpoffice/phpspreadsheet 1.29.*. Needs to
# be done directly in composer.json rather than composer.local.json since
# configuration isn't merged yet, see
# https://github.com/wikimedia/composer-merge-plugin/issues/229
RUN cd $MW_HOME && \
	cp composer.json composer.json.bak && \
	cat composer.json.bak | jq '. + {"config": ( .config + { "audit": { "ignore": ["PKSA-64jn-3d9t-gncx", "PKSA-8b16-mcgz-h4cz", "PKSA-s99r-9yxm-hjvt", "PKSA-7jd6-nb49-bz4v", "PKSA-nm34-xhtz-ww9p", "PKSA-4ckb-wpj6-c29d", "PKSA-ybqb-vyrq-8pdt", "PKSA-285y-y5bt-kvd9", "PKSA-jw5c-q9nd-tzj9", "PKSA-bcnb-9tc9-bjb8", "PKSA-gst3-cdk3-bpqt", "PKSA-dbrb-pvhs-h3st", "PKSA-mkg2-1wyw-57y7", "PKSA-p1pj-q951-6f1x", "PKSA-7f9v-sb8k-krfb", "PKSA-xk3k-rd1m-pxmg", "PKSA-dvbq-8ft2-ngrw", "PKSA-xp7t-fbrb-qjv4", "PKSA-m4hk-rk8p-4t5p"] } } ) }' > composer.json && \
	rm composer.json.bak

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
