--!Type(Module)

--!SerializeField
local _GoldBarIcons : { Texture } = nil

type GoldBarMetadata = {
  Name : string,
  Amount : number,
  ItemId : string,
  Icon : Texture,
  Description : string,
  CustomMessage : boolean,
  IsPremium : boolean,
}

local gold_bar_metadata : { [string] : GoldBarMetadata } = {
  ["nugget"] = {
    Name = "1 Nugget",
    Amount = 1,
    ItemId = "nugget",
    Icon = _GoldBarIcons[1],
    Description = "A small piece of gold. It's not much, but it's something.",
    CustomMessage = false,
    IsPremium = false,
  },
  ["5_bar"] = {
    Name = "5G Bar",
    Amount = 5,
    ItemId = "5_bar",
    Icon = _GoldBarIcons[2],
    Description = "A small bar of gold. It's worth 5 nuggets.",
    CustomMessage = false,
    IsPremium = false,
  },
  ["10_bar"] = {
    Name = "10G Bar",
    Amount = 10,
    ItemId = "10_bar",
    Icon = _GoldBarIcons[3],
    Description = "A bar of gold. It's worth 10 nuggets.",
    CustomMessage = false,
    IsPremium = false,
  },
  ["50_bar"] = {
    Name = "50G Bar",
    Amount = 50,
    ItemId = "50_bar",
    Icon = _GoldBarIcons[4],
    Description = "A large bar of gold. It's worth 50 nuggets.",
    CustomMessage = false,
    IsPremium = false,
  },
  ["100_bar"] = {
    Name = "100G Bar",
    Amount = 100,
    ItemId = "100_bar",
    Icon = _GoldBarIcons[5],
    Description = "A huge bar of gold. It's worth 100 nuggets.",
    CustomMessage = true,
    IsPremium = false,
  },
  ["500_bar"] = {
    Name = "500G Bar",
    Amount = 500,
    ItemId = "500_bar",
    Icon = _GoldBarIcons[6],
    Description = "A massive bar of gold. It's worth 500 nuggets.",
    CustomMessage = true,
    IsPremium = false,
  },
  ["1000_bar"] = {
    Name = "1k Gold Bar",
    Amount = 1000,
    ItemId = "1000_bar",
    Icon = _GoldBarIcons[7],
    Description = "A gigantic bar of gold. It's worth 1000 nuggets.",
    CustomMessage = true,
    IsPremium = false,
  },
  ["5000_bar"] = {
    Name = "5k Gold Bar",
    Amount = 5000,
    ItemId = "5000_bar",
    Icon = _GoldBarIcons[8],
    Description = "A colossal bar of gold. It's worth 5000 nuggets.",
    CustomMessage = true,
    IsPremium = true,
  },
  ["10000_bar"] = {
    Name = "10k Gold Bar",
    Amount = 10000,
    ItemId = "10000_bar",
    Icon = _GoldBarIcons[9],
    Description = "A massive bar of gold. It's worth 10000 nuggets.",
    CustomMessage = true,
    IsPremium = true,
  }
}

-- Define a consistent order for gold bars
local gold_bar_order = {
  "nugget",
  "5_bar",
  "10_bar", 
  "50_bar",
  "100_bar",
  "500_bar",
  "1000_bar",
  "5000_bar",
  "10000_bar"
}

function GetGoldBarMetadata(): { [string] : GoldBarMetadata }
  return gold_bar_metadata
end

function GetGoldBarsCount(): number
  return #gold_bar_order
end

function GetGoldBarMetadataByIndex(index : number): GoldBarMetadata?
  -- Arrays in Lua are 1-indexed
  if index >= 1 and index <= #gold_bar_order then
    local key = gold_bar_order[index]
    return gold_bar_metadata[key]
  end
  
  return nil
end