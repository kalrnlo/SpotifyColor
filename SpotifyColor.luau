--!strict

-- SpotifyColor
-- Spotify album background color getter from Spotify CarThing ported to Luau.
-- https://github.com/Merlin04/superbird-webapp/blob/modded/helpers/ColorExtractor.ts
-- @Kalrnlo
-- 12/02/2024

local ColorUtils = require(Path.To.ColorUtils)
local Quantize = require(Path.To.Quantize)

local DarkColor = Color3.fromHex("#000000")
local LightColor = Color3.fromHex("#FFFFFF")
local minTextContrast = 7 -- Minimum text/background contrast ratio for WCAG AAA compliance.
local minBackgroundContrast = 1.5; -- Minimum background/background contrast (arbitrarily chosen).

local function ExtractColor(EditableImage: EditableImage)
	local Pixels = EditableImage:ReadPixels(Vector2.new(0, 0), EditableImage.Size)
	local PixelCount = EditableImage.Size.X * EditableImage.Size.Y
	local PixelArray = table.create(math.ceil(PixelCount / 10))

	for Index = 1, PixelCount, 10 do
		local Offset = Index * 4
		local R = Pixels[Offset]
		local G = Pixels[Offset + 1]
		local B = Pixels[Offset + 2]
		local A = Pixels[Offset + 3]
	
		--If pixel is mostly opaque and not white
		if A >= 255 then
			if not (R > 250 and G > 250 and B > 250) then
				local RGBTable = table.create(3)
				RGBTable[1] = R
				RGBTable[2] = G
				RGBTable[3] = B
				
				PixelArray[#PixelArray + 1] = RGBTable
			end
		end
	end
	return Quantize(PixelArray, 5):Palette()[1]
end

local function EnsureContrastRatio(Color: Color3)
	local HSL = ColorUtils.HSL.toHSL(Color)
	
	-- Add lightness (L in HSL) until accessible against black.
	while ColorUtils.GetContrastRatio(ColorUtils.HSL.fromHSL(HSL), DarkColor) < minBackgroundContrast
		and HSL.L < 100
	do
		HSL.L += 1
	end

	-- Subtract lightness (L in HSL) until accessible against white.
	while ColorUtils.GetContrastRatio(ColorUtils.HSL.fromHSL(HSL), LightColor) < minTextContrast
		and HSL.L > 0
	do
		HSL.L -= 1
	end
	
	return ColorUtils.HSL.fromHSL(HSL)
end

local function GetBackgroundColor(EditableImage: EditableImage, Factor: number?)
	local Pixel = ExtractColor(EditableImage)
	local Factor = Factor or 1
	
	for Index, Channel in Pixel do
		Pixel[Index] = math.floor(Channel * Factor)
	end
	
	return EnsureContrastRatio(Color3.fromRGB(Pixel[1], Pixel[2], Pixel[3]))
end

return {
	EnsureContrastRatio = EnsureContrastRatio,
	GetBackgroundColor = GetBackgroundColor,
	ExtractColor = ExtractColor,
}
