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

  it "detaches boss-bar titles from both state reads and events" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    uuid = UUID.random
    title = Rosegold::TextComponent.new("Server title")
    title.extra = [Rosegold::TextComponent.new(" detail")]
    event = Rosegold::Clientbound::BossEvent.add(uuid, title, 1_f32, :blue, :none)
    bot.test_client.apply_boss_event(event)
    bot.on(Rosegold::Clientbound::BossEvent) do |observed|
      if text = observed.title
        text.text = "Changed event"
        text.extra.try(&.first.text = "Changed detail")
      end
    end
    bot.test_client.emit_event(event)
    bot.boss_bar_states.first.title.text = "Changed snapshot"
    bot.boss_bar_states.first.title.extra.try(&.first.text = "Changed snapshot detail")
    bot.test_client.boss_bar_states.first.title.to_s.should eq("Server title detail")
  end

  it "detaches tab-list display names from reads and join events" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    uuid = UUID.random
    entry = Rosegold::PlayerList::Entry.new(uuid, "test")
    entry.display_name = Rosegold::TextComponent.new("Server display name")
    bot.test_client.player_list[uuid] = entry
    bot.on(Rosegold::Event::PlayerJoined) do |observed|
      observed.display_name.try(&.text = "Changed event")
    end
    bot.test_client.emit_event(Rosegold::Event::PlayerJoined.new(entry))
    bot.tab_list.first.display_name.try(&.text = "Changed snapshot")
    entry.display_name.try(&.text).should eq("Server display name")
  end

  it "detaches player chat signatures and rich text" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    signature = Bytes.new(256, 7_u8)
    previous = Bytes.new(256, 8_u8)
    mask = Bytes.new(8, 9_u8)
    content = Rosegold::TextComponent.new("Server content")
    name = Rosegold::TextComponent.new("Server sender")
    target = Rosegold::TextComponent.new("Server target")
    event = Rosegold::Clientbound::PlayerChatMessage.new(0_u32, UUID.random, 0_u32,
      signature, "hello", 0_i64, 0_i64, [previous], content, 2_u32, mask, 0_u32, name, target)
    bot.on(Rosegold::Clientbound::PlayerChatMessage) do |observed|
      observed.signature.try(&.fill(0_u8))
      observed.previous_messages.first.fill(0_u8)
      observed.filter_mask.try(&.fill(0_u8))
      observed.unsigned_content.try(&.text = "Changed content")
      observed.network_name.text = "Changed sender"
      observed.network_target_name.try(&.text = "Changed target")
    end
    bot.test_client.emit_event(event)
    signature[0].should eq(7_u8)
    previous[0].should eq(8_u8)
    mask[0].should eq(9_u8)
    content.text.should eq("Server content")
    name.text.should eq("Server sender")
    target.text.should eq("Server target")
  end

  it "detaches system and disguised chat components" do
    bot = Rosegold::CivMC::Bot.new("localhost:25565")
    message = Rosegold::TextComponent.new("Server message")
    sender = Rosegold::TextComponent.new("Server sender")
    target = Rosegold::TextComponent.new("Server target")
    bot.on(Rosegold::Clientbound::SystemChatMessage) { |event| event.message.text = "Changed system" }
    bot.on(Rosegold::Clientbound::DisguisedChatMessage) do |event|
      event.message.text = "Changed disguised"
      event.sender_name.text = "Changed sender"
      event.target_name.try(&.text = "Changed target")
    end
    bot.test_client.emit_event(Rosegold::Clientbound::SystemChatMessage.new(message))
    bot.test_client.emit_event(Rosegold::Clientbound::DisguisedChatMessage.new(message, 0_u32, sender, target))
    message.text.should eq("Server message")
    sender.text.should eq("Server sender")
    target.text.should eq("Server target")
  end
end
