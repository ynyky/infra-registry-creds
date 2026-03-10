{{- define "http-server.fullname" -}}
{{ .Values.httpServer.name }}
{{- end }}

{{- define "http-server.labels" -}}
app: {{ .Values.httpServer.name }}
{{- end }}