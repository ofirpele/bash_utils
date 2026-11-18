_MARP_DIR="presentation"
_MARP_SOURCE="$_MARP_DIR/presentation.md"
_MARP_WITH_IMAGES="$_MARP_DIR/presentation_with_images.md"
_MARP_OUTPUT="$_MARP_DIR/presentation.pdf"
_MARP_THEME="$_MARP_DIR/presentation.css"

function _marp_cd_root()
{
    local root
    if ! root="$(git rev-parse --show-toplevel 2> /dev/null)"; then
        echo "ERROR: Not inside a git repository" >&2
        return 1
    fi

    if ! cd "$root"; then
        echo "ERROR: Failed to cd to repository root '$root'" >&2
        return 1
    fi
}

function _marp_require_file()
{
    local file="$1"
    local hint="$2"

    if [[ ! -f "$file" ]]; then
        echo "ERROR: File '$file' not found" >&2
        [[ -n "$hint" ]] && echo "$hint" >&2
        return 1
    fi
}

function _marp_ensure_cli()
{
    command -v marp &> /dev/null && return 0

    echo "Installing marp-cli..." >&2
    if ! npm install -g @marp-team/marp-cli; then
        echo "ERROR: Failed to install marp-cli" >&2
        echo "You can try installing it manually with: npm install -g @marp-team/marp-cli" >&2
        return 1
    fi
}

# Build the PDF from the given markdown file and open it.
function _marp_build_pdf()
{
    local input_file="$1"

    if ! marp "$input_file" \
        --pdf \
        --allow-local-files \
        --theme-set "$_MARP_THEME" \
        --output "$_MARP_OUTPUT"; then
        echo "ERROR: Failed to generate presentation PDF" >&2
        return 1
    fi

    echo "Successfully generated: $_MARP_OUTPUT"
    pdf_view "$_MARP_OUTPUT"
}

function _marp_run_check()
{
    uv run --no-project --python ">=3.10" python "$HOME/bash_utils/scripts/check_presentation_overflow.py" "$_MARP_SOURCE"
}

function marp_check()
{
    _marp_cd_root || return 1
    _marp_require_file "$_MARP_SOURCE" || return 1
    _marp_run_check
}

function marp_create_presentation()
{
    _marp_cd_root || return 1
    _marp_require_file "$_MARP_SOURCE" || return 1
    _marp_ensure_cli || return 1

    if ! command -v node &> /dev/null; then
        echo "ERROR: Node.js is required for Mermaid rendering" >&2
        return 1
    fi

    # Always render all diagrams (ignore git cache)
    echo "Rendering all mermaid diagrams (full render)..."
    if ! node "$HOME/bash_utils/scripts/render_mermaid.js" --force-full; then
        echo "ERROR: Failed to render Mermaid diagrams" >&2
        echo "Falling back to PDF without Mermaid diagrams..." >&2
        _marp_build_pdf "$_MARP_SOURCE"
        return
    fi

    _marp_build_pdf "$_MARP_WITH_IMAGES" || return 1

    echo ""
    _marp_run_check
    return 0
}
