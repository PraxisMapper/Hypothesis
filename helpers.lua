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
   local dlat = ToRadians(event2.latitude) - ToRadians(event1.latitude)
   --native.showAlert("dlat", dlat)

   local p1 = (math.sin(dlat / 2) ^ 2) 
   --native.showAlert("p1", p1)
   local p2 = math.cos(ToRadians(event1.latitude)) * math.cos(ToRadians(event2.latitude)) 
   --native.showAlert("p2", p2)
   local p3 = (math.sin(dlon / 2) ^ 2)

   --native.showAlert("p3", p3)
   local ansRadians = math.asin(math.sqrt(p1 + p2 * p3))
   local ansMeters = ansRadians * 6.371

   return ansMeters
end