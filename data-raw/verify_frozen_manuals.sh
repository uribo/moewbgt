#!/bin/sh
# Verify the frozen copies of the Ministry of the Environment data service
# manuals that produced inst/extdata/wbgt_stations{2022,2023,2024}.csv.
#
# The upstream URLs (https://www.wbgt.env.go.jp/man15NH/R0{4,5,6}_...) answer
# 403 as of 2026-09-05 -- present on the server but no longer served -- so these
# bytes cannot be fetched again. They are kept in two places outside this
# repository (the PDFs themselves are not redistributed here); this script is
# what makes a silent loss or a half-synced cloud copy visible.
#
# Run it quarterly and at manuscript milestones, and record the result in
# PROVENANCE.md. A failure is always an anomaly: do not edit the digests below
# to make it pass.
#
# Override either location for a different machine:
#   MOEWBGT_FROZEN_CANONICAL=... MOEWBGT_FROZEN_OFFSITE=... sh data-raw/verify_frozen_manuals.sh

set -eu

CANONICAL="${MOEWBGT_FROZEN_CANONICAL:-$HOME/Documents/4_Archives/_frozen/moewbgt/manuals}"
OFFSITE="${MOEWBGT_FROZEN_OFFSITE:-$HOME/OneDrive - Tokushima University/4_Archives/_frozen/moewbgt/manuals}"

# file:sha256, recorded 2026-09-05 from the copies in japan-heatstroke/data-raw/
DIGESTS="R04_wbgt_data_service_manual.pdf:5b3fdb1c5d0c22fd12bfd7295cc6a42488fc3815fb2641cf4d422161e5f35b88
R05_wbgt_data_service_manual.pdf:19a10a82050e97d28e46b148cd7134355be48178fb91ad03d9e09edfa1ba9464
R06_wbgt_data_service_manual.pdf:47594bd4a26a3c88f9ab16663d1a6992df11fd3a1054c20ecff64ca184e035b8"

# Cloud storage that keeps files on demand leaves small placeholders behind, so
# a listing can look complete while nothing is readable. Check the size too.
MIN_BYTES=100000

status=0
for location in "$CANONICAL" "$OFFSITE"; do
  echo "== $location"
  if [ ! -d "$location" ]; then
    echo "   MISSING directory"
    status=1
    continue
  fi
  echo "$DIGESTS" | while IFS=: read -r name want; do
    path="$location/$name"
    if [ ! -f "$path" ]; then
      echo "   MISSING $name"
      exit 1
    fi
    size=$(wc -c <"$path" | tr -d ' ')
    if [ "$size" -lt "$MIN_BYTES" ]; then
      echo "   PLACEHOLDER $name ($size bytes -- not a materialised copy)"
      exit 1
    fi
    got=$(shasum -a 256 "$path" | cut -d' ' -f1)
    if [ "$got" = "$want" ]; then
      echo "   OK $name"
    else
      echo "   MISMATCH $name"
      echo "     recorded $want"
      echo "     found    $got"
      exit 1
    fi
  done || status=1
done

if [ "$status" -ne 0 ]; then
  echo "FAILED: a frozen manual is missing, unreadable, or changed."
  exit 1
fi
echo "All frozen manuals match in both locations."
