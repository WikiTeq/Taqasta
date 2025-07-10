# Skins
# The Chameleon skin is downloaded via Composer and does not need to be installed.
RUN set -x; \
	mkdir $MW_HOME/skins && \
	cd $MW_HOME/skins

# https://github.com/docker/docs/issues/8230#issuecomment-475278273
# We don't want to hit layers limits so have to be a single run
# The code below generates a RUN command with a list of skins from values.yml file
RUN set -x; \
{{- $total := len (ds "values").skins -}}
{{- range $index, $ext := (ds "values").skins -}}
{{- /* $ext is a map with a single key = skin name */ -}}
{{ range $name, $details := $ext }}
	# {{ $name }}
    git clone --single-branch -b {{ default "$MW_VERSION" (index $details "branch") }} \
	{{- if (index $details "repository") }}
	{{ index $details "repository" }}
	{{- else }}
	https://gerrit.wikimedia.org/r/mediawiki/skins/{{- $name }}
	{{- end }} $MW_HOME/skins/{{- $name }} && \
	cd $MW_HOME/skins/{{- $name }} && \
	git checkout -q {{ $details.commit}}{{ if not (eq $index (sub $total 1) ) }} && \{{ end }}
{{- end -}}
{{- end }}

# TODO send to upstream, see https://wikiteq.atlassian.net/browse/MW-64 and https://wikiteq.atlassian.net/browse/MW-81
COPY _sources/patches/skin-refreshed.patch /tmp/skin-refreshed.patch
COPY _sources/patches/skin-refreshed-737080.diff /tmp/skin-refreshed-737080.diff
RUN set -x; \
	cd $MW_HOME/skins/Refreshed && \
	patch -u -b includes/RefreshedTemplate.php -i /tmp/skin-refreshed.patch && \
	# TODO remove me when https://gerrit.wikimedia.org/r/c/mediawiki/skins/Refreshed/+/737080 merged
	# Fix PHP Warning in RefreshedTemplate::makeElementWithIconHelper()
	git apply /tmp/skin-refreshed-737080.diff

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/skins && \
	find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +
