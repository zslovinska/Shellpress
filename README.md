# Shellpress
## Powershell script for converting markdown files to html using [pandoc](https://pandoc.org/)

Usage:
Publish-Portal [-Statistics] [-Destination dest] [file.markdown...]
- -Statistics - turn on generating statistics file (files count, words count)
- -Destination dest - publish file to dest

Notes:
- if list of files is empty, generate html for every file in current directory
- also generates index.html with list of every file
