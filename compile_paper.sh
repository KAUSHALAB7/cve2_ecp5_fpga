#!/bin/bash

# CVE2 RISC-V FPGA Research Paper - Compilation Script
# Combines all parts and generates PDF

set -e

PROJ_DIR="/home/kaushal/cve2_fpga_project"
cd "$PROJ_DIR"

echo "================================================"
echo "CVE2 RISC-V Research Paper Compilation"
echo "================================================"
echo ""

# Check if LaTeX is installed
if ! command -v pdflatex &> /dev/null; then
    echo "ERROR: pdflatex not found!"
    echo "Install with: sudo apt-get install texlive-latex-extra texlive-fonts-recommended"
    exit 1
fi

# Combine all parts
echo "[1/5] Combining document parts..."
cat paper_cve2_riscv.tex | head -n -1 > paper_complete.tex
cat paper_part2_background.tex >> paper_complete.tex
cat paper_part3_architecture.tex >> paper_complete.tex
cat paper_part4_implementation.tex >> paper_complete.tex
cat paper_part5_results_conclusion.tex >> paper_complete.tex

echo "      Created: paper_complete.tex ($(wc -l < paper_complete.tex) lines)"

# First compilation pass
echo "[2/5] Running pdflatex (first pass)..."
pdflatex -interaction=nonstopmode paper_complete.tex > compile_log1.txt 2>&1
if [ $? -ne 0 ]; then
    echo "      ERROR: First pass failed. Check compile_log1.txt"
    grep "^!" compile_log1.txt | head -5
    exit 1
fi
echo "      Success!"

# Second compilation pass (for cross-references)
echo "[3/5] Running pdflatex (second pass)..."
pdflatex -interaction=nonstopmode paper_complete.tex > compile_log2.txt 2>&1
if [ $? -ne 0 ]; then
    echo "      ERROR: Second pass failed. Check compile_log2.txt"
    grep "^!" compile_log2.txt | head -5
    exit 1
fi
echo "      Success!"

# Clean up auxiliary files
echo "[4/5] Cleaning up auxiliary files..."
rm -f *.aux *.log *.out *.toc *.lof *.lot compile_log1.txt compile_log2.txt
echo "      Done!"

# Verify PDF was created
if [ -f paper_complete.pdf ]; then
    FILESIZE=$(du -h paper_complete.pdf | cut -f1)
    PAGES=$(pdfinfo paper_complete.pdf 2>/dev/null | grep "^Pages:" | awk '{print $2}')
    echo "[5/5] PDF generated successfully!"
    echo ""
    echo "================================================"
    echo "SUCCESS!"
    echo "================================================"
    echo "File: paper_complete.pdf"
    echo "Size: $FILESIZE"
    echo "Pages: $PAGES"
    echo "Location: $PROJ_DIR/paper_complete.pdf"
    echo ""
    echo "Opening PDF viewer..."
    
    # Try to open with available PDF viewer
    if command -v xdg-open &> /dev/null; then
        xdg-open paper_complete.pdf &
    elif command -v evince &> /dev/null; then
        evince paper_complete.pdf &
    elif command -v okular &> /dev/null; then
        okular paper_complete.pdf &
    else
        echo "No PDF viewer found. Please open paper_complete.pdf manually."
    fi
else
    echo "ERROR: PDF was not created!"
    exit 1
fi
