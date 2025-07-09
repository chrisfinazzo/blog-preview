#!/bin/bash
# BBEdit Preview Filter for Markdown Manpages
# Converts Markdown to formatted manpage using Pandoc
# Displays properly formatted output using external template files

# Path to template files (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_HTML="$SCRIPT_DIR/man.html"

# Check if pandoc is available
if ! command -v pandoc &> /dev/null; then
    echo "<html><body><div class='error'><h1>Error</h1><p>Pandoc is not installed or not in PATH.</p><p>Please install pandoc to use this filter.</p></div></body></html>"
    exit 1
fi

# Check if man command is available
if ! command -v man &> /dev/null; then
    echo "<html><body><div class='error'><h1>Error</h1><p>man command is not available.</p></div></body></html>"
    exit 1
fi

# Create temporary files
TEMP_DIR=$(mktemp -d)
TEMP_MD="$TEMP_DIR/input.md"
TEMP_ROFF="$TEMP_DIR/output.roff"
TEMP_HTML="$TEMP_DIR/output.html"

# Function to cleanup temp files
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Read input from stdin (the Markdown file content)
cat > "$TEMP_MD"

# Convert Markdown to man page format using pandoc
if ! pandoc -s -f markdown -t man "$TEMP_MD" -o "$TEMP_ROFF" 2>/dev/null; then
    if [ -f "$TEMPLATE_HTML" ]; then
        sed 's|<!-- Manpage content will be inserted here -->|<div class="error"><h1>Error</h1><p>Failed to convert Markdown to man page format.</p><p>Please check your Markdown syntax and pandoc installation.</p></div>|' "$TEMPLATE_HTML"
    else
        echo "<html><body><div class='error'><h1>Error</h1><p>Failed to convert Markdown to man page format.</p><p>Please check your Markdown syntax and pandoc installation.</p></div></body></html>"
    fi
    exit 1
fi

# Convert the roff output to HTML using man
if ! man -Thtml "$TEMP_ROFF" > "$TEMP_HTML" 2>/dev/null; then
    # Fallback: try using groff directly
    if command -v groff &> /dev/null; then
        if ! groff -mandoc -Thtml "$TEMP_ROFF" > "$TEMP_HTML" 2>/dev/null; then
            if [ -f "$TEMPLATE_HTML" ]; then
                sed 's|<!-- Manpage content will be inserted here -->|<div class="error"><h1>Error</h1><p>Failed to format man page for display.</p></div>|' "$TEMPLATE_HTML"
            else
                echo "<html><body><div class='error'><h1>Error</h1><p>Failed to format man page for display.</p></div></body></html>"
            fi
            exit 1
        fi
    else
        if [ -f "$TEMPLATE_HTML" ]; then
            sed 's|<!-- Manpage content will be inserted here -->|<div class="error"><h1>Error</h1><p>Neither man nor groff is available for HTML formatting.</p></div>|' "$TEMPLATE_HTML"
        else
            echo "<html><body><div class='error'><h1>Error</h1><p>Neither man nor groff is available for HTML formatting.</p></div></body></html>"
        fi
        exit 1
    fi
fi

# Function to escape special characters for sed
escape_for_sed() {
    printf '%s\n' "$1" | sed "s/[[\.*^$()+?{|]/\\&/g"
}

# If HTML conversion worked, display it using template
if [ -s "$TEMP_HTML" ]; then
    # Extract the body content from the generated HTML
    CONTENT=$(sed -n '/<body>/,/<\/body>/p' "$TEMP_HTML" | sed '1d;$d')
    
    if [ -f "$TEMPLATE_HTML" ]; then
        # Use template file and replace placeholder with content
        ESCAPED_CONTENT=$(escape_for_sed "$CONTENT")
        sed "s|<!-- Manpage content will be inserted here -->|$ESCAPED_CONTENT|" "$TEMPLATE_HTML"
    else
        # Fallback: create basic HTML structure
        cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Man Page Preview</title>
    <style>
        body {
            font-family: 'Monaco', 'Menlo', 'Consolas', 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.4;
            color: #000;
            background-color: #fff;
            padding: 20px;
        }
        .manpage-container {
            max-width: 80ch;
            margin: 0 auto;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="manpage-container">
EOF
        echo "$CONTENT"
        cat << 'EOF'
    </div>
</body>
</html>
EOF
    fi
else
    # Fallback: create a simple HTML display of the roff source
    ROFF_CONTENT=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$TEMP_ROFF")
    FALLBACK_CONTENT="<h1>Man Page Preview</h1><pre>$ROFF_CONTENT</pre>"
    
    if [ -f "$TEMPLATE_HTML" ]; then
        ESCAPED_FALLBACK=$(escape_for_sed "$FALLBACK_CONTENT")
        sed "s|<!-- Manpage content will be inserted here -->|$ESCAPED_FALLBACK|" "$TEMPLATE_HTML"
    else
        echo "<html><head><title>Man Page Preview</title></head><body><div class='manpage-container'>$FALLBACK_CONTENT</div></body></html>"
    fi
fi
