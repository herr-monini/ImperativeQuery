module Compiler (
    compile,
    nameWithExtension,
    JsonString (J),

) where
    

import WebDPConv.Abs 
import Hjayson 

import qualified Data.Map as M
import Data.Binary (encode)


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
    encodeJs m = case m of 
        MParam name noise budget -> encodeJs [("column", encodeJs name), ("mech", encodeJs noise), ("budget", encodeJs budget)]
        MParamC name -> encodeJs [("column", encodeJs name)]
        MParamN noise -> encodeJs [("mech", encodeJs noise)]
        MParamB budget -> encodeJs [("budget", encodeJs budget)]
        MParamCN name noise -> encodeJs [("column", encodeJs name), ("mech", encodeJs noise)]
        MParamCB name budget -> encodeJs [("column", encodeJs name), ("budget", encodeJs budget)]
        MParamNB noise budget -> encodeJs [("mech", encodeJs noise), ("budget", encodeJs budget)]
        MParamNull -> encodeJs Null
  

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
        SVal s -> encodeJs s

instance Hjayson NoiseM where 
    encodeJs GMech = encodeJs "Gauss"
    encodeJs LMech = encodeJs "Laplace"

instance Hjayson BinMap where
    encodeJs (BMap string vs) = encodeJs [(string, encodeJs (map encodeJs vs))]

instance Hjayson ColumnSchema where 
    encodeJs (CScheme col typ) = encodeJs [("name", encodeJs col), ("type", encodeJs typ)]


instance Hjayson QueryStep where 
    encodeJs qs = case qs of 
        QSelect (Slist ls) -> encodeJs [("select", encodeJs (map encodeJs ls))]
        QRename (Slist from) (Slist to) -> encodeJs [
            ("rename", encodeJs $ zipWith (\f t -> (f, encodeJs t)) from to)]
        QFilter (Slist fs) -> encodeJs [("filter", encodeJs (map encodeJs fs))]
        QMap f cs -> encodeJs [("map", encodeJs [("fun", encodeJs f), ("schema", encodeJs $ map encodeJs cs)])]
        QBin bs -> encodeJs [("bin", encodeJs (map (\(BMap c vs) -> (c, encodeJs $ map encodeJs vs)) bs))]
        QCnt par -> encodeJs [("count", encodeJs par)]
        QMin par -> encodeJs [("min", encodeJs par)]
        QMax par -> encodeJs [("max", encodeJs par)]
        QSum par -> encodeJs [("sum", encodeJs par)]
        QMean par -> encodeJs [("mean", encodeJs par)]
        QGroup gs -> encodeJs [("groupby", encodeJs gs)]
        


instance Hjayson [GroupRow] where 
    encodeJs gs = encodeJs (map (\(GroupRow s vs) -> (s, encodeJs $ map encodeJs vs)) gs)

instance Hjayson Null where 
    encodeJs n = encodeJs $ go n 
        where 
            go :: Null -> [(String, JsonValue)]
            go n = []

data Null = Null deriving (Eq, Show)
