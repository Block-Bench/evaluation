# BlockBench Research Paper - Clean LaTeX Template

Minimal, clean LaTeX template ready for the BlockBench evaluation paper.

## Files

- **acl2020.tex** - Main document (minimal template with all essential packages)
- **acl2020.bib** - Bibliography file (empty, ready for references)
- **acl2020.sty** - ACL style file
- **acl_natbib.bst** - BibTeX style file
- **figures/** - Directory for figures and charts

## Template Features

The template includes:
- Two-column ACL format
- Times font, proper margins
- Figure and table support (graphicx, booktabs, multirow)
- Hyperlinks (blue colored)
- Code/verbatim boxes (PromptBox environment, FramedPrompt)
- Optimized list spacing
- Bibliography support (natbib)

## How to Use

1. Edit `acl2020.tex` - add your content after `% CONTENT HERE`
2. Add references to `acl2020.bib`
3. Place figures in `figures/` directory
4. Compile: `pdflatex acl2020 && bibtex acl2020 && pdflatex acl2020 && pdflatex acl2020`

## Ready to Start

The template is completely clean - no predefined sections, just the essential LaTeX structure.
