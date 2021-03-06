{-# LANGUAGE OverloadedStrings #-}

module Text.HTML.TagSoup.Manipulators where

import Control.Lens
import Safe
import Text.HTML.TagSoup
import Text.HTML.TagSoup.Tree
import Text.StringLike (StringLike, toString)

--------------------------------------------------------------------------------
-- | Get inner text of the next tag fitting this matcher
getText :: [Tag String] -> String -> String
getText xml matcher =
    stringHead itemInnerValue $ sections (~== matcher) xml

getText' :: (Eq a, StringLike a, Show a) => [Tag a] -> String -> String
getText' xml matcher =
    stringHead itemInnerValue' $ sections (~== matcher) xml

maybeGetText :: [Tag String] -> String -> Maybe String
maybeGetText xml matcher =
    fmap itemInnerValue . headMay $ sections (~== matcher) xml

-- | Get a string out of something
stringHead :: (a -> String) -> [a] -> String
stringHead fn = maybe "" fn . headMay

itemInnerValue :: [Tag String] -> String
itemInnerValue x = case x !! 1 of
    t@(TagText _) -> fromTagText t
    _             -> ""

itemInnerValue' :: (Eq a, StringLike a, Show a) => [Tag a] -> String
itemInnerValue' x = case x !! 1 of
    t@(TagText _) -> tagIdent t
    _             -> ""

topMatching :: (Eq a, StringLike a, Show a) => String -> [TagTree a] -> [TagTree a]
topMatching matcher = (=<<) (topMatching' matcher)

matchingKids :: (Eq a, StringLike a, Show a) => String -> [TagTree a] -> [TagTree a]
matchingKids matcher = (=<<) (matchingKids' matcher)

kidsWith :: (Eq a, StringLike a, Show a) => String -> [TagTree a] -> [TagTree a]
kidsWith matcher = (=<<) (topMatching matcher) . fmap getKids

topMatching' :: (Eq a, StringLike a, Show a) => String -> TagTree a -> [TagTree a]
topMatching' matcher l@(TagLeaf _) = matchingKids' matcher l
topMatching' matcher b@(TagBranch _ _ kids) =
    case matchingKids' matcher b of
        [] -> (=<<) (topMatching' matcher) kids
        _  -> [b]

matchingKids' :: (Eq a, StringLike a, Show a) => String -> TagTree a -> [TagTree a]
matchingKids' matcher t = [ t | isMatch t matcher ]

-- | Determine if we can match this tag by full tag description or tag name
-- @TODO better matchers
isMatch :: (Eq a, StringLike a, Show a) => TagTree a -> String -> Bool
isMatch t matcher =
    currentTag t ~== matcher || (TagText $ currentTagText t) ~== TagText matcher

-- | Get Tag object (no children) for any TagTree
currentTag :: TagTree a -> Tag a
currentTag (TagLeaf t) = t
currentTag (TagBranch t a _) = head . flattenTree $ [TagBranch t a []]

-- | Get Tag identifier for any TagTree
currentTagText :: (Show a, StringLike a) => TagTree a -> String
currentTagText x = tagIdent $ currentTag x

-- | Get Attributes for any TagTree
currentTagAttr :: (Show a, StringLike a) => TagTree a -> [(String, String)]
currentTagAttr (TagLeaf _) = []
currentTagAttr (TagBranch _ a _) = fmap (bimap toString toString) a

-- | Identify any Tag
tagIdent :: (Show a, StringLike a) => Tag a -> String
tagIdent t = toString $ tagIdent' t

tagIdent' :: (Show a, StringLike a) => Tag a -> a
tagIdent' (TagOpen x _)     = x
tagIdent' (TagClose x)      = x
tagIdent' (TagText x)       = x
tagIdent' (TagComment x)    = x
tagIdent' (TagWarning x)    = x
tagIdent' (TagPosition _ _) = error "Nope"

-- | Get children of any TagTree
getKids :: TagTree a -> [TagTree a]
getKids (TagLeaf _) = []
getKids (TagBranch _ _ k) = k
