require "spec"
require "../src/rosegold-civmc"

class Rosegold::CivMC::Bot
  def test_client
    @bot.client
  end
end

describe Rosegold::CivMC::Bot do
  it "keeps the default server when no override is supplied" do
    bot = Rosegold::CivMC::Bot.new
    bot.host.should eq("play.civmc.net")
    bot.port.should eq(25565)
  end

  it "delivers permitted events and removes one-shot subscriptions" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    health = [] of Float32
    bot.once(Rosegold::Event::HealthChanged) { |event| health << event.health }
    bot.test_client.emit_event(Rosegold::Event::HealthChanged.new(20_f32, 18_f32, 20_u32, 5_f32))
    bot.test_client.emit_event(Rosegold::Event::HealthChanged.new(18_f32, 16_f32, 20_u32, 5_f32))
    health.should eq([18_f32])
  end

  it "returns permitted events from an action-triggered wait" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    event = bot.wait_for(Rosegold::Event::ExperienceChanged) do
      bot.test_client.emit_event(Rosegold::Event::ExperienceChanged.new(1_u32, 2_u32, 7_u32, 16_u32, 0_f32, 0_f32))
    end
    event.experience_level.should eq(2_u32)
  end

  it "isolates slot-event handlers from server-synchronized inventory" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    slot = Rosegold::WindowSlot.new(36, Rosegold::Slot.new(2_u32, 1_u32))
    bot.test_client.inventory_menu[36] = slot
    bot.on(Rosegold::Clientbound::SetSlot) { |event| event.slot.count = 99_u32 }
    bot.test_client.emit_event(Rosegold::Clientbound::SetSlot.new(0_i8, 1_u32, slot))
    bot.test_client.inventory_menu[36].count.should eq(2_u32)
  end

  it "wraps menus received through container-open observations" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    chest = Rosegold::ChestMenu.new(bot.test_client, 1_u8, Rosegold::Chat.new("Chest"), 3)
    received = nil.as(Rosegold::CivMC::Menu?)
    bot.on(Rosegold::CivMC::ContainerOpened) { |event| received = event.menu }
    bot.test_client.emit_event(Rosegold::Event::ContainerOpened.new(2_u32, "Chest", chest))
    received.should be_a(Rosegold::CivMC::Menu)
  end

  it "detaches nested item components in container-content observations" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    components = {"damage" => Rosegold::DataComponents::Damage.new(4_u32).as(Rosegold::DataComponent)}
    slot = Rosegold::WindowSlot.new(36, Rosegold::Slot.new(2_u32, 1_u32, components))
    bot.test_client.inventory_menu[36] = slot
    bot.on(Rosegold::Clientbound::SetContainerContent) do |event|
      event.slots.first.components_to_add.clear
    end
    packet = Rosegold::Clientbound::SetContainerContent.new(0_u32, 1_u32, [slot], Rosegold::WindowSlot.new(-1, Rosegold::Slot.new))
    bot.test_client.emit_event(packet)
    bot.test_client.inventory_menu[36].components_to_add.has_key?("damage").should be_true
  end

  it "reports disconnected helper calls without exposing client state" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    bot.raise_level_with("emerald", 30).reason.disconnected?.should be_true
    expect_raises(Rosegold::CivCommon::MovementError) { bot.elevator(10) }
  end
end
