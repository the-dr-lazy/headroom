{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Headroom.Header.Impl.HaskellSpec
  ( spec
  )
where

import           Headroom.Header.Impl.Haskell
import           RIO
import           Test.Hspec


spec :: Spec
spec = do
  describe "headerSizeHaskell" $ do
    it "detects size of existing module header" $ do
      source <- readFileUtf8 "test-data/code-samples/haskell/full.hs"
      headerSizeHaskell source `shouldBe` 15

    it "handles empty files" $ do
      headerSizeHaskell "" `shouldBe` 0