#!/bin/sh
set -eu
# Linux x86_64. System dependencies are listed in README.md.
PANDOC_VERSION=3.8.2
CROSSREF_VERSION=0.3.22
tool_dir="${XDG_DATA_HOME:-$HOME/.local/share}/ampire-pandoc"
bin_dir="$HOME/.local/bin"
mkdir -p "$tool_dir" "$bin_dir"
curl -fL --retry 3 "https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-linux-amd64.tar.gz" -o "$tool_dir/pandoc.tar.gz"
printf '%s  %s\n' '3252c5fd8234925f46973f4f17f852ccda64777a0c631d5735861c7eb4d69132' "$tool_dir/pandoc.tar.gz" | sha256sum -c -
tar -xzf "$tool_dir/pandoc.tar.gz" -C "$tool_dir"
curl -fL --retry 3 "https://github.com/lierdakil/pandoc-crossref/releases/download/v$CROSSREF_VERSION/pandoc-crossref-Linux-X64.tar.xz" -o "$tool_dir/crossref.tar.xz"
printf '%s  %s\n' '401b8aa8dcdfe1ea5a3939353bdab2a76bc4198d3ccc3cadec1c9181f8f65377' "$tool_dir/crossref.tar.xz" | sha256sum -c -
tar -xJf "$tool_dir/crossref.tar.xz" -C "$tool_dir"
ln -sf "$tool_dir/pandoc-$PANDOC_VERSION/bin/pandoc" "$bin_dir/pandoc"
ln -sf "$tool_dir/pandoc-crossref" "$bin_dir/pandoc-crossref"
printf '%s\n' 'Tools installed. Add $HOME/.local/bin to PATH, then run make check.'
