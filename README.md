<p align="center"><img src ="https://github.com/vaclavsvejcar/headroom/blob/master/doc/assets/logo.png?raw=true" width="200" /></p>

> :construction: __Work in Progress__ :construction: - This project is under heavy development, any parts (functionality, API or documentation) may change unexpectedly.

So you are tired of managing license headers in your codebase by hand? Then __Headroom__ is the right tool for you! Now you can define your license header as [Mustache][web:mustache] template, put all the placeholders (such as author's name, year, etc.) into the [YAML][wiki:yaml] config file and Headroom will take care to add such license headers to all your source code files.

__Table of Contents__
<!-- TOC -->

- [1. Main Features](#1-main-features)
- [2. Installation](#2-installation)
    - [2.1. From Source Code](#21-from-source-code)
- [3. Case Example](#3-case-example)
    - [3.1. Adding License Header Templates](#31-adding-license-header-templates)
    - [3.2. Adding Headroom Configuration](#32-adding-headroom-configuration)
    - [3.3. Running Headroom](#33-running-headroom)
- [4. Command Line Interface Overview](#4-command-line-interface-overview)
    - [4.1. Run Command](#41-run-command)
    - [4.2. Generator Command](#42-generator-command)
        - [4.2.1. Supported License Types](#421-supported-license-types)
        - [4.2.2. Supported File Types](#422-supported-file-types)

<!-- /TOC -->

## 1. Main Features
- __License Header Management__ - allows to add, replace or drop license headers in source code files.
- __License Header Autodetection__ - you can even replace or drop license headers that weren't generated by Headroom, as they are automatically detected from source code files, not from template files.
- __Template Generator__ - generates license header templates for most popular _open source_ licenses. You can use these as-is, customize them or ignore them and use your custom templates.

## 2. Installation
> Binary distribution, pre-built packages and installation from Stackage is not ready yet, but it's planned for production release.

### 2.1. From Source Code
Headroom is written in [Haskell][web:haskell], so you can just clone this repository and install it using [Stack][web:stack]:

```shell
curl -sSL https://get.haskellstack.org/ | sh     # needed only if you don't have Stack

git clone https://github.com/vaclavsvejcar/headroom.git
cd headroom/
stack install
```

## 3. Case Example
Let's demonstrate how to use Headroom in real world example: imagine you have small source code repository with following structure and you'd like to setup Headroom for it:

```
project/
  └── src/
      ├── scala/
      │   ├── Foo.scala
      │   └── Bar.scala
      └── html/
          └── template1.html
```

### 3.1. Adding License Header Templates
Let's say our project is licensed under the [3-Clause BSD License][web:bsd-3] license, so we want't to use appropriate license headers. Headroom already provides templates for this license which you can use without modifications, or as starting point for your customization. Now we need to generate template file for each source code file type we have. The template must be always named as `<FILE_TYPE>.mustache`, for reference see list of [supported file types](#todo) and [supported license types](#todo).

```shell
cd project/
mkdir templates/
cd templates/

headroom gen -l bsd3:css >./css.mustache
headroom gen -l bsd3:html >./html.mustache
headroom gen -l bsd3:scala >./scala.mustache
```

Now the project structure should be following:

```
project/
  ├── src/
  │   ├── scala/
  │   │   ├── Foo.scala
  │   │   └── Bar.scala
  │   └── html/
  │       └── template1.html
  └── templates/
      ├── css.mustache
      ├── html.mustache
      └── scala.mustache
```

### 3.2. Adding Headroom Configuration
Now we need to add configuration file where we specify path to source code files, template files and define values for placeholders in templates. The configuration file should be placed in project root directory and should be named `.headroom.yaml`, so Headroom can locate it:

```
cd project/
headroom gen -c >./.headroom.yaml
```

The project structure should now be following:

```
project/
  ├── src/
  │   ├── scala/
  │   │   ├── Foo.scala
  │   │   └── Bar.scala
  │   └── html/
  │       └── template1.html
  ├── templates/
  │   ├── css.mustache
  │   ├── html.mustache
  │   └── scala.mustache
  └── .headroom.yaml
```

Let's now edit configuration file to match our project:

```yaml
## This is the configuration file for Headroom.
## See https://github.com/vaclavsvejcar/headroom for more details.

## Version of this config files (shouldn't be necessary to change).
config-version: 1

## Defines the behaviour how to handle license headers, possible options are:
##   - add     = (default) adds license header to files with no existing header
##   - drop    = drops existing license header from without replacement
##   - replace = adds or replaces existing license header
run-mode: add

## Paths to source code files (either files or directories).
source-paths:
    - src

## Paths to template files (either files or directories).
template-paths:
    - templates

## Placeholders (key-value) to replace in templates.
placeholders:
    author: John Smith
    year: "2019"
```

### 3.3. Running Headroom
Now we're ready to run Headroom:

```shell
cd project/
headroom run      # adds license headers to source code files
headroom run -r   # adds or replaces existing license headers
headroom run -d   # drops existing license headers from files
```

## 4. Command Line Interface Overview
Headroom provides various commands for different use cases. You can check commands overview by performing following command:

```
$ headroom --help
headroom v0.1.0.0 :: https://github.com/vaclavsvejcar/headroom

Usage: headroom COMMAND
  manage your source code license headers

Available options:
  -h,--help                Show this help text

Available commands:
  run                      add or replace source code headers
  gen                      generate stub configuration and template files
```

### 4.1. Run Command
Run command is used to manipulate (add, replace or drop) license headers in source code files. You can display available options by running following command:

```
$ headroom run --help
Usage: headroom run [-s|--source-path PATH] [-t|--template-path PATH]
                    [-p|--placeholders KEY=VALUE] ([-r|--replace-headers] |
                    [-d|--drop-headers]) [--debug]
  add or replace source code headers

Available options:
  -s,--source-path PATH    path to source code file/directory
  -t,--template-path PATH  path to header template file/directory
  -p,--placeholders KEY=VALUE
                           placeholder to replace in templates
  -r,--replace-headers     force replace existing license headers
  -d,--drop-headers        drop existing license headers only
  --debug                  produce more verbose output
  -h,--help                Show this help text
```

Note that command line options overrides options set in the configuration _YAML_ file. Relation between command line options and _YAML_ configuration options is below:

| YAML option         | Command Line Option       |
|---------------------|---------------------------|
| `run-mode: add`     | _(default mode)_          |
| `run-mode: drop`    | `-d`, `--drop-headers`    |
| `run-mode: replace` | `-r`, `--replace-headers` |
| `source-paths`      | `-s`, `--source-path`     |
| `template-paths`    | `-t`, `--template-path`   |


### 4.2. Generator Command
Generator command is used to generate stubs for license header template and _YAML_ configuration file. You can display available options by running following command:

```
$ headroom gen --help
Usage: headroom gen [-c|--config-file] [-l|--license name:type]
  generate stub configuration and template files

Available options:
  -c,--config-file         generate stub YAML config file to stdout
  -l,--license name:type   generate template for license and file type
  -h,--help                Show this help text
```

When using the `-l,--license` option, you need to select the _license type_ and _file type_ from the list of supported ones listed bellow. For example to generate template for _Apache 2.0_ license and _Haskell_ file type, you need to use the `headroom gen -l apache2:haskell`.

#### 4.2.1. Supported License Types
Below is the list of supported _open source_ license types. If you miss support for license you use, feel free to [open new issue][meta:new-issue].

| License        | Used Name |
|----------------|-----------|
| _Apache 2.0_   | `apache2` |
| _BSD 3-Clause_ | `bsd3`    |
| _GPLv2_        | `gpl2`    |
| _GPLv3_        | `gpl3`    |
| _MIT_          | `mit`     |

#### 4.2.2. Supported File Types
Below is the list of supported source code file types. If you miss support for programming language you use, feel free to [open new issue][meta:new-issue].

| Language     | Used Name | Supported Extensions |
|--------------|-----------|----------------------|
| _CSS_        | `css`     | `.css`               |
| _Haskell_    | `haskell` | `.hs`                |
| _HTML_       | `html`    | `.html`, `.htm`      |
| _Java_       | `java`    | `.java`              |
| _JavaScript_ | `js`      | `.js`                |
| _Scala_      | `scala`   | `.scala`             |


[meta:new-issue]: https://github.com/vaclavsvejcar/headroom/issues/new
[web:bsd-3]: https://opensource.org/licenses/BSD-3-Clause
[web:haskell]: https://haskell.org
[web:mustache]: https://mustache.github.io
[web:stack]: https://www.haskellstack.org
[wiki:yaml]: https://en.wikipedia.org/wiki/YAML
