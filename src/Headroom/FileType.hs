{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Headroom.FileType
  ( FileType(..)
  , fileTypeByExt
  , listExtensions
  , readFileType
  )
where

import           Headroom.Types.Util            ( allValues
                                                , readEnumCI
                                                )
import           RIO
import qualified RIO.List                      as L
import qualified RIO.Text                      as T
import           Text.Read                      ( readsPrec )


data FileType = Haskell deriving (Bounded, Enum, Eq, Ord, Show)

instance Read FileType where
  readsPrec _ = readEnumCI

fileTypeByExt :: T.Text -> Maybe FileType
fileTypeByExt ext =
  L.find (elem ext . listExtensions) (allValues :: [FileType])

listExtensions :: FileType -> [T.Text]
listExtensions Haskell = ["hs"]

readFileType :: T.Text -> Maybe FileType
readFileType = readMaybe . T.unpack
