module Main where 

import WebDPConv.Par (myLexer, pProg)
import WebDPConv.Abs 
import System.FilePath
import System.Environment
import Compiler (compile, JsonString(J), nameWithExtension)
import System.IO
import System.Directory
import Control.Monad


type Err = Either String

main :: IO ()
main = do 
    args <- getArgs
    if null args 
        then 
            do
                error "Too few arguments were applied"
        else 
            do 
                case extract2 args of 
                    Right (programFile, outputDir) -> compileAndSave programFile outputDir
                    Left err                       -> compileAndSave (head args) "out"   
            


compileAndSave :: FilePath -> FilePath -> IO ()
compileAndSave programFile outputDir = do 
    if not $ isCorrectExtension programFile
        then error "Compiler doesn't recognize the file extension"
        else do 
            program <- readFile programFile
            case parseFile program of 
                Left err   -> error err 
                Right tree -> do 
                    case compile tree of 
                        Left err    -> error err 
                        Right jsons -> do 
                            createDirectoryIfMissing True outputDir
                            mapM_ (writeAndSaveFile outputDir) jsons 
            


writeAndSaveFile :: FilePath -> JsonString -> IO ()
writeAndSaveFile outdir j@(J name contents) = do 
    withFile (outdir ++ "/" ++ nameWithExtension j) WriteMode (\handle -> 
        do
            hPutStrLn handle contents
        )

isCorrectExtension :: FilePath -> Bool 
isCorrectExtension fp = takeExtension fp == ".iq"

parseFile :: String -> Err Prog
parseFile = pProg . myLexer

extract2 :: [a] -> Err (a, a)
extract2 (a:b:xs) = pure (a, b)
extract2  _       = Left "Not enough arguments"

