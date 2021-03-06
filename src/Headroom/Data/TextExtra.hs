{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

{-|
Module      : Headroom.Data.TextExtra
Description : Additional utilities for text manipulation
Copyright   : (c) 2019-2020 Vaclav Svejcar
License     : BSD-3-Clause
Maintainer  : vaclav.svejcar@gmail.com
Stability   : experimental
Portability : POSIX

Module containing bunch of useful functions for working with text.
-}

module Headroom.Data.TextExtra
  ( read
    -- * Working with text lines
  , mapLines
  , fromLines
  , toLines
  )
where

import           RIO
import qualified RIO.Text                      as T


-- | Maps given function over individual lines of the given text.
--
-- >>> mapLines ("T: " <>) "foo zz\nbar"
-- "T: foo zz\nT: bar"
mapLines :: (Text -> Text)
         -- ^ function to map over individual lines
         -> Text
         -- ^ input text
         -> Text
         -- ^ result text
mapLines fn = fromLines . go . toLines
 where
  go []       = []
  go (x : xs) = fn x : go xs


-- | Same as 'readMaybe', but takes 'Text' as input instead of 'String'.
--
-- >>> read "123" :: Maybe Int
-- Just 123
read :: Read a
     => Text
     -- ^ input text to parse
     -> Maybe a
     -- ^ parsed value
read = readMaybe . T.unpack


-- | Similar to 'T.unlines', but does not automatically adds @\n@ at the end
-- of the text. Advantage is that when used together with 'toLines', it doesn't
-- ocassionaly change the newlines ad the end of input text:
--
-- >>> fromLines . toLines $ "foo\nbar"
-- "foo\nbar"
--
-- >>> fromLines . toLines $ "foo\nbar\n"
-- "foo\nbar\n"
--
-- Other examples:
--
-- >>> fromLines []
-- ""
--
-- >>> fromLines ["foo"]
-- "foo"
--
-- >>> fromLines ["first", "second"]
-- "first\nsecond"
--
-- >>> fromLines ["first", "second", ""]
-- "first\nsecond\n"
fromLines :: [Text]
          -- ^ lines to join
          -> Text
          -- ^ text joined from individual lines
fromLines = T.intercalate "\n"


-- | Similar to 'T.lines', but does not drop trailing newlines from output.
-- Advantage is that when used together with 'fromLines', it doesn't ocassionaly
-- change the newlines ad the end of input text:
--
-- >>> fromLines . toLines $ "foo\nbar"
-- "foo\nbar"
--
-- >>> fromLines . toLines $ "foo\nbar\n"
-- "foo\nbar\n"
--
-- Other examples:
--
-- >>> toLines ""
-- []
--
-- >>> toLines "first\nsecond"
-- ["first","second"]
--
-- >>> toLines "first\nsecond\n"
-- ["first","second",""]
toLines :: Text
        -- ^ text to break into lines
        -> [Text]
        -- ^ lines of input text
toLines input | T.null input = []
              | otherwise    = T.split (== '\n') input
