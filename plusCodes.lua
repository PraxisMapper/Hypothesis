PlusCode = {}

-- 14x14 precision
CODE_PRECISION_NORMAL = 10

-- 2x3 precision
CODE_PRECISION_EXTRA = 11

-- A separator used to break the code into two parts to aid memorability.
local SEPARATOR_ = '+'

-- The number of characters to place before the separator.
local SEPARATOR_POSITION_ = 8

-- The character used to pad codes.
local PADDING_CHARACTER_ = '0'

-- The character set used to encode the values.
CODE_ALPHABET_ = '23456789CFGHJMPQRVWX' --no longer local, so we can use it in other files

-- The base to use to convert numbers to/from.
local ENCODING_BASE_ = string.len(CODE_ALPHABET_)

-- The maximum value for latitude in degrees.
local LATITUDE_MAX_ = 90

-- The maximum value for longitude in degrees.
local LONGITUDE_MAX_ = 180

-- The max number of digits to process in a plus code.
local MAX_DIGIT_COUNT_ = 15

-- Maximum code length using lat/lng pair encoding. The area of such a
-- code is approximately 13x13 meters (at the equator), and should be suitable
-- for identifying buildings. This excludes prefix and separator characters.
local PAIR_CODE_LENGTH_ = 10

-- First place value of the pairs (if the last pair value is 1).
local PAIR_FIRST_PLACE_VALUE_ = math.pow(ENCODING_BASE_, (PAIR_CODE_LENGTH_ / 2 - 1))

-- Inverse of the precision of the pair section of the code.
local PAIR_PRECISION_ = math.pow(ENCODING_BASE_, 3)

-- The resolution values in degrees for each position in the lat/lng pair
-- encoding. These give the place value of each position, and therefore the
-- dimensions of the resulting area.
local PAIR_RESOLUTIONS_ = {20.0, 1.0, .05, .0025, .000125}

-- Number of digits in the grid precision part of the code.
local GRID_CODE_LENGTH_ = MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_;

-- Number of columns in the grid refinement method.
local GRID_COLUMNS_ = 4;

-- Number of rows in the grid refinement method.
local GRID_ROWS_ = 5;

-- First place value of the latitude grid (if the last place is 1).
local GRID_LAT_FIRST_PLACE_VALUE_ = math.pow(GRID_ROWS_, (GRID_CODE_LENGTH_ - 1));

-- First place value of the longitude grid (if the last place is 1).
local GRID_LNG_FIRST_PLACE_VALUE_ = math.pow(GRID_COLUMNS_, (GRID_CODE_LENGTH_ - 1));

-- Multiply latitude by this much to make it a multiple of the finest precision.
local FINAL_LAT_PRECISION_ = PAIR_PRECISION_ * math.pow(GRID_ROWS_, (MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_));

-- Multiply longitude by this much to make it a multiple of the finest precision.
local FINAL_LNG_PRECISION_ = PAIR_PRECISION_ * math.pow(GRID_COLUMNS_, (MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_));

-- Minimum length of a code that can be shortened.
local MIN_TRIMMABLE_CODE_LEN_ = 6;

-- return {string} Returns the OLC alphabet.
function getAlphabet() 
    return CODE_ALPHABET_ 
end

--my own pass at the algorithm. shorter, less thorough.
function tryMyEncode(latitude, longitude, codeLength)
    local code = ""
    local lat = math.floor((latitude + 90) * 8000)
    local long = math.floor((longitude + 180) * 8000)
    if (debug) then print("calc'd lat is   " .. lat) end
    if (debug) then print("calc'd long is  " .. long) end --these show up in the other formula too, after a few iterations.

    -- 10 most significant digits
    for i= 1, 5, 1 do
        local nextLongChar = (long % 20) + 1 
        local nextLatChar = (lat % 20) + 1

        code = CODE_ALPHABET_:sub(nextLatChar, nextLatChar) .. CODE_ALPHABET_:sub(nextLongChar, nextLongChar) .. code
        lat = math.floor(lat / 20)
        long = math.floor(long / 20)
        if (debug) then print("assembled code so far is  " .. code) end
    end

    --if (debug) then print("starting least signficant digits, current code is " .. code) end
    --5 least significant digits. Undone.


    return code:sub(1,8) .. SEPARATOR_ .. code:sub(9, 10);
end

