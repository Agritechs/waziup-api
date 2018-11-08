{-# LANGUAGE OverloadedStrings #-}

module Main where

import Network.Wai.Handler.Warp
import Waziup.API
import System.Log.Logger
import System.Log.Formatter
import System.Log.Handler hiding (setLevel)
import System.Log.Handler.Simple
import System.Log.Handler.Log4jXML
import System.IO
import System.FilePath  

main :: IO ()
main = do
  startLog "Waziup-log.xml"
  infoM "Main" "Running on http://localhost:8081"
  run 8081 waziupServer

startLog :: FilePath -> IO ()
startLog fp = do
   stdoutHandler <- do
        lh <- streamHandler stdout DEBUG
        return $ setFormatter lh (simpleLogFormatter "[$time : $loggername : $prio] $msg")
   log4jHandler <- log4jFileHandler fp DEBUG
   updateGlobalLogger rootLoggerName removeHandler
   updateGlobalLogger rootLoggerName (addHandler stdoutHandler)
   updateGlobalLogger rootLoggerName (addHandler log4jHandler)
   updateGlobalLogger rootLoggerName (setLevel DEBUG)
