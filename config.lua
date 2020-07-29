--
-- For more information on config.lua see the Project Configuration Guide at:
-- https://docs.coronalabs.com/guide/basics/configSettings
--

application =
{
	content =
	{
		width = 720,
		height = 1280, 
		scale = "letterbox",
		fps = 60,
		
		--[[
		imageSuffix =
		{
			    ["@2x"] = 2,
			    ["@4x"] = 4,
		},
		--]]
	},
	license =
    {
        google =
        {
            key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAifzatodKYdPLYlvXj3Wy2sY5qUcWxtUNKID6Lyu0zUUWCKA/Ks9FXhEizTwjoKZb/4wrD7XIkRoA7jIkkQ+IShncBNhfaXE7MgSC+mIanN1Clf66pbIRZwTd5QmYJ/CtJq0Y8apy1kHzs0Nxbfbo8qBXHrAw3ERSsO0qGILbHkHF4UcYf2/4LiepejGlTduN81vlQk0JqWosqf7JujAi0cJjYiTXn+2Lrj4CiErXqRJo01EtidhJyOZeUfOl2bfrZkZcMnNVySYQR5o70BN6Y+9v3xUoT2iZDSt/XXtztlDzJLsXOenp/GqM3gZklKszE71HI393ZXRo+zitY1x4uwIDAQAB",
        },
    },
}
