RUN set -x; \
	mkdir $MW_HOME/extensions \
	&& cd $MW_HOME/extensions

# https://github.com/docker/docs/issues/8230#issuecomment-475278273
# We don't want to hit layers limits so have to be a single run
# The code below generates a RUN command with a list of extensions from values.yml file
RUN set -x; \
{{- $total := len (ds "values").extensions -}}
{{- range $index, $ext := (ds "values").extensions -}}
{{- /* $ext is a map with a single key = extension name */ -}}
{{ range $name, $details := $ext }}
	# {{ $name }}
    git clone --single-branch -b {{ default "$MW_VERSION" (index $details "branch") }} \
	{{- if (index $details "repository") }}
	{{ index $details "repository" }}
	{{- else }}
	https://gerrit.wikimedia.org/r/mediawiki/extensions/{{- $name }}
	{{- end }} $MW_HOME/extensions/{{- $name }} \
	&& cd $MW_HOME/extensions/{{- $name }} \
	&& git checkout -q {{ $details.commit}} {{ if not (eq $index (sub $total 1) ) }}\{{ end }}
{{- end -}}
{{- end }}

# Cleanup all .git leftovers
RUN set -x; \
	cd $MW_HOME/extensions \
	&& find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +
