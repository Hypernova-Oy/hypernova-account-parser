# hypernova-account-parser

This tool parses accounting documents and exports them in a simple csv format.

# Requirements

* Install `pdftotext` utility

`sudo apt-get install poppler-utils cpanminus`

# Installation

```
git clone https://github.com/Hypernova-Oy/hypernova-account-parser
cd hypernova-account-parser
sudo cpanm --installdeps .
```

# Usage

`perl -I . convert_to_csv.pl document.pdf`
