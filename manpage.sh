#!/bin/bash

# BBEdit Preview Filter for Markdown Manpages
# Converts Markdown to formatted manpage using Pandoc
# Displays properly formatted output in Terminal

# Check if pandoc is available
if ! command -v pandoc &> /dev/null; then
    echo "<html><body><h1>Error</h1><p>Pandoc is not installed or not in PATH.</p><p>Please install pandoc to use this filter.</p></body></html>"
    exit 1
fi

# Check if man command is available
if ! command -v man &> /dev/null; then
    echo "<html><body><h1>Error</h1><p>man command is not available.</p></body></html>"
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
    echo "<html><body><h1>Error</h1><p>Failed to convert Markdown to man page format.</p><p>Please check your Markdown syntax and pandoc installation.</p></body></html>"
    exit 1
fi

# Convert the roff output to HTML using man
if ! man -Thtml "$TEMP_ROFF" > "$TEMP_HTML" 2>/dev/null; then
    # Fallback: try using groff directly
    if command -v groff &> /dev/null; then
        if ! groff -mandoc -Thtml "$TEMP_ROFF" > "$TEMP_HTML" 2>/dev/null; then
            echo "<html><body><h1>Error</h1><p>Failed to format man page for display.</p></body></html>"
            exit 1
        fi
    else
        echo "<html><body><h1>Error</h1><p>Neither man nor groff is available for HTML formatting.</p></body></html>"
        exit 1
    fi
fi

# If HTML conversion worked, display it
if [ -s "$TEMP_HTML" ]; then
    # Add some basic styling to make it look better
    cat << 'EOF'
<html>
<head>
    <style>
        body {
            font-family: monospace;
            max-width: 80ch;
            margin: 2em auto;
            padding: 1em;
            line-height: 1.4;
            background-color: #f8f8f8;
        }
        h1 { border-bottom: 2px solid #333; }
        h2 { border-bottom: 1px solid #666; margin-top: 2em; }
        .man-page { background: white; padding: 2em; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        pre { background: #f0f0f0; padding: 1em; border-radius: 4px; overflow-x: auto; }
        code { background: #f0f0f0; padding: 0.2em 0.4em; border-radius: 2px; }
    </style>
</head>
<body>
    <div class="man-page">
EOF
    
    # Extract the body content from the generated HTML
    sed -n '/<body>/,/<\/body>/p' "$TEMP_HTML" | sed '1d;$d'
    
    cat << 'EOF'
    </div>
</body>
</html>
EOF
else
    # Fallback: create a simple HTML display of the roff source
    echo "<html><head><title>Man Page Preview</title></head><body>"
    echo "<h1>Man Page Preview</h1>"
    echo "<pre>"
    # Escape HTML characters in the roff output
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$TEMP_ROFF"
    echo "</pre>"
    echo "</body></html>"
fi
