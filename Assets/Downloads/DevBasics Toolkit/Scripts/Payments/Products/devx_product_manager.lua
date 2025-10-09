--!Type(Module)

--!Tooltip("Currency Icon")
--!SerializeField
local _CurrencyIcon : Texture = nil

--!Tooltip("Deals Icons")
--!SerializeField
local _DealsIcons : { Texture } = {}

type Deal = {
  id: string,                   -- Unique Identifier
  name: string,                 -- Name of the deal
  description: string | nil,    -- Description of the deal
  price: number | nil,          -- Price in Gold
  icon: Texture | nil,          -- Icon of the deal
  value: number                 -- Value of the deal (Currency)
}

local CurrencyDeals : { [string]: Deal } = {
  ["devx_currency_100"] = {
    id = "devx_currency_100",
    name = "Starter Pack",
    description = "Start your journey with 100 currency!",
    price = 100,
    icon = _DealsIcons[1],
    value = 100
  },
  ["devx_currency_200"] = {
    id = "devx_currency_200",
    name = "Medium Pack",
    description = "Get 200 currency for a medium pack!",
    price = 200,
    icon = _DealsIcons[2],
    value = 200
  },
  ["devx_currency_500"] = {
    id = "devx_currency_500",
    name = "Large Pack",
    description = "Get 500 currency for a large pack!",
    price = 500,
    icon = _DealsIcons[3],
    value = 500
  },
  ["devx_currency_1000"] = {
    id = "devx_currency_1000",
    name = "Huge Pack",
    description = "Get 1000 currency for a huge pack!",
    price = 1000,
    icon = _DealsIcons[4],
    value = 1000
  },
  ["devx_currency_5000"] = {
    id = "devx_currency_5000",
    name = "Gigapack",
    description = "Get 5000 currency for a gigapack!",
    price = 5000,
    icon = _DealsIcons[5],
    value = 5000
  },
  ["devx_currency_10000"] = {
    id = "devx_currency_10000",
    name = "Megapack",
    description = "Get 10000 currency for a megapack!",
    price = 10000,
    icon = _DealsIcons[6],
    value = 10000
  }
}

--[[
  GetDeals: Returns the deals.
  @return { [string]: Deal }
]]
function GetDeals(): { [string]: Deal }
  return CurrencyDeals or {}
end

--[[
  GetDealsIcons: Returns the deals icons.
  @return { Texture }
]]
function GetDealsIcons(): { Texture }
  return _DealsIcons or {}
end

--[[
  GetDeal: Returns the deal.
  @param product_id: string
  @return Deal | nil
]]
function GetDeal(product_id: string): Deal | nil
  return CurrencyDeals[product_id] or nil
end

--[[
  GetCurrencyIcon: Returns the currency icon.
  @return Texture | nil
]]
function GetCurrencyIcon(): Texture | nil
  return _CurrencyIcon or nil
end