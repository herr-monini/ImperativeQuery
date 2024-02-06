module Compiler (
    compile,
    nameWithExtension,
    JsonString (J),

) where
    

import WebDPConv.Abs 
import Hjayson 

import qualified Data.Map as M


type Name    = String
type Payload = String

data JsonString = J Name Payload deriving (Eq, Ord, Show)


nameWithExtension :: JsonString -> String 
nameWithExtension (J n _) = n ++ ".json"

compile :: Prog -> Either String [JsonString]
compile (Program qs) = Right $ map compileQuery qs

compileQuery :: Query -> JsonString
compileQuery (Q (Ident name) (DId id) b qs) = 
    let 
        json = M.insert "dataset" (encodeJs id) (M.insert "budget" (encodeJs b) M.empty)
    in 
        J name $ toJsonString $ M.insert "query" (encodeJs (map encodeJs qs)) json

instance Hjayson DataType where 
    encodeJs dt = case dt of 
        BType     -> encodeJs [("name", encodeJs "Bool")]
        IType l r -> encodeJs [("name", encodeJs "Int"), ("low", encodeJs l), ("high", encodeJs r)]
        DType l r -> encodeJs [("name", encodeJs "Double"), ("low", encodeJs l), ("high", encodeJs r)]
        TType     -> encodeJs [("name", encodeJs "Text")]
        EType (Slist ls)  -> encodeJs [("name", encodeJs "Enum"), ("labels", encodeJs $ map encodeJs ls)]

instance Hjayson MParam where 
    encodeJs (MParam name noise budget) = encodeJs [("column", encodeJs name), ("mech", encodeJs noise), ("budget", encodeJs budget)]

instance Hjayson Budget where 
    encodeJs b = case b of 
        PureDP d -> encodeJs [("epsilon", encodeJs d)]
        ApproxDP e d -> encodeJs [("epsilon", encodeJs e), ("delta", encodeJs d)]

instance Hjayson Value where 
    encodeJs v = case v of
        TVal -> encodeJs True 
        FVal -> encodeJs False 
        IVal i -> encodeJs i 
        DVal d -> encodeJs d 

instance Hjayson NoiseM where 
    encodeJs GMech = encodeJs "Gauss"
    encodeJs LMech = encodeJs "Laplace"

instance Hjayson BinMap where
    encodeJs (BMap string vs) = encodeJs [(string, encodeJs (map encodeJs vs))]

instance Hjayson ColumnSchema where 
    encodeJs (CScheme col typ) = encodeJs [(col, encodeJs typ)]


instance Hjayson QueryStep where 
    encodeJs qs = case qs of 
        QSelect (Slist ls) -> encodeJs [("select", encodeJs (map encodeJs ls))]
        QRename (Slist from) (Slist to) -> encodeJs [
            ("rename", encodeJs $ zipWith (\f t -> (f, encodeJs t)) from to)]
        QFilter (Slist fs) -> encodeJs [("filter", encodeJs (map encodeJs fs))]
        QMap f cs -> encodeJs [("map", encodeJs [(f, encodeJs (map encodeJs cs))])]
        QBin bs -> encodeJs [("bin", encodeJs (map encodeJs bs))]
        QCnt par -> encodeJs [("count", encodeJs par)]
        QMin par -> encodeJs [("min", encodeJs par)]
        QMax par -> encodeJs [("max", encodeJs par)]
        QSum par -> encodeJs [("sum", encodeJs par)]
        QMean par -> encodeJs [("mean", encodeJs par)]

