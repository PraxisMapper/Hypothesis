--TODO: 
--enhance precision to 11 or more characters if I wanted to.
--make a more universal function for adjusting plus codes. I have the logic right, i just need to apply it to each pair instead of one at a time.
--using current pluscode  level (10), each cell is approximately passing by one house. Could drop the last 2 digits, and then it's more like City Block size.

-- oh right, the +3 level is a 5x4 ordered grid. so...
--'23456789CFGHJMPQRVWX'
-- R V W X
-- J M P Q 
-- C F G H 
-- 6 7 8 9 
-- 2 3 4 5 
--whats the fastest way to dig through this? 
--alter the last digit of the current cell to check neighbors, or 2nd to last cell if it overflows
--that only matters if I use 11-digit or more codes. At the 10 digit level its still 20x20. So, same idea, but one is X and one is Y

-- 14x14 precision
--CODE_PRECISION_NORMAL = 10

-- 2x3 precision
--CODE_PRECISION_EXTRA = 11

-- A separator used to break the code into two parts to aid memorability.
local SEPARATOR_ = '+'

-- The number of characters to place before the separator.
--local SEPARATOR_POSITION_ = 8

-- The character set used to encode the values.
CODE_ALPHABET_ = '23456789CFGHJMPQRVWX' --no longer local, so we can use it in other files

-- The base to use to convert numbers to/from.
local ENCODING_BASE_ = string.len(CODE_ALPHABET_)

-- The max number of digits to process in a plus code.
local MAX_DIGIT_COUNT_ = 15

-- Maximum code length using lat/lng pair encoding. The area of such a
-- code is approximately 13x13 meters (at the equator), and should be suitable
-- for identifying buildings. This excludes prefix and separator characters.
local PAIR_CODE_LENGTH_ = 10

-- The resolution values in degrees for each position in the lat/lng pair
-- encoding. These give the place value of each position, and therefore the
-- dimensions of the resulting area. reference values, not actually used
--local PAIR_RESOLUTIONS_ = {20.0, 1.0, .05, .0025, .000125}

-- Number of columns in the grid refinement method.
--local GRID_COLUMNS_ = 4;

-- Number of rows in the grid refinement method.
--local GRID_ROWS_ = 5;

--my own pass at the algorithm. shorter, less thorough.
function tryMyEncode(latitude, longitude, codeLength)
    local code = ""
    local lat = math.floor((latitude + 90) * 8000)
    local long = math.floor((longitude + 180) * 8000)
    if (debug) then print("calc'd lat is   " .. lat) end
    if (debug) then print("calc'd long is  " .. long) end 

    -- 10 most significant digits
    for i= 1, 5, 1 do
        local nextLongChar = (long % 20) + 1 
        local nextLatChar = (lat % 20) + 1

        code = CODE_ALPHABET_:sub(nextLatChar, nextLatChar) .. CODE_ALPHABET_:sub(nextLongChar, nextLongChar) .. code
        lat = math.floor(lat / 20)
        long = math.floor(long / 20)
        if (debug) then print("assembled code so far is  " .. code) end
    end

    return code:sub(1,8) .. SEPARATOR_ .. code:sub(9, 10);
end

function shiftCell(pluscode, xShift, yShift)
    --take the current cell, move it some number of cells in both directions (positive or negative)
    --will probably only work for values between -39 and 39. Shifting by 20 means you've move up 1 higher level cell entirely,
    local newCode = pluscode
    local currentDigit = ""
    local digitIndex = 0
    if (debug)then print ("shifting cell " .. pluscode) end
    --do X shift
    if (xShift ~= 0) then
        if (debug)then print ("Shifting X " .. xShift) end
        currentDigit = pluscode:sub(11, 11)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + xShift
        --i probably also need to adjust position 8 in the string if this happens in either direction
        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
            newCode = ShiftWholeBlock(newCode, -1, 0)
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
            newCode = ShiftWholeBlock(newCode, 1, 0)
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, 10) .. currentDigit
    end
    if (debug)then print ("newcode is " .. newCode) end

    --do Y shift
    if (yShift ~= 0) then
        if (debug)then print ("shifting Y " .. yShift) end
        --get last digit, move it 1 notch higher on the list
        currentDigit = pluscode:sub(10, 10)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + yShift
        --i probably also need to adjust position 7 in the string if this happens in either direction
        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
            newCode = ShiftWholeBlock(newCode, 0, -1)
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
            newCode = ShiftWholeBlock(newCode, 0, 1)
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, 9) .. currentDigit .. newCode:sub(11,11)
    end
    if (debug)then print ("newcode is " .. newCode) end

    return newCode
end

function ShiftWholeBlock(plusCode, xShift, yShift)
    --this function is set to shift positions 7 and 8 in a plus code.
    local newCode = plusCode
    local currentDigit = ""
    local digitIndex = 0
    if (debug)then print ("shifting cell " .. plusCode) end
    --do X shift
    if (xShift ~= 0) then
        if (debug)then print ("Shifting X " .. xShift) end
        currentDigit = plusCode:sub(8, 8)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + xShift
        --i probably also need to adjust position 6 in the string if this happens in either direction
        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, 7) .. currentDigit .. newCode:sub(9, 11)
    end
    if (debug)then print ("newcode is " .. newCode) end

    --do Y shift
    if (yShift ~= 0) then
        if (debug)then print ("shifting Y " .. yShift) end
        --get last digit, move it 1 notch higher on the list
        currentDigit = plusCode:sub(7, 7)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + yShift
        --i probably also need to adjust position 5 in the string if this happens in either direction
        if (digitIndex <= 0) then
            digitIndex = 20 + digitIndex
        end
        if (digitIndex > 20) then
            digitIndex = digitIndex - 20
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, 6) .. currentDigit .. newCode:sub(8,11)
    end
    if (debug)then print ("newcode is " .. newCode) end
    return newCode
end