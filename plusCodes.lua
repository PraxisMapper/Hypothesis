
-- oh right, the 11th character level is a 5x4 ordered grid. so...
--'23456789CFGHJMPQRVWX'
-- R V W X
-- J M P Q 
-- C F G H 
-- 6 7 8 9 
-- 2 3 4 5 
--alter the last digit of the current cell to check neighbors, or 2nd to last cell if it overflows
--that only matters if I use 11-digit or more codes. At the 10 digit level its still 20x20. So, same idea, but one is X and one is Y

-- 14x14 meter precision
--CODE_PRECISION_NORMAL = 10

-- 2x3 meter precision
--CODE_PRECISION_EXTRA = 11

-- A separator used to break the code into two parts to aid memorability.
local SEPARATOR_ = '+'

-- The number of characters to place before the separator.
--local SEPARATOR_POSITION_ = 8

-- The character set used to encode the values.
CODE_ALPHABET_ = '23456789CFGHJMPQRVWX' --no longer local, so we can use it in other files

-- The resolution values in degrees for each position in the lat/lng pair
-- encoding. These give the place value of each position, and therefore the
-- dimensions of the resulting area. reference values, not actually used
--local PAIR_RESOLUTIONS_ = {20.0, 1.0, .05, .0025, .000125}

-- Number of columns in the grid refinement method.
local GRID_COLUMNS_ = 4;

-- Number of rows in the grid refinement method.
local GRID_ROWS_ = 5;

--for decoding the 11th digit?
local GRID_ROW_MULTIPLIER = 3125
local GRID_COL_MULTIPLIER = 1024

--my own pass at the algorithm. shorter, less thorough.
function encodeLatLon(latitude, longitude, codeLength)
    --if (debug) then print("encoding latlong") end
    local code = ""
    local lat = math.floor((latitude + 90) * 8000)
    local long = math.floor((longitude + 180) * 8000)
    if (codeLength == 11) then
        lat = lat * GRID_ROW_MULTIPLIER
        long = long * GRID_COL_MULTIPLIER
    end

    -- 10 most significant digits
    for i= 1, 5, 1 do
        local nextLongChar = (long % 20) + 1 
        local nextLatChar = (lat % 20) + 1

        code = CODE_ALPHABET_:sub(nextLatChar, nextLatChar) .. CODE_ALPHABET_:sub(nextLongChar, nextLongChar) .. code
        lat = math.floor(lat / 20)
        long = math.floor(long / 20)
    end

    --11th digit is from a 4x5 grid, starting with 2 in the lower-left corner and ending with X in the upper-right, increasing left-to-right and then bottom-to-top
    if (codeLength == 11) then
        local latGrid = lat % 5
        local lonGrid = long % 4
        local indexDigit = latGrid * GRID_COLUMNS_ + lonGrid
        code = code .. CODE_ALPHABET_:sub(indexDigit, indexDigit)
        return code:sub(1,8) .. SEPARATOR_ .. code:sub(9, 11);
    end 

    return code:sub(1,8) .. SEPARATOR_ .. code:sub(9, 10);
end

function shiftCell(pluscode, Shift, position)
    --take the current cell, move it some number of cells at some position. (Call this twice to do X and Y)
    --Shift should be under 20
    --position is which cell we're looking to shift, from 1 to 10. This function handles the plus sign by skipping it.

    local charPos = position
    if (position > 8) then --shift this over 1, to avoid the + in the plus code
        charPos = position + 1
    end

    local newCode = pluscode
    local currentDigit = ""
    local digitIndex = 0
    --do the shift
    if (Shift ~= 0) then

        currentDigit = pluscode:sub(charPos, charPos)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + Shift

        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
            newCode = shiftCell(newCode, -1, position - 2) 
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
            newCode = shiftCell(newCode, 1, position - 2) 
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, charPos - 1) .. currentDigit .. newCode:sub(charPos + 1, 11)
    end
    return newCode
end

function removePlus(pluscode)
    return string.gsub(pluscode, "+", "")
end