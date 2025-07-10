RUN set -x; \
	mkdir $MW_HOME/extensions && \
	cd $MW_HOME/extensions

# Split extensions into groups of 10 for better layer caching
{{- $allExtensions := (ds "values").extensions -}}
{{- $extensions := coll.Slice -}}
{{- range $ext := $allExtensions -}}
  {{- range $name, $details := $ext -}}
    {{- if not (index $details "bundled") -}}
      {{- $extensions = $extensions | append $ext -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $groupSize := 10 -}}
{{- $total := len $extensions -}}
{{- $groupCount := div (add $total (sub $groupSize 1)) $groupSize -}}
{{- range $groupIndex := seq 0 (sub $groupCount 1) -}}
  {{- $start := mul $groupIndex $groupSize -}}
  {{- $end := add $start $groupSize -}}
  {{- if gt $end $total -}}
    {{- $end = $total -}}
  {{- end }}

# Extensions group {{ add $groupIndex 1 }} ({{ add $start 1 }}-{{ $end }})
RUN set -x; \
    cd $MW_HOME/extensions && \
    {{- range $relativeIndex := seq 0 (sub (sub $end $start) 1) -}}
      {{- $extIndex := add $start $relativeIndex -}}
      {{- $ext := index $extensions $extIndex -}}
      {{- range $name, $details := $ext }}
	# {{ $name }}
	git clone{{ if not (index $details "full_history") }} --single-branch{{ end }} -b {{ default "$MW_VERSION" (index $details "branch") }} \
	{{- if (index $details "repository") }}
	{{ index $details "repository" }}
	{{- else }}
	https://gerrit.wikimedia.org/r/mediawiki/extensions/{{- $name }}
	{{- end }} $MW_HOME/extensions/{{- $name }} && \
	cd $MW_HOME/extensions/{{- $name }} && \
	git checkout -q {{ $details.commit}}{{ if not (eq $extIndex (sub $end 1) ) }} && \{{ end }}
      {{- end -}}
    {{- end }}
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
