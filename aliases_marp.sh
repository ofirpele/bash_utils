function marp_create_presentation()
{
    cd "$(git rev-parse --show-toplevel)" || return 1

    local input_file="presentation/presentation_with_images.md"
    local output_file="presentation/presentation.pdf"

    # Check if cached presentation_with_images.md exists
    if [[ ! -f "$input_file" ]]; then
        echo "ERROR: Cached file '$input_file' not found" >&2
        echo "Run 'py_create_presentation_full' first to render diagrams" >&2
        return 1
    fi

    # Check if marp-cli is installed
    if ! command -v marp &> /dev/null; then
        echo "Installing marp-cli..." >&2
        npm install -g @marp-team/marp-cli
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to install marp-cli" >&2
            echo "You can try installing it manually with: npm install -g @marp-team/marp-cli" >&2
            return 1
        fi
    fi

    # Use cached presentation_with_images.md (no rendering)
    echo "Using cached presentation (no re-rendering)..."
    marp "$input_file" \
        --pdf \
        --allow-local-files \
        --theme presentation \
        --theme-set presentation/presentation.css \
        --output "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "Successfully generated: $output_file"
        pdf_present "$output_file"
        return 0
    else
        echo "ERROR: Failed to generate presentation PDF" >&2
        return 1
    fi
}

function marp_create_presentation_full()
{
    cd "$(git rev-parse --show-toplevel)" || return 1

    local input_file="presentation/presentation.md"
    local output_file="presentation/presentation.pdf"

    if [[ ! -f "$input_file" ]]; then
        echo "ERROR: Input file '$input_file' not found" >&2
        return 1
    fi

    # Check if marp-cli is installed
    if ! command -v marp &> /dev/null; then
        echo "Installing marp-cli..." >&2
        npm install -g @marp-team/marp-cli
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to install marp-cli" >&2
            echo "You can try installing it manually with: npm install -g @marp-team/marp-cli" >&2
            return 1
        fi
    fi

    if ! command -v node &> /dev/null; then
        echo "ERROR: Node.js is required for Mermaid rendering" >&2
        return 1
    fi

    # Always render all diagrams (ignore git cache)
    echo "Rendering all mermaid diagrams (full render)..."
    node "$HOME/bash_utils/scripts/render_mermaid.js" --force-full

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to render Mermaid diagrams" >&2
        echo "Falling back to PDF without Mermaid diagrams..." >&2
        marp "$input_file" --pdf --allow-local-files --theme presentation --theme-set presentation/presentation.css --output "$output_file"
    else
        # Generate PDF from the file with rendered images
        marp "presentation/presentation_with_images.md" \
            --pdf \
            --allow-local-files \
            --theme presentation \
            --theme-set presentation/presentation.css \
            --output "$output_file"

        if [[ $? -eq 0 ]]; then
            echo "Successfully generated: $output_file"
            pdf_present "$output_file"

            echo ""
            uv run --no-project --python ">=3.10" python "$HOME/bash_utils/scripts/check_presentation_overflow.py" "$input_file"

            return 0
        else
            echo "ERROR: Failed to generate presentation PDF" >&2
            return 1
        fi
    fi
}
