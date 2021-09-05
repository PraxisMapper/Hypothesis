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

function convertColor(colorString)
   --colors are #AARRGGBB
   local alphaHex = tonumber('0x' .. colorString:sub(2,3))
   local redHex = tonumber('0x' .. colorString:sub(4,5))
   local greenHex = tonumber('0x' .. colorString:sub(6,7))
   local blueHex = tonumber('0x' .. colorString:sub(8,9))
   
   return {redHex / 255, greenHex / 255, blueHex / 255, alphaHex / 255}
end