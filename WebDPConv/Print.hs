-- File generated by the BNF Converter (bnfc 2.9.5).

{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
#if __GLASGOW_HASKELL__ <= 708
{-# LANGUAGE OverlappingInstances #-}
#endif

-- | Pretty-printer for WebDPConv.

module WebDPConv.Print where

import Prelude
  ( ($), (.)
  , Bool(..), (==), (<)
  , Int, Integer, Double, (+), (-), (*)
  , String, (++)
  , ShowS, showChar, showString
  , all, elem, foldr, id, map, null, replicate, shows, span
  )
import Data.Char ( Char, isSpace )
import qualified WebDPConv.Abs

-- | The top-level printing method.

printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 False (map ($ "") $ d []) ""
  where
  rend
    :: Int        -- ^ Indentation level.
    -> Bool       -- ^ Pending indentation to be output before next character?
    -> [String]
    -> ShowS
  rend i p = \case
      "["      :ts -> char '[' . rend i False ts
      "("      :ts -> char '(' . rend i False ts
      "{"      :ts -> onNewLine i     p . showChar   '{'  . new (i+1) ts
      "}" : ";":ts -> onNewLine (i-1) p . showString "};" . new (i-1) ts
      "}"      :ts -> onNewLine (i-1) p . showChar   '}'  . new (i-1) ts
      [";"]        -> char ';'
      ";"      :ts -> char ';' . new i ts
      t  : ts@(s:_) | closingOrPunctuation s
                   -> pending . showString t . rend i False ts
      t        :ts -> pending . space t      . rend i False ts
      []           -> id
    where
    -- Output character after pending indentation.
    char :: Char -> ShowS
    char c = pending . showChar c

    -- Output pending indentation.
    pending :: ShowS
    pending = if p then indent i else id

  -- Indentation (spaces) for given indentation level.
  indent :: Int -> ShowS
  indent i = replicateS (2*i) (showChar ' ')

  -- Continue rendering in new line with new indentation.
  new :: Int -> [String] -> ShowS
  new j ts = showChar '\n' . rend j True ts

  -- Make sure we are on a fresh line.
  onNewLine :: Int -> Bool -> ShowS
  onNewLine i p = (if p then id else showChar '\n') . indent i

  -- Separate given string from following text by a space (if needed).
  space :: String -> ShowS
  space t s =
    case (all isSpace t, null spc, null rest) of
      (True , _   , True ) -> []             -- remove trailing space
      (False, _   , True ) -> t              -- remove trailing space
      (False, True, False) -> t ++ ' ' : s   -- add space if none
      _                    -> t ++ s
    where
      (spc, rest) = span isSpace s

  closingOrPunctuation :: String -> Bool
  closingOrPunctuation [c] = c `elem` closerOrPunct
  closingOrPunctuation _   = False

  closerOrPunct :: String
  closerOrPunct = ")],;"

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- | The printer class does the job.

class Print a where
  prt :: Int -> a -> Doc

instance {-# OVERLAPPABLE #-} Print a => Print [a] where
  prt i = concatD . map (prt i)

instance Print Char where
  prt _ c = doc (showChar '\'' . mkEsc '\'' c . showChar '\'')

instance Print String where
  prt _ = printString

printString :: String -> Doc
printString s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q = \case
  s | s == q -> showChar '\\' . showChar s
  '\\' -> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  s -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j < i then parenth else id

instance Print Integer where
  prt _ x = doc (shows x)

instance Print Double where
  prt _ x = doc (shows x)

instance Print WebDPConv.Abs.Ident where
  prt _ (WebDPConv.Abs.Ident i) = doc $ showString i
instance Print WebDPConv.Abs.Prog where
  prt i = \case
    WebDPConv.Abs.Program querys -> prPrec i 0 (concatD [prt 0 querys])

instance Print WebDPConv.Abs.Query where
  prt i = \case
    WebDPConv.Abs.Q id_ datasetid budget querysteps -> prPrec i 0 (concatD [prt 0 id_, prt 0 datasetid, prt 0 budget, doc (showString "="), doc (showString "("), prt 0 querysteps, doc (showString ")")])

instance Print WebDPConv.Abs.DatasetId where
  prt i = \case
    WebDPConv.Abs.DId n -> prPrec i 0 (concatD [prt 0 n])

instance Print WebDPConv.Abs.Budget where
  prt i = \case
    WebDPConv.Abs.PureDP d -> prPrec i 0 (concatD [prt 0 d])
    WebDPConv.Abs.ApproxDP d1 d2 -> prPrec i 0 (concatD [prt 0 d1, prt 0 d2])

instance Print WebDPConv.Abs.StringList where
  prt i = \case
    WebDPConv.Abs.Slist strs -> prPrec i 0 (concatD [doc (showString "["), prt 0 strs, doc (showString "]")])

instance Print WebDPConv.Abs.QueryStep where
  prt i = \case
    WebDPConv.Abs.QSelect stringlist -> prPrec i 0 (concatD [doc (showString "SELECT"), prt 0 stringlist])
    WebDPConv.Abs.QRename stringlist1 stringlist2 -> prPrec i 0 (concatD [doc (showString "RENAME"), prt 0 stringlist1, doc (showString "TO"), prt 0 stringlist2])
    WebDPConv.Abs.QFilter stringlist -> prPrec i 0 (concatD [doc (showString "FILTER"), prt 0 stringlist])
    WebDPConv.Abs.QMap str columnschemas -> prPrec i 0 (concatD [doc (showString "MAP"), printString str, doc (showString "["), prt 0 columnschemas, doc (showString "]")])
    WebDPConv.Abs.QBin binmaps -> prPrec i 0 (concatD [doc (showString "BIN"), doc (showString "["), prt 0 binmaps, doc (showString "]")])
    WebDPConv.Abs.QCnt mparam -> prPrec i 0 (concatD [doc (showString "COUNT"), prt 0 mparam])
    WebDPConv.Abs.QMin mparam -> prPrec i 0 (concatD [doc (showString "MIN"), prt 0 mparam])
    WebDPConv.Abs.QMax mparam -> prPrec i 0 (concatD [doc (showString "MAX"), prt 0 mparam])
    WebDPConv.Abs.QSum mparam -> prPrec i 0 (concatD [doc (showString "SUM"), prt 0 mparam])
    WebDPConv.Abs.QMean mparam -> prPrec i 0 (concatD [doc (showString "MEAN"), prt 0 mparam])
    WebDPConv.Abs.QGroup grouprows -> prPrec i 0 (concatD [doc (showString "GROUP"), doc (showString "("), prt 0 grouprows, doc (showString ")")])

instance Print WebDPConv.Abs.GroupRow where
  prt i = \case
    WebDPConv.Abs.GroupRow str values -> prPrec i 0 (concatD [printString str, doc (showString "BY"), doc (showString "["), prt 0 values, doc (showString "]")])

instance Print WebDPConv.Abs.DataType where
  prt i = \case
    WebDPConv.Abs.BType -> prPrec i 0 (concatD [doc (showString "Bool")])
    WebDPConv.Abs.IType n1 n2 -> prPrec i 0 (concatD [doc (showString "Int"), prt 0 n1, prt 0 n2])
    WebDPConv.Abs.DType d1 d2 -> prPrec i 0 (concatD [doc (showString "Double"), prt 0 d1, prt 0 d2])
    WebDPConv.Abs.TType -> prPrec i 0 (concatD [doc (showString "Text")])
    WebDPConv.Abs.EType stringlist -> prPrec i 0 (concatD [doc (showString "Enum"), prt 0 stringlist])

instance Print WebDPConv.Abs.Value where
  prt i = \case
    WebDPConv.Abs.TVal -> prPrec i 0 (concatD [doc (showString "true")])
    WebDPConv.Abs.FVal -> prPrec i 0 (concatD [doc (showString "false")])
    WebDPConv.Abs.IVal n -> prPrec i 0 (concatD [prt 0 n])
    WebDPConv.Abs.DVal d -> prPrec i 0 (concatD [prt 0 d])
    WebDPConv.Abs.SVal str -> prPrec i 0 (concatD [printString str])

instance Print WebDPConv.Abs.MParam where
  prt i = \case
    WebDPConv.Abs.MParam str noisem budget -> prPrec i 0 (concatD [printString str, prt 0 noisem, prt 0 budget])
    WebDPConv.Abs.MParamC str -> prPrec i 0 (concatD [printString str])
    WebDPConv.Abs.MParamN noisem -> prPrec i 0 (concatD [prt 0 noisem])
    WebDPConv.Abs.MParamB budget -> prPrec i 0 (concatD [prt 0 budget])
    WebDPConv.Abs.MParamCN str noisem -> prPrec i 0 (concatD [printString str, prt 0 noisem])
    WebDPConv.Abs.MParamCB str budget -> prPrec i 0 (concatD [printString str, prt 0 budget])
    WebDPConv.Abs.MParamNB noisem budget -> prPrec i 0 (concatD [prt 0 noisem, prt 0 budget])
    WebDPConv.Abs.MParamNull -> prPrec i 0 (concatD [])

instance Print WebDPConv.Abs.NoiseM where
  prt i = \case
    WebDPConv.Abs.GMech -> prPrec i 0 (concatD [doc (showString "Gauss")])
    WebDPConv.Abs.LMech -> prPrec i 0 (concatD [doc (showString "Laplace")])

instance Print WebDPConv.Abs.BinMap where
  prt i = \case
    WebDPConv.Abs.BMap str values -> prPrec i 0 (concatD [printString str, doc (showString "["), prt 0 values, doc (showString "]")])

instance Print WebDPConv.Abs.ColumnSchema where
  prt i = \case
    WebDPConv.Abs.CScheme str datatype -> prPrec i 0 (concatD [printString str, prt 0 datatype])

instance Print [WebDPConv.Abs.QueryStep] where
  prt _ [] = concatD []
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ";"), prt 0 xs]

instance Print [String] where
  prt _ [] = concatD []
  prt _ [x] = concatD [printString x]
  prt _ (x:xs) = concatD [printString x, doc (showString ","), prt 0 xs]

instance Print [WebDPConv.Abs.ColumnSchema] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print [WebDPConv.Abs.BinMap] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print [WebDPConv.Abs.Value] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print [WebDPConv.Abs.Query] where
  prt _ [] = concatD []
  prt _ (x:xs) = concatD [prt 0 x, prt 0 xs]

instance Print [WebDPConv.Abs.GroupRow] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]
