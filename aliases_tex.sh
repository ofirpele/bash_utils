# ---------------------------------------------------------------------------
# tex_compile: build a .tex file into a PDF and open it in SumatraPDF.
#
#   tex_compile [name|name.tex]
#
# Runs pdflatex twice so that \ref / \label cross-references and the table of
# contents resolve correctly.
# ---------------------------------------------------------------------------
tex_compile() {
    local input=$1
    local base="${input%.tex}"
    local tex_file="${base}.tex"
    local pdf_file="${base}.pdf"

    local out_dir
    out_dir="$(dirname "$tex_file")"

    if [[ ! -f "$tex_file" ]]; then
        echo "ERROR: '$tex_file' not found in $(pwd)." >&2
        return 1
    fi

    if ! command -v pdflatex >/dev/null 2>&1; then
        echo "ERROR: 'pdflatex' not found. Run '_tex_install' first (and open a new shell)." >&2
        return 1
    fi

    echo "==> Compiling $tex_file (pass 1/2)..."
    pdflatex -shell-escape -interaction=nonstopmode -halt-on-error -output-directory="$out_dir" "$tex_file" || {
        echo "ERROR: pdflatex failed. See ${base}.log for details." >&2
        return 1
    }

    echo "==> Compiling $tex_file (pass 2/2)..."
    pdflatex -shell-escape -interaction=nonstopmode -halt-on-error -output-directory="$out_dir" "$tex_file" || {
        echo "ERROR: pdflatex failed on second pass. See ${base}.log for details." >&2
        return 1
    }

    if [[ ! -f "$pdf_file" ]]; then
        echo "ERROR: expected '$pdf_file' was not produced." >&2
        return 1
    fi

    rm -f "${base}.aux" "${base}.log" "${base}.out"

    echo "==> Opening $pdf_file in SumatraPDF..."
    pdf_view "$pdf_file"
}

# not robust
_tex_install() {
    export PATH="$PATH:/c/Users/itama/AppData/Local/Programs/MiKTeX/miktex/bin/x64"
    export PATH="$PATH:$HOME/.cargo/bin"

    echo "==> Installing TeX distribution and tools via winget..."

    if ! command -v winget >/dev/null 2>&1; then
        echo "ERROR: 'winget' was not found. Install 'App Installer' from the" >&2
        echo "       Microsoft Store, then re-run tex_install." >&2
        return 1
    fi

    # MiKTeX: lightweight, installs missing packages on demand.
    echo "==> Installing MiKTeX..."
    winget install --id MiKTeX.MiKTeX --accept-source-agreements --accept-package-agreements -e || {
        echo "WARNING: MiKTeX install reported a non-zero exit code (may already be installed)." >&2
    }

    # SumatraPDF: fast viewer that does NOT lock the PDF file, so rebuilds work.
    echo "==> Installing SumatraPDF..."
    winget install --id SumatraPDF.SumatraPDF --accept-source-agreements --accept-package-agreements -e || {
        echo "WARNING: SumatraPDF install reported a non-zero exit code (may already be installed)." >&2
    }

    echo
    echo "==> NOTE: open a NEW shell so that 'pdflatex' is on PATH before compiling."
    echo "          MiKTeX auto-installs any missing package on first use."

    echo "==> Installing cargo (Rust) and tex-fmt..."

    if ! command -v cargo >/dev/null 2>&1; then
        if ! command -v winget >/dev/null 2>&1; then
            echo "ERROR: 'winget' was not found. Install 'App Installer' from the" >&2
            echo "       Microsoft Store, then re-run tex_fmt_install." >&2
            return 1
        fi

        echo "==> Installing rustup (provides cargo) via winget..."
        winget install --id Rustlang.Rustup --accept-source-agreements --accept-package-agreements -e || {
            echo "WARNING: rustup install reported a non-zero exit code (may already be installed)." >&2
        }

        # winget puts cargo in ~/.cargo/bin; make it available in THIS shell too.
        export PATH="$PATH:$HOME/.cargo/bin"
    fi

    if ! command -v cargo >/dev/null 2>&1; then
        echo "ERROR: 'cargo' still not found. Open a NEW shell and re-run tex_fmt_install." >&2
        return 1
    fi

    echo "==> Installing tex-fmt via cargo..."
    cargo install tex-fmt || {
        echo "ERROR: 'cargo install tex-fmt' failed." >&2
        return 1
    }

    echo
    echo "==> tex-fmt installed to ~/.cargo/bin. Open a NEW shell if 'tex-fmt' is not yet on PATH."
}
