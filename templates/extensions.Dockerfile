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
FROM base AS extensions{{ add $start 1 }}-{{ $end }}
RUN set -x; \
	mkdir $MW_HOME/extensions && \
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
