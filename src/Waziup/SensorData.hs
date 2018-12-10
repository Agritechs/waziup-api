{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Waziup.SensorData where

import           Waziup.Types
import           Waziup.Utils
import           Waziup.Devices hiding (info, warn, debug, err)
import           Control.Monad.Except (throwError)
import           Control.Monad.IO.Class
import           Control.Monad.Catch as C
import           Data.Maybe
import           Data.Text hiding (map, filter, foldl, any, find)
import           Data.String.Conversions
import qualified Data.List as L
import           Data.Aeson as JSON
import           Data.AesonBson
import           Servant
import           Keycloak as KC hiding (info, warn, debug, err, Scope) 
import           Orion as O hiding (info, warn, debug, err)
import           System.Log.Logger
import           Database.MongoDB as DB hiding (value)


getDatapoints :: Maybe Token -> DeviceId -> SensorId -> Waziup [Datapoint]
getDatapoints tok did sid = do
  info "Get datapoints"
  withKCId did $ \(keyId, _) -> do
    debug "Check permissions"
    runKeycloak $ checkPermission keyId (pack $ show DevicesDataView) tok
    debug "Permission granted, returning datapoints"
    runMongo $ getDatapointsMongo did sid

getDatapointsMongo :: DeviceId -> SensorId -> Action IO [Datapoint]
getDatapointsMongo did mid = do
  docs <- rest =<< find (select [] "waziup_history")
  let res = sequence $ map (fromJSON . Object . aesonify) docs
  case res of
    JSON.Success a -> return a
    JSON.Error _ -> return []

-- Logging
warn, info, debug, err :: (MonadIO m) => String -> m ()
debug s = liftIO $ debugM   "SensorData" s
info  s = liftIO $ infoM    "SensorData" s
warn  s = liftIO $ warningM "SensorData" s
err   s = liftIO $ errorM   "SensorData" s
