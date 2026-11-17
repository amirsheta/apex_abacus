#!/usr/bin/env bash
# =============================================================================
# convert_forms_to_xml.sh
# Convert every Oracle Forms 12c .fmb file in a directory to XML using frmf2xml.
#
# Part of the Oracle Forms 12c -> Oracle APEX 21.2 migration toolkit.
#
# Usage:
#   ./convert_forms_to_xml.sh <fmb_directory> [output_base_dir]
#
#   <fmb_directory>    Directory containing .fmb files (searched non-recursively)
#   [output_base_dir]  Optional. XML is written to <output_base_dir>/xml/
#                      Default: ./output  (i.e. ./output/xml/)
#
# Environment variables (optional):
#   FRMF2XML     Full path to the frmf2xml script. Default: auto-detect
#                (PATH, $ORACLE_HOME/bin/frmf2xml.sh, $DOMAIN_HOME Forms instance bin).
#   FRMF2XML_OPTS Extra options. Default: "OVERWRITE=YES DUMP_OVERRIDDEN_PROPERTIES=YES"
#   FORMS_PATH   Must include the directories of any .olb/.pll referenced by the
#                forms, otherwise subclassed objects cannot be resolved.
#
# Notes:
#   * Run on the Forms 12c middle-tier host (frmf2xml ships with Forms Builder).
#   * On headless Linux hosts frmf2xml may need a DISPLAY; if it fails with an
#     X11 error, run with: xvfb-run ./convert_forms_to_xml.sh ...
#   * frmf2xml writes <name>_fmb.xml into the CURRENT directory, so this script
#     runs it from inside the output folder.
#
# Exit codes: 0 = all converted, 1 = usage/environment error, 2 = some files failed
# =============================================================================

set -o nounset
set -o pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} <fmb_directory> [output_base_dir]

Converts every *.fmb in <fmb_directory> to XML with frmf2xml.
XML files go to <output_base_dir>/xml/ (default: ./output/xml/).
A log is written to <output_base_dir>/logs/convert_<timestamp>.log

Environment:
  FRMF2XML       path to frmf2xml (auto-detected if unset)
  FRMF2XML_OPTS  extra options (default: OVERWRITE=YES DUMP_OVERRIDDEN_PROPERTIES=YES)
  FORMS_PATH     directories containing referenced .olb/.pll files

Example:
  export FORMS_PATH=/u01/forms/src:/u01/forms/libs
  ${SCRIPT_NAME} /u01/forms/src ./output
EOF
}

log() {
    local level="$1"; shift
    local line
    line="$(date '+%Y-%m-%d %H:%M:%S') [${level}] $*"
    echo "${line}"
    [[ -n "${LOG_FILE:-}" ]] && echo "${line}" >> "${LOG_FILE}"
    return 0
}

