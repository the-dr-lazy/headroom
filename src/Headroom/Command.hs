{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications  #-}

{-|
Module      : Headroom.Command
Description : Support for parsing command line arguments
Copyright   : (c) 2019-2020 Vaclav Svejcar
License     : BSD-3-Clause
Maintainer  : vaclav.svejcar@gmail.com
Stability   : experimental
Portability : POSIX

This module contains code responsible for parsing command line arguments, using
the /optparse-applicative/ library.
-}

module Headroom.Command
  ( commandParser
  )
where

import           Headroom.Command.Readers       ( licenseReader
                                                , licenseTypeReader
                                                , regexReader
                                                )
import           Headroom.Command.Types         ( Command(..) )
import           Headroom.Configuration.Types   ( LicenseType
                                                , RunMode(..)
                                                , TemplateSource(..)
                                                )
import           Headroom.Data.EnumExtra        ( EnumExtra(..) )
import           Headroom.Meta                  ( productDesc
                                                , productInfo
                                                )
import           Options.Applicative
import           RIO
import qualified RIO.Text                      as T


-- | Parses command line arguments.
commandParser :: ParserInfo Command
commandParser = info
  (commands <**> helper)
  (fullDesc <> progDesc (T.unpack productDesc) <> header (T.unpack productInfo))
 where
  commands   = subparser (runCommand <> genCommand <> initCommand)
  runCommand = command
    "run"
    (info (runOptions <**> helper)
          (progDesc "add, replace, drop or check source code headers")
    )
  genCommand = command
    "gen"
    (info (genOptions <**> helper)
          (progDesc "generate stub configuration and template files")
    )
  initCommand = command
    "init"
    (info (initOptions <**> helper)
          (progDesc "initialize current project for Headroom")
    )

runOptions :: Parser Command
runOptions =
  Run
    <$> many
          (strOption
            (long "source-path" <> short 's' <> metavar "PATH" <> help
              "path to source code file/directory"
            )
          )
    <*> many
          (option
            regexReader
            (long "excluded-path" <> short 'e' <> metavar "REGEX" <> help
              "path to exclude from source code file paths"
            )
          )
    <*> optional
          (   BuiltInTemplates
          <$> option
                licenseTypeReader
                (long "builtin-templates" <> metavar "TYPE" <> help
                  ("use built-in templates for license type, available options: "
                  <> T.unpack (T.toLower (allValuesToText @LicenseType))
                  )
                )
          <|> TemplateFiles
          <$> some
                (strOption
                  (long "template-path" <> short 't' <> metavar "PATH" <> help
                    "path to license template file/directory"
                  )
                )
          )
    <*> many
          (strOption
            (long "variable" <> short 'v' <> metavar "KEY=VALUE" <> help
              "value for template variable"
            )
          )
    <*> optional
          (   flag'
              Add
              (long "add-headers" <> short 'a' <> help
                "only adds missing license headers"
              )
          <|> flag'
                Check
                (long "check-headers" <> short 'c' <> help
                  "check whether existing headers are up-to-date"
                )
          <|> flag'
                Replace
                (long "replace-headers" <> short 'r' <> help
                  "force replace existing license headers"
                )
          <|> flag'
                Drop
                (long "drop-headers" <> short 'd' <> help
                  "drop existing license headers only"
                )
          )
    <*> switch (long "debug" <> help "produce more verbose output")
    <*> switch (long "dry-run" <> help "execute dry run (no changes to files)")

genOptions :: Parser Command
genOptions =
  Gen
    <$> switch
          (long "config-file" <> short 'c' <> help
            "generate stub YAML config file to stdout"
          )
    <*> optional
          (option
            licenseReader
            (  long "license"
            <> short 'l'
            <> metavar "licenseType:fileType"
            <> help "generate template for license and file type"
            )
          )

initOptions :: Parser Command
initOptions =
  Init
    <$> option
          licenseTypeReader
          (long "license-type" <> short 'l' <> metavar "TYPE" <> help
            (  "type of open source license, available options: "
            <> T.unpack (T.toLower (allValuesToText @LicenseType))
            )
          )
    <*> some
          (strOption
            (long "source-path" <> short 's' <> metavar "PATH" <> help
              "path to source code file/directory"
            )
          )
