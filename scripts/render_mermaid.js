/**
 * render_mermaid.js - Pre-render Mermaid diagrams in a Marp presentation to SVG.
 *
 * Marp can't render ```mermaid blocks in a PDF by itself, so this script turns
 * each block into an SVG image and writes a copy of the presentation that
 * points to those images. Marp then builds the PDF from that copy.
 *
 * Usage (normally called by marp_create_presentation in aliases_marp.sh):
 *     cd "$(git rev-parse --show-toplevel)"
 *     node ~/bash_utils/scripts/render_mermaid.js [--force-full]
 *
 *     --force-full  Render every diagram again. Without it, a diagram that
 *                   matches the same-numbered diagram in the version of
 *                   presentation.md at git HEAD, and whose SVG already exists,
 *                   is not rendered again. marp_create_presentation
 *                   always passes this flag.
 *
 * Required project layout (paths are relative to the current directory, which
 * must be the git repository root):
 *
 *     <repo root>/
 *       presentation/
 *         presentation.md               # Source slides (Marp markdown), with ```mermaid blocks
 *         presentation.css              # Marp theme; must declare  /* @theme presentation *\/
 *         diagrams/                     # Generated: diagram_N.mmd + diagram_N.svg (created if missing)
 *         presentation_with_images.md   # Generated: blocks replaced by ![Diagram N](diagrams/diagram_N.svg)
 *         presentation.pdf              # Generated afterward by marp (aliases_marp.sh)
 *
 * The folder must be named "presentation" and the files "presentation.md" and
 * "presentation.css". These names are hardcoded here and in aliases_marp.sh.
 *
 * Notes:
 *   - Diagrams are numbered 1..N in the order they appear. Adding or removing
 *     a diagram renumbers the ones after it. Keep that in mind for the
 *     git-HEAD cache, and don't hand-edit files in diagrams/.
 *   - The first "theme: <name>" line in presentation.md is changed to
 *     "theme: presentation" in the generated copy, so the custom CSS theme is used.
 *   - Diagrams use a dark theme with a transparent background (white text,
 *     lavender #b19cd9 borders) and are limited to 800x500.
 *   - Rendering uses `npx -y -p @mermaid-js/mermaid-cli@11 mmdc`, so it needs
 *     Node.js and network access the first time (Puppeteer/Chromium download).
 *   - A temporary presentation/mermaid-config.json is written and then deleted.
 *   - The exit code is 1 if any diagram fails to render. The generated
 *     markdown is still written.
 */

