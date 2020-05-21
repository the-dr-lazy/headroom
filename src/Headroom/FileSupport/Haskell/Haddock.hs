{-# LANGUAGE DeriveFunctor     #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}

{-|
Module      : Headroom.FileSupport.Haskell.Haddock
Description : Extraction of /Haddock module header/ fields
Copyright   : (c) 2019-2020 Vaclav Svejcar
License     : BSD-3-Clause
Maintainer  : vaclav.svejcar@gmail.com
Stability   : experimental
Portability : POSIX

This module provides support for extracting selected fields from the
/Haddock module header/ part of the /Haskell/ source code file.
-}

module Headroom.FileSupport.Haskell.Haddock
  ( HaddockModuleHeader(..)
  , extractModuleHeader
  , stripCommentSyntax
  )
where

import           Control.Applicative            ( Alternative(..) )
import           Control.Monad                  ( ap )
import           Headroom.Regex                 ( re' )
import           RIO
import qualified RIO.Char                      as C
import qualified RIO.Text                      as T
import           Text.Regex.PCRE.Heavy          ( gsub )


-- | Extracted fields from the /Haddock module header/.
data HaddockModuleHeader = HaddockModuleHeader
  { hmhShortDesc :: !(Maybe Text)
  -- ^ module short description (content of the @Description@ field)
  , hmhLongDesc  :: !(Maybe Text)
  -- ^ module long description (the text after module header fields)
  }
  deriving (Eq, Show)

-- | Extracts metadata from given /Haddock/ module header.
extractModuleHeader :: Text
                    -- ^ text containing /Haddock/ module header
                    -> HaddockModuleHeader
                    -- ^ extracted metadata
extractModuleHeader text =
  let hmhShortDesc = extractField "Description"
      hmhLongDesc  = if null rest' then Nothing else process rest'
  in  HaddockModuleHeader { .. }
 where
  (fields', rest') = fromMaybe ([], input) $ runP fields input
  input            = T.unpack . stripCommentSyntax $ text
  extractField name = fmap (T.strip . T.pack) (lookup name fields')
  process = Just . T.strip . T.pack


-- | Strips /Haskell/ comment syntax tokens (e.g. @{-@, @-}@) from input text.
--
-- >>> stripCommentSyntax "{- foo -}\nbar\n"
-- "foo \nbar\n"
stripCommentSyntax :: Text
                   -- ^ input text to strip
                   -> Text
                   -- ^ resulting text without comment syntax tokens
stripCommentSyntax text = T.unlines $ go (T.lines text) []
 where
  regex = [re'|^(-- \||-{2,})|^\h*({-\h?\|?)|(-})\h*$|]
  strip = gsub regex ("" :: Text)
  go []       acc = reverse acc
  go (x : xs) acc = go xs (strip x : acc)


--------------------------------------------------------------------------------
-- Below code is slightly modified version of code copied from:
-- https://github.com/haskell/haddock/blob/ghc-8.10/haddock-api/src/Haddock/Interface/ParseModuleHeader.hs
-------------------------------------------------------------------------------
-- Small parser to parse module header.
-------------------------------------------------------------------------------

-- The below is a small parser framework how we read keys.
--
-- all fields in the header are optional and have the form
--
-- [spaces1][field name][spaces] ":"
--    [text]"\n" ([spaces2][space][text]"\n" | [spaces]"\n")*
-- where each [spaces2] should have [spaces1] as a prefix.
--
-- Thus for the key "Description",
--
-- > Description : this is a
-- >    rather long
-- >
-- >    description
-- >
-- > The module comment starts here
--
-- the value will be "this is a .. description" and the rest will begin
-- at "The module comment".

-- 'C' is a 'Char' carrying its column.
--
-- This let us make an indentation-aware parser, as we know current indentation.
-- by looking at the next character in the stream ('curInd').
--
-- Thus we can munch all spaces but only not-spaces which are indented.
--
data C = C {-# UNPACK #-} !Int Char

newtype P a = P { unP :: [C] -> Maybe ([C], a) }
  deriving Functor

instance Applicative P where
  pure x = P $ \s -> Just (s, x)
  (<*>) = ap

instance Monad P where
  return = pure
  m >>= k = P $ \s0 -> do
    (s1, x) <- unP m s0
    unP (k x) s1

instance Alternative P where
  empty = P $ const Nothing
  a <|> b = P $ \s -> unP a s <|> unP b s

runP :: P a -> String -> Maybe a
runP p input = fmap snd (unP p input')
 where
  input' =
    concat [ zipWith C [0 ..] l ++ [C (length l) '\n'] | l <- lines input ]

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

curInd :: P Int
curInd = P $ \s -> Just . (,) s $ case s of
  []        -> 0
  C i _ : _ -> i

rest :: P String
rest = P $ \cs -> Just ([], [ c | C _ c <- cs ])

munch :: (Int -> Char -> Bool) -> P String
munch p = P $ \cs -> let (xs, ys) = takeWhileMaybe p' cs in Just (ys, xs)
 where
  p' (C i c) | p i c     = Just c
             | otherwise = Nothing

munch1 :: (Int -> Char -> Bool) -> P String
munch1 p = P $ \case
  [] -> Nothing
  (c : cs)
    | Just c' <- p' c
    -> let (xs, ys) = takeWhileMaybe p' cs in Just (ys, c' : xs)
    | otherwise
    -> Nothing
 where
  p' (C i c) | p i c     = Just c
             | otherwise = Nothing

char :: Char -> P Char
char c = P $ \case
  [] -> Nothing
  (C _ c' : cs) | c == c'   -> Just (cs, c)
                | otherwise -> Nothing

skipSpaces :: P ()
skipSpaces = P $ \cs -> Just (dropWhile (\(C _ c) -> C.isSpace c) cs, ())

takeWhileMaybe :: (a -> Maybe b) -> [a] -> ([b], [a])
takeWhileMaybe f = go where
  go xs0@[]       = ([], xs0)
  go xs0@(x : xs) = case f x of
    Just y  -> let (ys, zs) = go xs in (y : ys, zs)
    Nothing -> ([], xs0)

-------------------------------------------------------------------------------
-- Fields
-------------------------------------------------------------------------------

field :: Int -> P (String, String)
field i = do
  fn <- munch1 $ \_ c -> C.isAlpha c || c == '-'
  skipSpaces
  _ <- char ':'
  skipSpaces
  val <- munch $ \j c -> C.isSpace c || j > i
  return (fn, val)

fields :: P ([(String, String)], String)
fields = do
  skipSpaces
  i  <- curInd
  fs <- many (field i)
  r  <- rest
  return (fs, r)