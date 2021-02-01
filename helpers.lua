local sockets = require("socket")

--debugging helper function
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 --Split a string, since there's no built in split in lua.
 function Split(s, delimiter)
   result = {};
   for match in (s..delimiter):gmatch("(.-)"..delimiter) do
       table.insert(result, match);
   end
   return result;
end

--Math helper, for function below
function ToRadians(degrees)
   return degrees * (math.pi / 180)
end

--a distance calculation, for an earlier attempt at calculating distance. Currently called in main.lua somewhere.
function CalcDistance(event1, event2)
   local dlon = ToRadians(event2.longitude) - ToRadians(event1.longitude)
   local dlat = ToRadians(event2.latitude) - ToRadians(event1.latitude)--Haversine formula
   local dlat2 = ToRadians(event2.latitude) + ToRadians(event1.latitude) --equirectangluar formula
   
   --this is the Haversine formula, more accurate, but I dont think people are correctly documenting Order of Operations
   local p1 = (math.sin(dlat / 2) ^ 2) 
   local p2 = math.cos(ToRadians(event1.latitude)) * math.cos(ToRadians(event2.latitude)) 
   local p3 = (math.sin(dlon / 2) ^ 2)

   --this is the equirectangluar formula. Sufficiently accurate at tiny distance.
    --local x = (dlon ^ 2) * math.cos(dlat2 * .5)
    --local y = dlat
    local radiusEarth = 6371000 --meters, remove 0s for km.
    --local distance = radiusEarth * math.sqrt((x*2) + (y^2))

   local ansRadians = math.asin(math.sqrt(p1 + p2 * p3))
   local ansMeters = ansRadians * radiusEarth

   return ansMeters
end

function doesFileExist( fname, path )
    local results = false
   -- Path for the file
   local filePath = system.pathForFile( fname, path )
   if ( filePath ) then
       local file, errorString = io.open( filePath, "r" )
       if not file then
           -- doesnt exist or an error locked it out
       else
           -- File exists!
           results = true
           -- Close the file handle
           file:close()
       end
   end
   return results
end

--not a real sleep function but close enough?
function sleep(sec)
   sockets.select(nil, nil, sec)
end