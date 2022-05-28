## asciidoc2txt

A simple asciidoc to text converter.

```sh
asciidoc2txt.sh - Convert asciidoc input to text.
Usage: asciidoc2txt.sh [flags] [in-file|-]
Input file: 'test-resume.adoc'.
Option flags:
  -o --out-file - Output file. Default: '/dev/stdout'.
  -e --extended - Enable extended output file. Default: ''.
  -h --help     - Show this help and exit.
  -v --verbose  - Verbose execution. Default: ''.
  -g --debug    - Extra verbose execution. Default: ''.
Info:
  asciidoc2txt asciidoc2txt.sh
  Project Home: https://github.com/glevand/asciidoc2txt
```

See the [asciidoc reference](https://docs.asciidoctor.org/asciidoc/latest/syntax-quick-reference/) for syntax.

## Generate test files

```
asciidoctor -v test-resume.adoc
asciidoctor-pdf -v test-resume.adoc
asciidoc2txt.sh test-resume.adoc
```

## Licence & Usage

All files in the [asciidoc2txt project](https://github.com/glevand/asciidoc2txt), unless otherwise noted, are covered by an [MIT Plus License](https://github.com/glevand/asciidoc2txt/blob/master/mit-plus-license.txt).  The text of the license describes what usage is allowed.