const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Project root = current working directory (caller cd's to the git toplevel)
const projectRoot = process.cwd();

// Helper function to extract mermaid diagrams from markdown content
function extractMermaidDiagrams(content) {
    const mermaidRegex = /```mermaid\r?\n([\s\S]*?)```/g;
    let match;
    let diagrams = [];

    while ((match = mermaidRegex.exec(content)) !== null) {
        diagrams.push(match[1]);
    }

    return diagrams;
}

// Helper function to get committed version of presentation.md
function getCommittedPresentationContent() {
    try {
        // Try to get the file from the last commit
        const committedContent = execSync('git show HEAD:presentation/presentation.md', {
            cwd: projectRoot,
            encoding: 'utf8'
        });
        return committedContent;
    } catch (error) {
        // File doesn't exist in the last commit or git error
        console.log('No committed version found, will render all diagrams');
        return null;
    }
}

// Create custom Mermaid theme configuration with CSS overrides
const mermaidConfig = {
    theme: 'dark',
    themeCSS: `
        g.classGroup rect {
            fill: #2d2d2d !important;
            stroke: #b19cd9 !important;
            stroke-width: 2 !important;
        }
        g.classGroup line {
            stroke: #b19cd9 !important;
        }
        .divider {
            stroke: #b19cd9 !important;
        }
        .node rect, .node circle, .node ellipse, .node polygon, .node path {
            fill: #2d2d2d !important;
            stroke: #b19cd9 !important;
        }
        text {
            fill: #ffffff !important;
        }
        .relation {
            stroke: #ffffff !important;
        }
        .label text {
            fill: #ffffff !important;
        }
        .edgeLabel {
            background-color: #2d2d2d !important;
        }
    `,
    themeVariables: {
        // Transparent background
        background: 'transparent',
        darkMode: true,

        // Text colors
        primaryTextColor: '#ffffff',
        textColor: '#ffffff',

        // Font settings
        fontFamily: 'Roboto, sans-serif',
        fontSize: '14px'
    }
};

// Write config to temporary file
const configPath = path.join(projectRoot, 'presentation/mermaid-config.json');
fs.writeFileSync(configPath, JSON.stringify(mermaidConfig, null, 2));

// Read the current presentation file
const content = fs.readFileSync(path.join(projectRoot, 'presentation/presentation.md'), 'utf8');

// Extract mermaid diagrams from current content
const diagrams = extractMermaidDiagrams(content);

console.log(`Found ${diagrams.length} Mermaid diagrams`);

// Check if we should force full rendering (ignore git cache)
const forceFullRender = process.argv.includes('--force-full');

// Get committed version and extract its diagrams (unless forcing full render)
const committedContent = forceFullRender ? null : getCommittedPresentationContent();
const committedDiagrams = committedContent ? extractMermaidDiagrams(committedContent) : [];

// Create a temporary directory for diagrams
const diagramsDir = path.join(projectRoot, 'presentation/diagrams');
if (!fs.existsSync(diagramsDir)) {
    fs.mkdirSync(diagramsDir);
}

// Render each diagram (only if changed or new)
let renderedCount = 0;
let skippedCount = 0;

diagrams.forEach((diagram, index) => {
    const mmdFilename = `diagram_${index + 1}.mmd`;
    const svgFilename = `diagram_${index + 1}.svg`;
    const filename = path.join(diagramsDir, mmdFilename);
    const outputFile = path.join(diagramsDir, svgFilename);

    // Create clickable path relative to project root
    const clickableMmdPath = `presentation/diagrams/${mmdFilename}:1`;

    // Check if this diagram has changed from the committed version
    const hasChanged = !committedDiagrams[index] || committedDiagrams[index] !== diagram;
    const outputExists = fs.existsSync(outputFile);

    if (!hasChanged && outputExists) {
        console.log(`${clickableMmdPath}: Diagram ${index + 1} unchanged, reusing existing SVG`);
        skippedCount++;
        // Still write the .mmd file to keep them in sync
        fs.writeFileSync(filename, diagram);
        return;
    }

    // Write mermaid code to file
    fs.writeFileSync(filename, diagram);

    try {
        // Use mermaid-cli to render with size constraints and custom theme
        // -w sets width, -H sets height to prevent overflow
        // -c specifies the config file with custom theme
        // -b transparent for transparent background (will show dark gray from config)
        execSync(`npx -y -p @mermaid-js/mermaid-cli@11 mmdc -i "${filename}" -o "${outputFile}" -c "${configPath}" -b transparent -w 800 -H 500`,
                 { stdio: 'inherit' });
        console.log(`${clickableMmdPath}: Diagram ${index + 1} rendered [${hasChanged ? 'changed' : 'new'}]`);
        renderedCount++;
    } catch (error) {
        console.error(`${clickableMmdPath}: Failed to render diagram ${index + 1} - ${error.message}`);
        process.exitCode = 1;
    }
});

console.log(`\nSummary: ${renderedCount} diagram(s) rendered, ${skippedCount} diagram(s) reused`);

// Now replace mermaid blocks with image references
let updatedContent = content;
let diagramIndex = 0;

updatedContent = updatedContent.replace(/```mermaid\r?\n[\s\S]*?```/g, () => {
    diagramIndex++;
    return `![Diagram ${diagramIndex}](diagrams/diagram_${diagramIndex}.svg)`;
});

// Ensure the presentation theme is preserved in the frontmatter
updatedContent = updatedContent.replace(/theme:\s*\w+/, 'theme: presentation');

// Write the updated presentation
const outputPath = path.join(projectRoot, 'presentation/presentation_with_images.md');
fs.writeFileSync(outputPath, updatedContent);

// Clean up the config file
try {
    fs.unlinkSync(configPath);
} catch (err) {
    // Ignore if file doesn't exist
}

console.log('Created presentation_with_images.md with embedded diagrams');