find_frmf2xml() {
    if [[ -n "${FRMF2XML:-}" ]]; then
        [[ -x "${FRMF2XML}" ]] && { echo "${FRMF2XML}"; return 0; }
        return 1
    fi
    local candidate
    for candidate in frmf2xml.sh frmf2xml; do
        if command -v "${candidate}" >/dev/null 2>&1; then
            command -v "${candidate}"; return 0
        fi
    done
    local paths=()
    [[ -n "${ORACLE_HOME:-}" ]] && paths+=("${ORACLE_HOME}/bin/frmf2xml.sh" "${ORACLE_HOME}/bin/frmf2xml")
    if [[ -n "${DOMAIN_HOME:-}" ]]; then
        for candidate in "${DOMAIN_HOME}"/config/fmwconfig/components/FORMS/instances/*/bin/frmf2xml.sh; do
            paths+=("${candidate}")
        done
    fi
    for candidate in "${paths[@]+"${paths[@]}"}"; do
        [[ -x "${candidate}" ]] && { echo "${candidate}"; return 0; }
    done
    return 1
}

# ----------------------------------------------------------------------------- args
if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    [[ $# -lt 1 ]] && exit 1 || exit 0
fi

FMB_DIR="$1"
OUTPUT_BASE="${2:-./output}"

if [[ ! -d "${FMB_DIR}" ]]; then
    echo "ERROR: '${FMB_DIR}' is not a directory." >&2
    usage >&2
    exit 1
fi

FMB_DIR="$(cd "${FMB_DIR}" && pwd)"
mkdir -p "${OUTPUT_BASE}/xml" "${OUTPUT_BASE}/logs" || { echo "ERROR: cannot create ${OUTPUT_BASE}" >&2; exit 1; }
OUTPUT_BASE="$(cd "${OUTPUT_BASE}" && pwd)"
XML_DIR="${OUTPUT_BASE}/xml"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
LOG_FILE="${OUTPUT_BASE}/logs/convert_${TIMESTAMP}.log"
: > "${LOG_FILE}"

if ! FRMF2XML_BIN="$(find_frmf2xml)"; then
    log ERROR "frmf2xml not found or not executable. Set FRMF2XML=/path/to/frmf2xml.sh"
    log ERROR "Typical location: \$DOMAIN_HOME/config/fmwconfig/components/FORMS/instances/forms1/bin/frmf2xml.sh"
    exit 1
fi
read -r -a OPTS <<< "${FRMF2XML_OPTS:-OVERWRITE=YES DUMP_OVERRIDDEN_PROPERTIES=YES}"

shopt -s nullglob nocaseglob
FMB_FILES=("${FMB_DIR}"/*.fmb)
shopt -u nocaseglob

if [[ ${#FMB_FILES[@]} -eq 0 ]]; then
    log WARN "No .fmb files found in ${FMB_DIR}"
    exit 1
fi

log INFO "frmf2xml   : ${FRMF2XML_BIN}"
log INFO "Options    : ${OPTS[*]}"
log INFO "Source dir : ${FMB_DIR}"
log INFO "Output dir : ${XML_DIR}"
log INFO "FORMS_PATH : ${FORMS_PATH:-<not set>}"
log INFO "Files found: ${#FMB_FILES[@]}"

# ----------------------------------------------------------------------------- loop
SUCCESS=0
FAILED=0
FAILED_LIST=()
START_TS=$(date +%s)

for fmb in "${FMB_FILES[@]}"; do
    base="$(basename "${fmb}")"
    name="${base%.*}"
    expected_xml="${XML_DIR}/${name}_fmb.xml"
    file_log="${OUTPUT_BASE}/logs/${name}_${TIMESTAMP}.log"

    log INFO "Converting ${base} ..."
    rm -f "${expected_xml}"

    # frmf2xml writes into the current directory -> run inside XML_DIR
    ( cd "${XML_DIR}" && "${FRMF2XML_BIN}" "${OPTS[@]}" "${fmb}" ) > "${file_log}" 2>&1
    rc=$?

    # frmf2xml may name output <name>_fmb.xml; accept case variations
    if [[ ! -s "${expected_xml}" ]]; then
        alt="$(find "${XML_DIR}" -maxdepth 1 -iname "${name}_fmb.xml" -print -quit 2>/dev/null || true)"
        [[ -n "${alt}" && -s "${alt}" ]] && expected_xml="${alt}"
    fi

    if [[ ${rc} -eq 0 && -s "${expected_xml}" ]] && grep -q "<Module" "${expected_xml}" 2>/dev/null; then
        size=$(wc -c < "${expected_xml}" | tr -d ' ')
        log OK "${base} -> $(basename "${expected_xml}") (${size} bytes)"
        SUCCESS=$((SUCCESS + 1))
        rm -f "${file_log}"
    else
        log FAIL "${base} (exit code ${rc}). Details: ${file_log}"
        tail -n 5 "${file_log}" 2>/dev/null | sed 's/^/        /' | tee -a "${LOG_FILE}"
        FAILED=$((FAILED + 1))
        FAILED_LIST+=("${base}")
    fi
done

ELAPSED=$(( $(date +%s) - START_TS ))

# ----------------------------------------------------------------------------- summary
{
    echo ""
    echo "================================================================"
    echo " frmf2xml conversion summary"
    echo "================================================================"
    echo " Total files : ${#FMB_FILES[@]}"
    echo " Succeeded   : ${SUCCESS}"
    echo " Failed      : ${FAILED}"
    echo " Elapsed     : ${ELAPSED}s"
    echo " XML output  : ${XML_DIR}"
    echo " Log file    : ${LOG_FILE}"
    if [[ ${FAILED} -gt 0 ]]; then
        echo " Failed files:"
        for f in "${FAILED_LIST[@]}"; do echo "   - ${f}"; done
        echo ""
        echo " Common causes: referenced .olb/.pll not in FORMS_PATH, missing"
        echo " DISPLAY (try xvfb-run), file saved by a newer Forms version."
    fi
    echo "================================================================"
} | tee -a "${LOG_FILE}"

[[ ${FAILED} -gt 0 ]] && exit 2
exit 0
