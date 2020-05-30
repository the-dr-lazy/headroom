{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Headroom.Data.TextExtraSpec
  ( spec
  )
where

import           Headroom.Data.TextExtra
import           RIO
import qualified RIO.Text                      as T
import           Test.Hspec


spec :: Spec
spec = do
  describe "mapLines" $ do
    it "should return same output for identity function" $ do
      let sample = T.unlines ["foo zz", "bar", "xx"]
      mapLines id sample `shouldBe` sample

    it "should map all lines using the function" $ do
      let sample   = T.unlines ["foo zz", "bar", "xx"]
          fn       = ("L: " <>)
          expected = T.unlines ["L: foo zz", "L: bar", "L: xx"]
      mapLines fn sample `shouldBe` expected