--copy of JS reference code. Not completely correctly ported, or not completely correct to start?
-- Encode a location into an Open Location Code.
-- param {number} latitude The latitude in signed decimal degrees. It will be clipped to the range -90 to 90.
-- param {number} longitude The longitude in signed decimal degrees. Will be normalised to the range -180 to 180.
-- param {?number} codeLength The length of the code to generate. If  omitted, the value OpenLocationCode.CODE_PRECISION_NORMAL will be used.
--     For a more precise result, OpenLocationCode.CODE_PRECISION_EXTRA is recommended.
-- return {string} The code.
-- throws {Exception} if any of the input values are not numbers.
function encode(latitude, longitude, codeLength)
    --latitude = Number(latitude);
    --longitude = Number(longitude);
    if (codeLength == nil) then
        codeLength = OpenLocationCode.CODE_PRECISION_NORMAL;
    else
        codeLength = math.min(MAX_DIGIT_COUNT_, codeLength);
    end
    if (type(latitude) ~= "number" or type(longitude) ~= "number" or type(codeLength) ~= "number") then
        error('ValueError: Parameters are not numbers')
    end
    if (codeLength < 2 or
        (codeLength < PAIR_CODE_LENGTH_ and codeLength % 2 == 1)) then
        error('IllegalArgumentException: Invalid Open Location Code length');
    end

    -- Ensure that latitude and longitude are valid.
    latitude = clipLatitude(latitude);
    longitude = normalizeLongitude(longitude);
    -- Latitude 90 needs to be adjusted to be just less, so the returned code can also be decoded.
    if (latitude == 90) then
        latitude = latitude - computeLatitudePrecision(codeLength);
    end
    local code = '';

    if (debug) then print("adjusted latitude is " .. latitude) end
    if (debug) then print("adjusted longitude is " .. longitude) end

    -- Compute the code.
    -- This approach converts each value to an integer after multiplying it by
    -- the final precision. This allows us to use only integer operations, so
    -- avoiding any accumulation of floating point representation errors.

    -- Multiply values by their precision and convert to positive.
    -- Force to integers so the division operations will have integer results.
    -- Note: JavaScript requires rounding before truncating to ensure precision!
    local latVal = math.floor(math.round((latitude + LATITUDE_MAX_) * FINAL_LAT_PRECISION_ * 1e6) / 1e6)
    local lngVal = math.floor(math.round((longitude + LONGITUDE_MAX_) * FINAL_LNG_PRECISION_ * 1e6) / 1e6)

    if (debug) then print("int latitude is " .. latVal) end
    if (debug) then print("int longitude is " .. lngVal) end
    if (debug) then print("encoding base is " .. ENCODING_BASE_) end
    -- Compute the grid part of the code if necessary. This is the 5x4 grid area, most significant digits.
    if (codeLength > PAIR_CODE_LENGTH_) then
        for i = 1, MAX_DIGIT_COUNT_ - PAIR_CODE_LENGTH_, 1 do --(15 - 10 = 5), so for 1, 5, 1
            local latDigit = latVal % GRID_ROWS_;
            local lngDigit = lngVal % GRID_COLUMNS_;
            local ndx = (latDigit * GRID_COLUMNS_ + lngDigit) + 1
            if (debug) then print("next letter is: " .. CODE_ALPHABET_:sub(ndx, ndx)) end
            code = CODE_ALPHABET_:sub(ndx, ndx) .. code;
            -- Note! Integer division.
            latVal = math.floor(latVal / GRID_ROWS_);
            lngVal = math.floor(lngVal / GRID_COLUMNS_);
            if (debug) then print("A next latVal is " .. latVal .. " and lngVal is " .. lngVal) end
        end
    else
        latVal = math.floor(latVal / math.pow(GRID_ROWS_, GRID_CODE_LENGTH_));
        lngVal = math.floor(lngVal / math.pow(GRID_COLUMNS_, GRID_CODE_LENGTH_));
        if (debug) then print("B next latVal is " .. latVal .. " and lngVal is " .. lngVal) end
    end

    if (debug) then print("starting least signficant digits, current code is " .. code) end
    -- Compute the pair section of the code, least significant digits.
    for i = 0, PAIR_CODE_LENGTH_ / 2, 1 do
        if (debug) then print("Next position is " .. lngVal % ENCODING_BASE_.. " LEtter: " .. CODE_ALPHABET_:sub(lngVal % ENCODING_BASE_, lngVal % ENCODING_BASE_)) end
        code = CODE_ALPHABET_:sub((lngVal % ENCODING_BASE_) + 1, (lngVal % ENCODING_BASE_) + 1) .. code;
        code = CODE_ALPHABET_:sub((latVal % ENCODING_BASE_) + 1, (latVal % ENCODING_BASE_) + 1) .. code;
        latVal = math.floor(latVal / ENCODING_BASE_);
        lngVal = math.floor(lngVal / ENCODING_BASE_);
        if (debug) then print("C next latVal is " .. latVal .. " and lngVal is " .. lngVal) end
    end

    if (debug) then print("full code is: " .. code) end

    -- Add the separator character.
    code = code:sub(0, SEPARATOR_POSITION_) .. SEPARATOR_ .. code:sub(SEPARATOR_POSITION_ + 1, codeLength);
    
    if (debug) then print("trimmed code is: " .. code) print("Expected code is Palo Alto, CRXR+9C") end

    -- If we dont need to pad the code, return the requested section.
    if (codeLength >= SEPARATOR_POSITION_) then
        return code:sub(0, codeLength + 1)
    end

    -- Pad and return the code. TODO fit to LUA
    return code:sub(0, codeLength) .. Array(SEPARATOR_POSITION_ - codeLength + 1).join(PADDING_CHARACTER_) .. SEPARATOR_
