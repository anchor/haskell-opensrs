{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Data.OpenSRS.Types.Common where

import Data.String.Utils
import Data.Time

--------------------------------------------------------------------------------
-- | Converts strings to UTCTime
toUTC :: Maybe String -> Maybe UTCTime
toUTC Nothing = Nothing
toUTC (Just ds) = toUTC' ds

toUTC' :: String -> Maybe UTCTime
toUTC' ds = maybeRead ds

type DomainName = String