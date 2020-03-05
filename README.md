<p align="center"><img src ="https://github.com/vaclavsvejcar/headroom/blob/master/doc/assets/logo.png?raw=true" width="200" /></p>

[![Build Status](https://travis-ci.com/vaclavsvejcar/headroom.svg?branch=master)](https://travis-ci.com/vaclavsvejcar/headroom)

So you are tired of managing license headers in your codebase by hand? Then __Headroom__ is the right tool for you! Now you can define your license header as [Mustache][web:mustache] template, put all the variables (such as author's name, year, etc.) into the [YAML][wiki:yaml] config file and Headroom will take care to add such license headers to all your source code files.

<p align="center"><img src ="https://github.com/vaclavsvejcar/headroom/blob/master/doc/assets/demo.gif?raw=true" /></p>

__Table of Contents__
<!-- TOC -->

- [1. Main Features](#1-main-features)
- [2. Planned Features](#2-planned-features)
- [3. Installation](#3-installation)
    - [3.1. From Source Code](#31-from-source-code)
        - [3.1.1. Using Cabal](#311-using-cabal)
        - [3.1.2. Using Stack](#312-using-stack)
- [4. Case Example](#4-case-example)
    - [4.1. Adding License Header Templates](#41-adding-license-header-templates)
    - [4.2. Adding Headroom Configuration](#42-adding-headroom-configuration)
    - [4.3. Running Headroom](#43-running-headroom)
- [5. Command Line Interface Overview](#5-command-line-interface-overview)
    - [5.1. Run Command](#51-run-command)
    - [5.2. Generator Command](#52-generator-command)
        - [5.2.1. Supported License Types](#521-supported-license-types)
        - [5.2.2. Supported File Types](#522-supported-file-types)

<!-- /TOC -->

## 1. Main Features
- __License Header Management__ - allows to add, replace or drop license headers in source code files.
- __License Header Autodetection__ - you can even replace or drop license headers that weren't generated by Headroom, as they are automatically detected from source code files, not from template files.
- __Template Generator__ - generates license header templates for most popular _open source_ licenses. You can use these as-is, customize them or ignore them and use your custom templates.

## 2. Planned Features
- [[#24]][i24] __Init Command__ - automates initial Headroom setup for your project (generates config files, detects source code file types and generates license template stubs for them)
- __Binary Distribution__ - pre-built binaries will be generated for each release for major OS platforms

## 3. Installation
> Binary distribution, pre-built packages and installation from Stackage will be available soon.

### 3.1. From Source Code
Headroom is written in [Haskell][web:haskell], so you can install it from source code either using [Cabal][web:cabal] or [Stack][web:stack].

#### 3.1.1. Using Cabal
1. install [Cabal][web:cabal] for your platform
1. run `cabal install headroom`
1. add `$HOME/.cabal/bin` to your `$PATH`

#### 3.1.2. Using Stack
1. install [Stack][web:stack] for your platform
1. clone this repository
1. run `stack install` inside the `headroom/` directory
1. add `$HOME/.local/bin` to your `$PATH`

## 4. Case Example
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

### 4.1. Adding License Header Templates
Let's say our project is licensed under the [3-Clause BSD License][web:bsd-3] license, so we want to use appropriate license headers. Headroom already provides templates for this license which you can use without modifications, or as starting point for your customization. Now we need to generate template file for each source code file type we have. The template must be always named as `<FILE_TYPE>.mustache`, for reference see list of [supported file types](#422-supported-file-types) and [supported license types](#421-supported-license-types).

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

### 4.2. Adding Headroom Configuration
Now we need to add configuration file where we specify path to source code files, template files and define values for variables in templates. The configuration file should be placed in project root directory and should be named `.headroom.yaml`, so Headroom can locate it:

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

## Variables (key-value) to replace in templates.
variables:
    author: John Smith
    year: "2019"
```

### 4.3. Running Headroom
Now we're ready to run Headroom:

```shell
cd project/
headroom run      # adds license headers to source code files
headroom run -r   # adds or replaces existing license headers
headroom run -d   # drops existing license headers from files
```

## 5. Command Line Interface Overview
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

### 5.1. Run Command
Run command is used to manipulate (add, replace or drop) license headers in source code files. You can display available options by running following command:

```
$ headroom run --help
Usage: headroom run [-s|--source-path PATH] [-t|--template-path PATH]
                    [-v|--variable KEY=VALUE] ([-r|--replace-headers] |
                    [-d|--drop-headers]) [--debug]
  add or replace source code headers

Available options:
  -s,--source-path PATH    path to source code file/directory
  -t,--template-path PATH  path to header template file/directory
  -v,--variable KEY=VALUE
                           values for template variables
  -r,--replace-headers     force replace existing license headers
  -d,--drop-headers        drop existing license headers only
  --debug                  produce more verbose output
  -h,--help                Show this help text
```

Note that command line options override options set in the configuration _YAML_ file. Relation between command line options and _YAML_ configuration options is below:

| YAML option         | Command Line Option       |
|---------------------|---------------------------|
| `run-mode: add`     | _(default mode)_          |
| `run-mode: drop`    | `-d`, `--drop-headers`    |
| `run-mode: replace` | `-r`, `--replace-headers` |
| `source-paths`      | `-s`, `--source-path`     |
| `template-paths`    | `-t`, `--template-path`   |


### 5.2. Generator Command
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

#### 5.2.1. Supported License Types
Below is the list of supported _open source_ license types. If you miss support for license you use, feel free to [open new issue][meta:new-issue].

| License        | Used Name |
|----------------|-----------|
| _Apache 2.0_   | `apache2` |
| _BSD 3-Clause_ | `bsd3`    |
| _GPLv2_        | `gpl2`    |
| _GPLv3_        | `gpl3`    |
| _MIT_          | `mit`     |

#### 5.2.2. Supported File Types
Below is the list of supported source code file types. If you miss support for programming language you use, feel free to [open new issue][meta:new-issue].

| Language     | Used Name | Supported Extensions |
|--------------|-----------|----------------------|
| _CSS_        | `css`     | `.css`               |
| _Haskell_    | `haskell` | `.hs`                |
| _HTML_       | `html`    | `.html`, `.htm`      |
| _Java_       | `java`    | `.java`              |
| _JavaScript_ | `js`      | `.js`                |
| _Scala_      | `scala`   | `.scala`             |


[i24]: https://github.com/vaclavsvejcar/headroom/issues/24
[meta:new-issue]: https://github.com/vaclavsvejcar/headroom/issues/new
[web:bsd-3]: https://opensource.org/licenses/BSD-3-Clause
[web:cabal]: https://www.haskell.org/cabal/
[web:haskell]: https://haskell.org
[web:mustache]: https://mustache.github.io
[web:stack]: https://www.haskellstack.org
[wiki:yaml]: https://en.wikipedia.org/wiki/YAML
