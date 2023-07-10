# Scute - *Site Creation (u) Tool (e)*

An extensible static site generator. Supports macOS and Linux.

## Overview

Scute is a markdown-oriented static site generation tool. Pages are created using markdown,
and automatically generated elements such as tables of contents and blog post lists are
implemented via custom markdown plugins (e.g. `@TableOfContents{depth:2}@`).

The structure of your website is purely controlled by the structure of your source files and
directories, keeping things simple.

GitHub flavoured markdown is supported.

In future I hope to make a simple mechanism for site creators to implement their own plugins
to further customise the site generator.

## Installation

`scute` hasn't been added to homebrew yet, and mint can't successfully install it, so for now
it must be installed manually.

```sh
git clone https://github.com/stackotter/scute
cd scute
swift build -c release
sudo cp .build/release/scute /usr/local/bin
```

## Quickstart

```sh
scute create site_name
cd site_name
scute preview
```

If hosting with Vercel, you can use `scute create site_name --vercel` to automatically
create the required `vercel.json` file along with your website.

## Configuration

Every scute project has a `Scute.toml` configuration file. The following example showcases
all available configuration options.

```toml
config_version = 1 # always 1 for now
name = "Website Name"
input = "./src"
output = "./build"
page_template = "./src/_template.html"
syntax_theme = "atom-one-dark"
```

## Customisation

### Customising theme

To customise a Scute site all you need to know is HTML and CSS. Just modify your page template
(located at `src/_template.html` by default) and the stylesheet (located at `src/css/page.css`
by default).

### Adding pages

To add a page simply create a new markdown file and the route to that file once built will
match the path to the file on disk (relative to the input directory). For example, creating
`src/achievements.md` will create a new page at `/achievements`, and so will creating a file
at `src/achievements/index.md`.

### Adding resources

To add resources to your website, simply just add them to the input folder wherever you want.
Any files that aren't handled by a plugin (only `markdown` and `css` by default) will get
copied as-is to the output directory (preserving their location in the folder structure).

## Features

- GitHub flavoured markdown
- CSS minification (unused rules are removed)
- Code block syntax highlighting
- Auto-generated header ids for linking between sections
- Automatic table of contents generation markdown extension
- Automatic article list generation markdown extension