end

function clipLatitude(latitude) 
    return math.min(90, math.max(-90, latitude)); 
end

function normalizeLongitude(longitude)
    while (longitude < -180) do longitude = longitude + 360; end
    while (longitude >= 180) do longitude = longitude - 360; end
    return longitude;
end

-- spec required but unlikely to be used here:

-- Determines if a code is valid.
-- To be valid, all characters must be from the Open Location Code character
-- set with at most one separator. The separator can be in any even-numbered
-- position up to the eighth digit.

-- param {string} code The string to check.
-- return {boolean} True if the string is a valid code.

--    function isValid(code) 
--     --  if (!code || typeof code == 'string') {
--     --    return false;
--     --  }
--      -- The separator is required.
--      if (code.indexOf(SEPARATOR_) == -1) {
--        return false
--      }
--      if (code.indexOf(SEPARATOR_) ~= code.lastIndexOf(SEPARATOR_)) {
--        return false;
--      }
--      -- Is it the only character?
--      if (code.length == 1) {
--        return false;
--      }
--      -- Is it in an illegal position?
--      if (code.indexOf(SEPARATOR_) > SEPARATOR_POSITION_ ||
--          code.indexOf(SEPARATOR_) % 2 == 1) {
--        return false;
--      }
--      -- We can have an even number of padding characters before the separator,
--      -- but then it must be the final character.
--      if (code.indexOf(PADDING_CHARACTER_) > -1) {
--        -- Short codes cannot have padding
--        if (code.indexOf(SEPARATOR_) < SEPARATOR_POSITION_) {
--          return false;
--        }
--        -- Not allowed to start with them!
--        if (code.indexOf(PADDING_CHARACTER_) == 0) {
--          return false;
--        }
--        -- There can only be one group and it must have even length.
--        local padMatch = code.match(new RegExp('(' + PADDING_CHARACTER_ + '+)', 'g'));
--        if (padMatch.length > 1 || padMatch[0].length % 2 == 1 ||
--            padMatch[0].length > SEPARATOR_POSITION_ - 2) {
--          return false;
--        }
--        -- If the code is long enough to end with a separator, make sure it does.
--        if (code.charAt(code.length - 1) != SEPARATOR_) {
--          return false;
--        }
--      }
--      -- If there are characters after the separator, make sure there isn't just
--      -- one of them (not legal).
--      if (code.length - code.indexOf(SEPARATOR_) - 1 == 1) {
--        return false;
--      }

--      -- Strip the separator and any padding characters.
--      code = code.replace(new RegExp('\\' + SEPARATOR_ + '+'), '')
--          .replace(new RegExp(PADDING_CHARACTER_ + '+'), '');
--      -- Check the code contains only valid characters.
--      for (local i = 0, len = code.length; i < len; i++) {
--        local character = code.charAt(i).toUpperCase();
--        if (character != SEPARATOR_ && CODE_ALPHABET_.indexOf(character) == -1) {
--          return false;
--        }
--      }
--      return true;
--     end
