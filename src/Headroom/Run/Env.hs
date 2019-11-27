{-# LANGUAGE NoImplicitPrelude #-}
module Headroom.Run.Env
  ( RunOptions(..)
  , StartupEnv(..)
  , Env(..)
  , HasRunOptions(..)
  , toAppConfig
  )
where

import           Data.Default                   ( def )
import           Headroom.Types                 ( AppConfig(..) )
import           RIO

data RunOptions =
    RunOptions { replaceHeaders :: Bool
               , sourcePaths :: [FilePath]
               , templatePaths :: [FilePath]
               } deriving (Eq, Show)

data StartupEnv =
    StartupEnv { envLogFunc :: !LogFunc
               , envRunOptions :: !RunOptions
               }

data Env =
    Env { envEnv :: !StartupEnv
        , envAppConfig :: !AppConfig}

class (HasLogFunc env, HasRunOptions env) => HasEnv env where
    envL :: Lens' env StartupEnv

class HasRunOptions env where
    runOptionsL :: Lens' env RunOptions

instance HasEnv StartupEnv where
  envL = id

instance HasEnv Env where
  envL = lens envEnv (\x y -> x { envEnv = y })

instance HasLogFunc StartupEnv where
  logFuncL = lens envLogFunc (\x y -> x { envLogFunc = y })

instance HasLogFunc Env where
  logFuncL = envL . logFuncL

instance HasRunOptions StartupEnv where
  runOptionsL = lens envRunOptions (\x y -> x { envRunOptions = y })

instance HasRunOptions Env where
  runOptionsL = envL . runOptionsL

toAppConfig :: RunOptions -> AppConfig
toAppConfig opts = def { acSourcePaths    = sourcePaths opts
                       , acTemplatePaths  = templatePaths opts
                       , acReplaceHeaders = replaceHeaders opts
                       }