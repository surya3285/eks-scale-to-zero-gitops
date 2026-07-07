#!/usr/bin/env bash
# Pulls actual Cost Explorer data for a date range and renders it as a
# markdown table -- run once over a 24/7 baseline window (enable_scheduling
# = false) and once over a scheduled window (enable_scheduling = true), then
# diff the two tables for a real, not guessed, before/after number.
#
# Requires: aws cli (configured), jq
#
# Usage:
#   ./scripts/generate-cost-report.sh --start 2026-07-01 --end 2026-07-04 \
#       --label baseline-24x7 [--tag-value dev] [--granularity DAILY|HOURLY]
#
# Notes:
#   - Cost Explorer only serves HOURLY granularity for the trailing 14 days
#     and the requested range must fall within that window.
#   - --tag-value filters to Environment=<value> using the same tag Terraform
#     applies to every resource; omit it for whole-account totals.
#   - This calls the live Cost Explorer API (small per-request cost); the
#     CUR/Data Export in terraform/modules/cost-visibility is the durable,
#     free-to-query (once in S3/Athena) source of truth for anything beyond
#     quick before/after checks.

set -euo pipefail

GRANULARITY="DAILY"
TAG_VALUE=""
LABEL=""
START=""
END=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start) START="$2"; shift 2 ;;
    --end) END="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --tag-value) TAG_VALUE="$2"; shift 2 ;;
    --granularity) GRANULARITY="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$START" || -z "$END" || -z "$LABEL" ]]; then
  echo "Usage: $0 --start YYYY-MM-DD --end YYYY-MM-DD --label NAME [--tag-value dev] [--granularity DAILY|HOURLY]" >&2
  exit 1
fi

for bin in aws jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Missing required tool: $bin" >&2; exit 1; }
done

FILTER_ARGS=()
if [[ -n "$TAG_VALUE" ]]; then
  FILTER_ARGS=(--filter "$(jq -n --arg v "$TAG_VALUE" '{Tags:{Key:"Environment",Values:[$v]}}')")
fi

RESULT=$(aws ce get-cost-and-usage \
  --time-period "Start=${START},End=${END}" \
  --granularity "$GRANULARITY" \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  "${FILTER_ARGS[@]}")

OUT_DIR="docs/cost-data"
mkdir -p "$OUT_DIR"
OUT_FILE="${OUT_DIR}/${LABEL}.md"

{
  echo "## ${LABEL}"
  echo
  echo "Range: ${START} to ${END} (${GRANULARITY})$( [[ -n "$TAG_VALUE" ]] && echo ", Environment=${TAG_VALUE}" )"
  echo
  echo "| Period | Service | Cost (USD) |"
  echo "|---|---|---|"

  echo "$RESULT" | jq -r '
    .ResultsByTime[] as $period |
    $period.Groups[] |
    select((.Metrics.UnblendedCost.Amount | tonumber) > 0.0001) |
    [$period.TimePeriod.Start, .Keys[0], (.Metrics.UnblendedCost.Amount | tonumber | (.*100|round)/100 | tostring)] |
    "| \(.[0]) | \(.[1]) | \(.[2]) |"
  '

  TOTAL=$(echo "$RESULT" | jq -r '[.ResultsByTime[].Groups[].Metrics.UnblendedCost.Amount | tonumber] | add')
  printf '\n**Total: $%.2f**\n' "$TOTAL"
} | tee "$OUT_FILE"

echo
echo "Written to ${OUT_FILE}"
