#!/bin/bash
SERVICE=${1:-checkout}
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
AGO=$(date -u -v-5M +%Y-%m-%dT%H:%M:%SZ)
curl -s "http://localhost:8080/jaeger/ui/api/v3/traces?query.service_name=$SERVICE&query.start_time_min=$AGO&query.start_time_max=$NOW&query.num_traces=5" \
| python3 -c '
import sys, json
trace_data = json.load(sys.stdin)
for resource_block in trace_data["result"]["resourceSpans"]:
    service_name = "unknown"
    for one_attribute in resource_block["resource"]["attributes"]:
        if one_attribute["key"] == "service.name":
            service_name = one_attribute["value"]["stringValue"]
    for scope_block in resource_block["scopeSpans"]:
        for one_span in scope_block["spans"]:
            span_status = one_span.get("status", {})
            if span_status.get("code") == 2:
                print(service_name, "|", one_span["name"], "|", span_status.get("message"))
'
