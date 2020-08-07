--TODO:
--set up a one-time 'you are cool' purchase that makes the game say you are cool on startup.
--set up a repeatble 'buy dev a coffee' purchase.
--remember google needs to consume a purchase to reset it as available again.
--do all the google logic first, then figure out how to handle apple purchases later.
--I need a product identifier, 

--these need to come from google.
local coffeePurchaseID = "coffee_purchase"
local goodPersonPurchaseID = "good_person"

local store
 
local targetAppStore = system.getInfo( "targetAppStore" )
 
if ( "apple" == targetAppStore ) then  -- iOS
    store = require( "store" )
elseif ( "google" == targetAppStore ) then  -- Android
    store = require( "plugin.google.iap.v3" )
elseif ( "amazon" == targetAppStore ) then  -- Amazon
    store = require( "plugin.amazon.iap" )
else
    print( "In-app purchases are not available for this platform." )
end

local function transactionListener( event )
    local transaction = event.transaction
 
    if ( transaction.isError ) then
        print( transaction.errorType )
        print( transaction.errorString )
    else
        -- No errors; proceed
        --google check
        if (event.name == "init") then
            --not a purchase but we might want to do some pre-processing
        else if (event.name == "storeTransaction") then
            --is a purchase
        end
    end
end
end

store.init(transactionListener)



