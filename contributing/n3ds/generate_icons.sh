#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Detect OS and pick the right ctrtool binary
case "$(uname -s)" in
    Darwin*) TOOL_3DS="${SCRIPT_DIR}/tools/macos/ctrtool" ;;
    Linux*)  TOOL_3DS="${SCRIPT_DIR}/tools/linux/ctrtool" ;;
    *)
        echo "[Error] Unsupported OS: $(uname -s)"
        exit 1
        ;;
esac

ICON_CONVERTER="${SCRIPT_DIR}/_icon_to_png.py"
SANITIZER="${SCRIPT_DIR}/_sanitize.py"
OUTPUT_DIR="${REPO_ROOT}/icons/n3ds"
GAMES_DIR="${SCRIPT_DIR}/games"

echo "-------------------------------------------------------"
echo "3DS Icon Extractor (Batch Mode)"
echo "-------------------------------------------------------"

# Verify required files exist
if [[ ! -f "${ICON_CONVERTER}" ]]; then
    echo "[Error] _icon_to_png.py not found. Place it in the same folder as this script."
    exit 1
fi
if [[ ! -f "${SANITIZER}" ]]; then
    echo "[Error] _sanitize.py not found. Place it in the same folder as this script."
    exit 1
fi
if [[ ! -f "${TOOL_3DS}" ]]; then
    echo "[Error] ctrtool not found. Expected at: ${TOOL_3DS}"
    exit 1
fi

chmod +x "${TOOL_3DS}"

# Prefer a project venv if present, otherwise fall back to PATH python
DOTENV_PYTHON="${SCRIPT_DIR}/../../.venv/bin/python"
VENV_PYTHON="${SCRIPT_DIR}/../../venv/bin/python"
if [[ -f "${DOTENV_PYTHON}" ]]; then
    PYTHON="${DOTENV_PYTHON}"
elif [[ -f "${VENV_PYTHON}" ]]; then
    PYTHON="${VENV_PYTHON}"
elif command -v python3 &>/dev/null; then
    PYTHON="python3"
elif command -v python &>/dev/null; then
    PYTHON="python"
else
    echo "[Error] Python not found in PATH. Install Python and retry."
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${GAMES_DIR}"

# Collect .3ds and .cci files
mapfile -d '' GAME_FILES < <(find "${GAMES_DIR}" -maxdepth 1 \( -name "*.3ds" -o -name "*.cci" \) -print0 2>/dev/null)

if [[ ${#GAME_FILES[@]} -eq 0 ]]; then
    echo "[Info] No .3ds or .cci files found in: ${GAMES_DIR}"
    echo "Add ROM files to the games folder, then run this script again."
    exit 0
fi

PROCESSED=0
SUCCESS=0

process_game() {
    local GAME_FILE="$1"
    local FILENAME
    FILENAME="$(basename "${GAME_FILE}")"
    local EXEFS_DIR
    EXEFS_DIR="$(mktemp -d)"
    local ICON_RAW="${EXEFS_DIR}/icon"
    local ICON_BIN="${EXEFS_DIR}/icon.bin"

    local SANITIZED_NAME
    SANITIZED_NAME="$("${PYTHON}" "${SANITIZER}" "${FILENAME}" 2>/dev/null || true)"
    if [[ -z "${SANITIZED_NAME}" ]]; then
        SANITIZED_NAME="${FILENAME%.*}"
    fi

    local OUTPUT_PNG="${OUTPUT_DIR}/${SANITIZED_NAME}.png"

    echo "[Processing] ${FILENAME}..."

    if ! "${TOOL_3DS}" --exefsdir="${EXEFS_DIR}" "${GAME_FILE}" &>/dev/null; then
        echo "[Warning] ctrtool failed on ${FILENAME}."
        rm -rf "${EXEFS_DIR}"
        return 1
    fi

    if [[ -f "${ICON_RAW}" ]]; then
        cp "${ICON_RAW}" "${ICON_BIN}"
    elif [[ ! -f "${ICON_BIN}" ]]; then
        echo "[Warning] icon file not found in ExeFS for ${FILENAME}."
        rm -rf "${EXEFS_DIR}"
        return 1
    fi

    if ! "${PYTHON}" "${ICON_CONVERTER}" "${ICON_BIN}" "${OUTPUT_PNG}"; then
        echo "[Warning] Python conversion failed for ${FILENAME}. Ensure pyctr is installed: pip install pyctr"
        rm -rf "${EXEFS_DIR}"
        return 1
    fi

    if [[ ! -f "${OUTPUT_PNG}" ]]; then
        echo "[Warning] Conversion reported success but no output file was found for ${FILENAME}."
        rm -rf "${EXEFS_DIR}"
        return 1
    fi

    echo "[Saved] ${OUTPUT_PNG}"
    rm -rf "${EXEFS_DIR}"
    return 0
}

for GAME_FILE in "${GAME_FILES[@]}"; do
    PROCESSED=$((PROCESSED + 1))
    if process_game "${GAME_FILE}"; then
        SUCCESS=$((SUCCESS + 1))
    fi
done

echo ""
echo "-------------------------------------------------------"
echo "Finished. Processed: ${PROCESSED}  Success: ${SUCCESS}"
echo "Output folder: ${OUTPUT_DIR}"
echo "-------------------------------------------------------"
