{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use second" #-}
{-# HLINT ignore "Use bimap" #-}
{-# HLINT ignore "Use first" #-}
module Hjayson (
    Json,
    Hjayson (encodeJs),
    toJsonString,
    JsonValue
) where

import qualified Data.Map as M

data JsonValue = I Integer | D Double | S String | B Bool | J Collection deriving (Eq, Show)

data Collection = Ls [JsonValue] | Js Json deriving (Eq, Show)

type Json = M.Map String JsonValue


class Hjayson a where 
    encodeJs :: a -> JsonValue 

instance Hjayson Integer where
    encodeJs = I 

instance Hjayson Double where 
    encodeJs = D 

instance Hjayson String where 
    encodeJs = S 

instance Hjayson Bool where 
    encodeJs = B 

instance Hjayson [JsonValue] where 
    encodeJs = J . Ls 

instance Hjayson [(String, JsonValue)] where 
    encodeJs = J . Js . M.fromList 



toJsonString :: Json -> String 
toJsonString = curly . commas . map tupJson . M.toList

valJson :: JsonValue -> String 
valJson v = case v of 
    I i -> show i 
    D d -> show d 
    S s -> qt s 
    B b -> show b 
    J cs -> case cs of 
        Ls xs   -> brackets $ commas $ map valJson xs 
        Js json -> curly $ commas $ map tupJson (M.toList json)


tupJson :: (String, JsonValue) -> String 
tupJson (k, v) = qt k ++ ":" ++ valJson v

commas :: [String] -> String
commas = delimitWith ','

delimitWith :: Char -> [String] -> String 
delimitWith _ [] = []
delimitWith del ss = go del ss 
    where 
        go del [s] = s 
        go del (s:ss) = s ++ del : go del ss


enclose :: (Char, Char) -> String -> String 
enclose (l, r) s = l : s ++ [r]

qt :: String -> String
qt = enclose ('"', '"')

brackets :: String -> String
brackets = enclose ('[', ']')

curly :: String -> String
curly = enclose ('{', '}')