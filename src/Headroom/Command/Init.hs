{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE LambdaCase            #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE TupleSections         #-}
{-# LANGUAGE TypeApplications      #-}

{-|
Module      : Headroom.Command.Init
Description : Handler for the @init@ command
Copyright   : (c) 2019-2020 Vaclav Svejcar
License     : BSD-3
Maintainer  : vaclav.svejcar@gmail.com
Stability   : experimental
Portability : POSIX

Module representing the @init@ command, responsible for generating all the
required files (configuration, templates) for the given project, which are then
required by the @run@ or @gen@ commands.
-}

module Headroom.Command.Init
  ( Env(..)
  , Paths(..)
  , commandInit
  , doesAppConfigExist
  , findSupportedFileTypes
  )
where

import           Headroom.Command.Utils         ( bootstrap )
import           Headroom.Configuration         ( makeHeadersConfig
                                                , parseConfiguration
                                                )
import           Headroom.Embedded              ( configFileStub
                                                , defaultConfig
                                                , licenseTemplate
                                                )
import           Headroom.FileSystem            ( createDirectory
                                                , doesFileExist
                                                , fileExtension
                                                , findFiles
                                                , getCurrentDirectory
                                                )
import           Headroom.FileType              ( fileTypeByExt )
import           Headroom.Has                   ( Has(..) )
import           Headroom.Meta                  ( TemplateType )
import           Headroom.Template              ( Template(..) )
import           Headroom.Types                 ( ApplicationError(..)
                                                , CommandInitError(..)
                                                , CommandInitOptions(..)
                                                , FileType(..)
                                                , LicenseType(..)
                                                , PartialConfiguration(..)
                                                )
import           Headroom.UI                    ( Progress(..)
                                                , zipWithProgress
                                                )
import           RIO
import qualified RIO.Char                      as C
import           RIO.FilePath                   ( (</>) )
import qualified RIO.List                      as L
import qualified RIO.NonEmpty                  as NE
import qualified RIO.Text                      as T
import qualified RIO.Text.Partial              as TP



-- | /RIO/ Environment for the @init@ command.
data Env = Env
  { envLogFunc     :: !LogFunc
  , envInitOptions :: !CommandInitOptions
  , envPaths       :: !Paths
  }

-- | Paths to various locations of file system.
data Paths = Paths
  { pCurrentDir   :: !FilePath
  , pConfigFile   :: !FilePath
  , pTemplatesDir :: !FilePath
  }

instance HasLogFunc Env where
  logFuncL = lens envLogFunc (\x y -> x { envLogFunc = y })

instance Has CommandInitOptions Env where
  hasLens = lens envInitOptions (\x y -> x { envInitOptions = y })

instance Has Paths Env where
  hasLens = lens envPaths (\x y -> x { envPaths = y })

--------------------------------------------------------------------------------

env' :: CommandInitOptions -> LogFunc -> IO Env
env' opts logFunc = do
  currentDir <- getCurrentDirectory
  let paths = Paths { pCurrentDir   = currentDir
                    , pConfigFile   = ".headroom.yaml"
                    , pTemplatesDir = "headroom-templates"
                    }
  pure $ Env { envLogFunc = logFunc, envInitOptions = opts, envPaths = paths }

-- | Handler for @init@ command.
commandInit :: CommandInitOptions -- ^ @init@ command options
            -> IO ()              -- ^ execution result
commandInit opts = bootstrap (env' opts) False $ doesAppConfigExist >>= \case
  False -> do
    fileTypes <- findSupportedFileTypes
    makeTemplatesDir
    createTemplates fileTypes
    createConfigFile
  True -> do
    paths <- viewL
    throwM $ CommandInitError (AppConfigAlreadyExists $ pConfigFile paths)

-- | Recursively scans provided source paths for known file types for which
-- templates can be generated.
findSupportedFileTypes :: (Has CommandInitOptions env, HasLogFunc env)
                       => RIO env [FileType]
findSupportedFileTypes = do
  opts           <- viewL
  pHeadersConfig <- pcLicenseHeaders <$> parseConfiguration defaultConfig
  headersConfig  <- makeHeadersConfig pHeadersConfig
  fileTypes      <- do
    allFiles <- mapM (\path -> findFiles path (const True))
                     (cioSourcePaths opts)
    let allFileTypes = fmap (fileExtension >=> fileTypeByExt headersConfig)
                            (concat allFiles)
    pure $ L.nub . catMaybes $ allFileTypes
  case fileTypes of
    [] -> throwM $ CommandInitError NoProvidedSourcePaths
    _  -> do
      logInfo $ "Found supported file types: " <> displayShow fileTypes
      pure fileTypes

createTemplates :: (Has CommandInitOptions env, HasLogFunc env, Has Paths env)
                => [FileType]
                -> RIO env ()
createTemplates fileTypes = do
  opts  <- viewL
  paths <- viewL
  let templatesDir = pCurrentDir paths </> pTemplatesDir paths
  mapM_ (\(p, lf) -> createTemplate templatesDir lf p)
        (zipWithProgress $ fmap (cioLicenseType opts, ) fileTypes)

createTemplate :: (HasLogFunc env)
               => FilePath
               -> (LicenseType, FileType)
               -> Progress
               -> RIO env ()
createTemplate templatesDir (licenseType, fileType) progress = do
  let extension = NE.head $ templateExtensions @TemplateType
      file = (fmap C.toLower . show $ fileType) <> "." <> T.unpack extension
      filePath  = templatesDir </> file
      template  = licenseTemplate licenseType fileType
  logInfo $ mconcat
    [display progress, " Creating template file in ", fromString filePath]
  writeFileUtf8 filePath template

createConfigFile :: (Has CommandInitOptions env, HasLogFunc env, Has Paths env)
                 => RIO env ()
createConfigFile = do
  opts  <- viewL
  paths <- viewL
  let filePath = pCurrentDir paths </> pConfigFile paths
  logInfo $ "Creating YAML config file in " <> fromString filePath
  writeFileUtf8 filePath (configuration opts paths)
 where
  configuration opts paths =
    let withSourcePaths = TP.replace
          "source-paths: []"
          ("source-paths: " <> toYamlList (T.pack <$> cioSourcePaths opts))
          configFileStub
        withTemplatePaths = TP.replace
          "template-paths: []"
          ("template-paths: " <> toYamlList [T.pack $ pTemplatesDir paths])
          withSourcePaths
    in  withTemplatePaths
  toYamlList items = mconcat
    ["[ ", T.intercalate ", " (fmap (\i -> "\"" <> i <> "\"") items), " ]"]

-- | Checks whether application config file already exists.
doesAppConfigExist :: (HasLogFunc env, Has Paths env) => RIO env Bool
doesAppConfigExist = do
  paths <- viewL
  logInfo "Verifying that there's no existing Headroom configuration..."
  doesFileExist $ pCurrentDir paths </> pConfigFile paths

-- | Creates directory for template files.
makeTemplatesDir :: (HasLogFunc env, Has Paths env) => RIO env ()
makeTemplatesDir = do
  paths <- viewL
  let templatesDir = pCurrentDir paths </> pTemplatesDir paths
  logInfo $ "Creating directory for templates in " <> fromString templatesDir
  createDirectory templatesDir
