require "spec"
require "rosegold"
require "../src/rosegold-civmc/inventory"

private def inventory_client
  Rosegold::Client.new("localhost", 25565, offline: {uuid: "00000000-0000-0000-0000-000000000000", username: "inventorytest"})
end

describe Rosegold::CivMC::Inventory do
  it "detaches slot values and component state from the live inventory" do
    client = inventory_client
    components = {"damage" => Rosegold::DataComponents::Damage.new(4_u32).as(Rosegold::DataComponent)}
    client.inventory_menu[36] = Rosegold::Slot.new(2_u32, 1_u32, components)
    inventory = Rosegold::CivMC::Inventory.new(Rosegold::Inventory.new(client))
    snapshot = inventory.hotbar.first
    snapshot.slot_number.should eq(36)
    snapshot.count = 99_u32
    snapshot.components_to_add.clear
    client.inventory_menu[36].count.should eq(2_u32)
    client.inventory_menu[36].components_to_add.has_key?("damage").should be_true
    inventory.count { |slot| slot.item_id_int == 1_u32 }.should eq(2)
  end

  it "passes detached slots to selection predicates" do
    client = inventory_client
    client.inventory_menu[36] = Rosegold::Slot.new(2_u32, 1_u32)
    inventory = Rosegold::CivMC::Inventory.new(Rosegold::Inventory.new(client))
    inventory.pick do |slot|
      slot.count = 0_u32
      false
    end.should be_false
    client.inventory_menu[36].count.should eq(2_u32)
  end
end

describe Rosegold::CivMC::ContainerHandle do
  it "wraps typed menus and preserves safe indexed slot snapshots" do
    client = inventory_client
    chest = Rosegold::ChestMenu.new(client, 1_u8, Rosegold::Chat.new("Chest"), 3)
    chest[0] = Rosegold::Slot.new(5_u32, 1_u32)
    handle = Rosegold::CivMC::ContainerHandle.new(Rosegold::ContainerHandle.new(client, chest))
    handle.menu.should be_a(Rosegold::CivMC::Menu)
    (handle.as_chest || raise "Missing expected inventory value").rows.should eq(3)
    handle.as_furnace.should be_nil
    slot = (handle.find_in_container(1_u32) || raise "Missing expected inventory value")
    slot.slot_number.should eq(0)
    slot.count = 0_u32
    handle.count_in_container(1_u32).should eq(5)
    (handle.as_chest || raise "Missing expected inventory value").contents.first.count.should eq(5_u32)
  end

  it "exposes enchanting display offers without the seed properties" do
    client = inventory_client
    menu = Rosegold::EnchantmentMenu.new(client, 1_u8, Rosegold::Chat.new("Enchant"))
    menu.properties[0_i16] = 5_i16
    menu.properties[3_i16] = 123_i16
    handle = Rosegold::CivMC::ContainerHandle.new(Rosegold::ContainerHandle.new(client, menu))
    wrapper = (handle.as_enchantment || raise "Missing expected inventory value")
    (wrapper.offers[0] || raise "Missing expected inventory value").required_level.should eq(5)
    wrapper.responds_to?(:properties).should be_false
    wrapper.responds_to?(:client).should be_false
    wrapper.responds_to?(:menu).should be_false
  end
end

describe Rosegold::CivMC::Menu do
  it "wraps every typed menu without exposing raw state" do
    client = inventory_client
    title = Rosegold::Chat.new("Container")
    menus = [
      Rosegold::CraftingMenu.new(client, 1_u8, title),
      Rosegold::FurnaceMenu.new(client, 1_u8, title),
      Rosegold::AnvilMenu.new(client, 1_u8, title),
      Rosegold::BrewingStandMenu.new(client, 1_u8, title),
      Rosegold::HopperMenu.new(client, 1_u8, title),
      Rosegold::MerchantMenu.new(client, 1_u8, title),
    ]
    menus.each do |raw|
      handle = Rosegold::CivMC::ContainerHandle.new(Rosegold::ContainerHandle.new(client, raw))
      handle.as_crafting.try(&.grid.size.should eq(9))
      handle.as_furnace.try(&.ingredient.empty?.should be_true)
      handle.as_anvil.try(&.first_input.empty?.should be_true)
      handle.as_brewing_stand.try(&.bottles.size.should eq(3))
      handle.as_hopper.try(&.contents.size.should eq(5))
      handle.as_merchant.try(&.trades.empty?.should be_true)
      handle.menu.responds_to?(:properties).should be_false
      handle.menu.responds_to?(:update_slot).should be_false
      handle.menu.responds_to?(:player_inventory).should be_false
      handle.menu.responds_to?(:client).should be_false
    end
  end
end

describe "CivMC inventory display properties" do
  it "returns only named display values, preserving unknown values" do
    client = inventory_client
    title = Rosegold::Chat.new("Container")
    furnace = Rosegold::FurnaceMenu.new(client, 1_u8, title)
    wrapped_furnace = Rosegold::CivMC::FurnaceMenu.new(furnace)
    wrapped_furnace.cook_ticks.should be_nil
    furnace.properties[0_i16] = 80_i16
    furnace.properties[1_i16] = 160_i16
    furnace.properties[2_i16] = 25_i16
    furnace.properties[3_i16] = 200_i16
    wrapped_furnace.fuel_ticks_remaining.should eq(80)
    wrapped_furnace.fuel_ticks_total.should eq(160)
    wrapped_furnace.cook_ticks.should eq(25)
    wrapped_furnace.cook_ticks_total.should eq(200)
    brewing = Rosegold::BrewingStandMenu.new(client, 1_u8, title)
    brewing.properties[0_i16] = 300_i16
    brewing.properties[1_i16] = 12_i16
    wrapped_brewing = Rosegold::CivMC::BrewingStandMenu.new(brewing)
    wrapped_brewing.brewing_ticks.should eq(300)
    wrapped_brewing.fuel_uses_remaining.should eq(12)
    anvil = Rosegold::AnvilMenu.new(client, 1_u8, title)
    anvil.properties[0_i16] = 7_i16
    Rosegold::CivMC::AnvilMenu.new(anvil).level_cost.should eq(7)
  end
end
