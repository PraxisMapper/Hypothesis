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

 function CenterButton(button, X, Y)
   --TODO: take in button (ImageRect) size, adjust coordinates to center on screen horizontally (if X is true) or vertically (if Y is true)
 end

 function Split(s, delimiter)
   result = {};
   for match in (s..delimiter):gmatch("(.-)"..delimiter) do
       table.insert(result, match);
   end
   return result;
end

function ToRadians(degrees)
   return degrees * (math.pi / 180)
end

function CalcDistance(event1, event2)
   --native.showAlert("2", dump(event2))
   --native.showAlert("1", dump(event1))
   --if (event2.latitude == nil) then
     -- native.showAlert(dump(event2))
      --return 0
   --end

   local dlon = ToRadians(event2.longitude) - ToRadians(event1.longitude)
   local dlat = ToRadians(event2.latitude) - ToRadians(event1.latitude)--Haversine formula
   local dlat2 = ToRadians(event2.latitude) + ToRadians(event1.latitude) --equirectangluar formula
   --native.showAlert("dlat", dlat)


   --this is the Haversine formula, more accurate, but I dont think people are correctly documenting Order of Operations
   local p1 = (math.sin(dlat / 2) ^ 2) 
   local p2 = math.cos(ToRadians(event1.latitude)) * math.cos(ToRadians(event2.latitude)) 
   local p3 = (math.sin(dlon / 2) ^ 2)

   --this is the equirectangluar formula. Sufficiently accurate at tiny distance.
    local x = (dlon ^ 2) * math.cos(dlat2 * .5)
    local y = dlat
    local radiusEarth = 6371000 --meters, remove 0s for km.
    local distance = radiusEarth * math.sqrt((x*2) + (y^2))

   local ansRadians = math.asin(math.sqrt(p1 + p2 * p3))
   local ansMeters = ansRadians * radiusEarth

   return ansMeters
   --return distance
end