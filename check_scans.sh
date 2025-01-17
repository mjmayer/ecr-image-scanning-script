#!/bin/bash

function wait_for_scan() {
  echo "Giving some time for scan to begin..."
  sleep 3
  while [[ $(aws ecr describe-image-scan-findings --repository-name $REPONAME --image-id imageTag=$BUILDID | jq -r .imageScanStatus.status) != "COMPLETE" ]];do
    echo "SCAN IS NOT YET COMPLETE..."
    sleep 3
  done
}

function check_for_high_critical_vuln() {
  scan_results=$(aws ecr describe-image-scan-findings --repository-name $REPONAME --image-id imageTag=$BUILDID)
  high=$(echo $scan_results | jq .imageScanFindings.findingSeverityCounts.HIGH)
  critical=$(echo $scan_results | jq .imageScanFindings.findingSeverityCounts.CRITICAL)
}

function return_scan_results() {
    echo "=== BEGIN IMAGE SCAN RESULTS ==="
    echo "$scan_results"
    echo "=== END IMAGE SCAN RESULTS ==="
}

function return_error() {
    echo -e "\n**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    echo "ERROR: There are CRITICAL/HIGH vulnerabilties. Stopping build."
    echo "**********************************************************"
    echo "**********************************************************"
    echo "**********************************************************"
    exit 2
}

function analyze_scan_results() {
  if [[ $high -gt 0 ]] && $FAILBUILD; then
    return_scan_results
    return_error
  elif [[ $high -gt 0 ]] && $FAILBUILD; then
    echo "ERROR: There are HIGH vulnerabilties. Stopping build."
    return_scan_results
    return_error
  else
    return_scan_results
  fi
}

REPONAME="${1:?Need to set REPONAME(first param) non-empty}"
BUILDID="${2:?Need to set BUILDID(second param) non-empty}"
FAILBUILD="${3:-true}"
hash=$@

wait_for_scan $hash
check_for_high_critical_vuln $hash
analyze_scan_results $hash
