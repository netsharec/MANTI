{-# OPTIONS_GHC -Wall -fno-warn-unused-do-bind #-}
module Parser
  ( term
  , query
  , rule
  ) where

import Text.Parsec
import Text.Parsec.String

import Control.Applicative ((<*), (<$>), (<*>))

import Types

-- Helpers
-- -------------------------------------------------------------------

spStr :: String -> Parser String
spStr s = string s <* spaces

spChar :: Char -> Parser Char
spChar c = char c <* spaces

atomRest :: Parser String
atomRest = many $ oneOf $ concat [ ['a'..'z'], ['0'..'9'], "-_'" ]

parens :: Parser a -> Parser a
parens p = do
    spChar '('
    ret <- p
    spChar ')'
    return ret

listOf :: Parser a -> Parser [a]
listOf p = sepBy1 (p <* spaces) (spChar ',')

-- -------------------------------------------------------------------

atom :: Parser Atom
atom = do
    f <- oneOf ['a'..'z']
    r <- atomRest
    spaces
    return $ Atom (f:r)

var :: Parser Var
var = do
    f <- oneOf ['A'..'Z']
    r <- atomRest
    spaces
    return $ Var (f:r)

compound :: Parser Compound
compound = do
    functor <- atom
    spaces
    terms <- parens $ listOf term
    return $ Compound functor terms

query :: Parser Query
query = Query <$> (compound <* spChar '?')

rule :: Parser Rule
rule = Rule <$> rhead <*> rbody
  where
    rhead :: Parser RHead
    rhead = do
        name <- atom
        terms <- parens $ listOf term
        return $ RHead name terms

    rbody :: Parser RBody
    rbody = do
        isFact <- optionMaybe (spChar '.')
        clauses <- case isFact of
                     Just _  -> return [Compound (Atom "true") []]
                     Nothing -> spStr ":-" >> (listOf compound <* spChar '.')
        return (RBody clauses)

term :: Parser Term
term = choice
    [ TAtom <$> try atom
    , TVar <$> try var
    , TComp <$> compound
    ]
