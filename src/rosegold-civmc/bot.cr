module Rosegold::CivMC
  VERSION         = "0.1.0"
  DEFAULT_ADDRESS = "play.civmc.net:25565"

  # Container observations carry a restricted handle rather than the core menu.
  class ContainerOpened < Rosegold::Event
    getter window_type : UInt32
    getter title : String
    getter menu : Menu

    def initialize(@window_type, @title, @menu); end
  end

  # CivMC scripting entrypoint. Only explicitly reviewed operations are exposed.
  class Bot
    include Rosegold::CivCommon::Helpers

    @bot : Rosegold::Bot
    @events = Rosegold::EventEmitter.new
    @spectator : Rosegold::SpectateServer?
    getter inventory : Inventory
    getter keys : MovementKeys

    # An address override changes the destination, never the API policy.
    def initialize(address : String = DEFAULT_ADDRESS)
      @bot = Rosegold::Bot.new(address)
      @inventory = Inventory.new(@bot.inventory)
      @keys = MovementKeys.new(@bot.keys)
      forward_events
    end

    private def copy_event(event : Rosegold::Event)
      event
    end

    private def copy_event(event : Rosegold::Clientbound::SetSlot)
      Rosegold::Clientbound::SetSlot.new(event.window_id, event.state_id, InventorySnapshot.copy(event.slot))
    end

    private def copy_event(event : Rosegold::Clientbound::SetContainerContent)
      Rosegold::Clientbound::SetContainerContent.new(event.window_id, event.state_id,
        event.slots.map { |slot| InventorySnapshot.copy(slot) }, InventorySnapshot.copy(event.cursor))
    end

    private def copy_entry(entry : Rosegold::PlayerList::Entry)
      Rosegold::PlayerList::Entry.new(entry.uuid, entry.name, entry.properties.dup,
        entry.gamemode, entry.ping, entry.display_name)
    end

    private def copy_event(event : Rosegold::Event::PlayerJoined)
      Rosegold::Event::PlayerJoined.new(copy_entry(event.entry))
    end

    private def copy_event(event : Rosegold::Event::PlayerLeft)
      Rosegold::Event::PlayerLeft.new(copy_entry(event.entry))
    end

    private def forward_events
      {% for type in [Rosegold::Event::Tick, Rosegold::Event::HealthChanged,
                      Rosegold::Event::ExperienceChanged, Rosegold::Event::Died,
                      Rosegold::Event::PlayerJoined, Rosegold::Event::PlayerLeft,
                      Rosegold::Clientbound::SystemChatMessage,
                      Rosegold::Clientbound::PlayerChatMessage,
                      Rosegold::Clientbound::DisguisedChatMessage,
                      Rosegold::Clientbound::SetContainerContent,
                      Rosegold::Clientbound::SetSlot,
                      Rosegold::Clientbound::BossEvent] %}
        @bot.client.on({{type}}) { |event| @events.emit_event(copy_event(event)) }
      {% end %}
      @bot.client.on(Rosegold::Event::ContainerOpened) do |event|
        @events.emit_event(ContainerOpened.new(event.window_type, event.title, Menu.new(event.menu)))
      end
    end

    {% for type in [Rosegold::Event::Tick, Rosegold::Event::HealthChanged,
                    Rosegold::Event::ExperienceChanged, Rosegold::Event::Died,
                    Rosegold::Event::PlayerJoined, Rosegold::Event::PlayerLeft,
                    Rosegold::Clientbound::SystemChatMessage,
                    Rosegold::Clientbound::PlayerChatMessage,
                    Rosegold::Clientbound::DisguisedChatMessage,
                    Rosegold::Clientbound::SetContainerContent,
                    Rosegold::Clientbound::SetSlot,
                    Rosegold::Clientbound::BossEvent, ContainerOpened] %}
      # Subscribes to an allowed observation. Spawn work that waits for ticks.
      def on(event_type : {{type}}.class, id : UUID = UUID.random, &block : {{type}} ->)
        @events.on(event_type, id: id, &block)
      end

      # Removes an allowed observation subscription.
      def off(event_type : {{type}}.class, id : UUID)
        @events.off(event_type, id)
        nil
      end

      # Receives the next allowed observation once.
      def once(event_type : {{type}}.class, &block : {{type}} ->)
        @events.once(event_type, &block)
      end

      # Waits for an allowed observation, returning nil on timeout.
      def wait_for(event_type : {{type}}.class, timeout : Time::Span = 5.seconds)
        @events.wait_for(event_type, timeout)
      end

      # Runs an action and waits for an allowed observation, raising on timeout.
      def wait_for(event_type : {{type}}.class, timeout : Time::Span = 5.seconds, &)
        @events.wait_for(event_type, timeout) { yield }
      end
    {% end %}

    # Connects and returns the restricted bot after spawning.
    def self.join_game(address : String = DEFAULT_ADDRESS, timeout_ticks : Int32 = 1200)
      new(address).join_game(timeout_ticks)
    end

    # Connects and returns the restricted bot after spawning.
    def join_game(timeout_ticks : Int32 = 1200) : self
      @bot.join_game(timeout_ticks)
      self
    end

    # Connects, yields this bot, and disconnects even if the script raises.
    def join_game(timeout_ticks : Int32 = 1200, &)
      join_game(timeout_ticks)
      yield self
    ensure
      disconnect("Script finished") if connected?
    end

    # Returns the permitted host observation.
    def host
      @bot.host
    end

    # Returns the permitted port observation.
    def port
      @bot.port
    end

    # Returns the permitted connected observation.
    def connected?
      !!@bot.connected?
    end

    # Returns the permitted spawned observation.
    def spawned?
      @bot.spawned?
    end

    # Returns the permitted uuid observation.
    def uuid
      @bot.uuid
    end

    # Returns the permitted username observation.
    def username
      @bot.username
    end

    # Returns the permitted health observation.
    def health
      @bot.health
    end

    # Returns the permitted food observation.
    def food
      @bot.food
    end

    # Returns the permitted saturation observation.
    def saturation
      @bot.saturation
    end

    # Returns the permitted sneaking observation.
    def sneaking?
      @bot.sneaking?
    end

    # Returns the permitted sprinting observation.
    def sprinting?
      @bot.sprinting?
    end

    # Returns the permitted speed level observation.
    def speed_level
      @bot.speed_level
    end

    # Returns the permitted slowness level observation.
    def slowness_level
      @bot.slowness_level
    end

    # Returns the permitted jump boost level observation.
    def jump_boost_level
      @bot.jump_boost_level
    end

    # Returns the permitted has slow falling observation.
    def has_slow_falling?
      @bot.has_slow_falling?
    end

    # Returns the permitted levitation level observation.
    def levitation_level
      @bot.levitation_level
    end

    # Returns the permitted x observation.
    def x
      @bot.x
    end

    # Returns the permitted y observation.
    def y
      @bot.y
    end

    # Returns the permitted z observation.
    def z
      @bot.z
    end

    # Returns the permitted location observation.
    def location
      @bot.location
    end

    # Returns the permitted feet observation.
    def feet
      @bot.feet
    end

    # Returns the permitted riding observation.
    def riding
      @bot.riding
    end

    # Returns the permitted riding observation.
    def riding?(type : String? = nil)
      @bot.riding?(type)
    end

    # Returns the permitted disconnect reason observation.
    def disconnect_reason
      @bot.disconnect_reason
    end

    # Returns the permitted dead observation.
    def dead?
      @bot.dead?
    end

    # Returns the permitted look observation.
    def look
      @bot.look
    end

    # Returns the permitted yaw observation.
    def yaw
      @bot.yaw
    end

    # Returns the permitted pitch observation.
    def pitch
      @bot.pitch
    end

    # Returns the permitted hotbar selection observation.
    def hotbar_selection
      @bot.hotbar_selection
    end

    # Returns the permitted should eat observation.
    def should_eat?
      @bot.should_eat?
    end

    # Returns the permitted full health observation.
    def full_health?
      @bot.full_health?
    end

    # Returns the permitted experience level observation.
    def experience_level
      @bot.experience_level.to_i32
    end

    # Returns the permitted experience progress observation.
    def experience_progress
      @bot.experience_progress
    end

    # Returns the permitted total experience observation.
    def total_experience
      @bot.total_experience
    end

    # Returns the permitted auto respawn observation.
    def auto_respawn?
      @bot.auto_respawn?
    end

    # Performs connect through the core DSL without returning internals.
    def connect : Nil
      @bot.connect
      nil
    end

    # Performs disconnect through the core DSL without returning internals.
    def disconnect(reason : String) : Nil
      @bot.disconnect(reason)
      nil
    end

    # Performs respawn through the core DSL without returning internals.
    def respawn(timeout_ticks : Int32 = 1200) : Nil
      @bot.respawn(timeout_ticks)
      nil
    end

    # Performs chat through the core DSL without returning internals.
    def chat(message : String) : Nil
      @bot.chat(message)
      nil
    end

    # Performs wait tick through the core DSL without returning internals.
    def wait_tick : Nil
      @bot.wait_tick
      nil
    end

    # Performs wait ticks through the core DSL without returning internals.
    def wait_ticks(ticks : Int32) : Nil
      @bot.wait_ticks(ticks)
      nil
    end

    # Performs sneak through the core DSL without returning internals.
    def sneak(sneaking : Bool = true) : Nil
      @bot.sneak(sneaking)
      nil
    end

    # Performs sprint through the core DSL without returning internals.
    def sprint(sprinting : Bool = true) : Nil
      @bot.sprint(sprinting)
      nil
    end

    # Performs stop using hand through the core DSL without returning internals.
    def stop_using_hand : Nil
      @bot.stop_using_hand
      nil
    end

    # Performs stop digging through the core DSL without returning internals.
    def stop_digging : Nil
      @bot.stop_digging
      nil
    end

    # Sets look through the vanilla controls.
    def look=(value : Rosegold::Look | Rosegold::Vec3d)
      @bot.look=(value)
    end

    # Sets yaw through the vanilla controls.
    def yaw=(value : Float64)
      @bot.yaw=(value)
    end

    # Sets pitch through the vanilla controls.
    def pitch=(value : Float64)
      @bot.pitch=(value)
    end

    # Performs look at through the core DSL without returning internals.
    def look_at(location : Rosegold::Vec3d) : Nil
      @bot.look_at(location)
      nil
    end

    # Performs look at horizontal through the core DSL without returning internals.
    def look_at_horizontal(location : Rosegold::Vec3d) : Nil
      @bot.look_at_horizontal(location)
      nil
    end

    # Performs move to through the core DSL without returning internals.
    def move_to(location : Rosegold::Vec3d | Rosegold::Vec3i, stuck_timeout_ticks : Int32 = 60) : Nil
      @bot.move_to(location, stuck_timeout_ticks)
      nil
    end

    # Performs stop moving through the core DSL without returning internals.
    def stop_moving : Nil
      @bot.stop_moving
      nil
    end

    # Performs start jump through the core DSL without returning internals.
    def start_jump : Nil
      @bot.start_jump
      nil
    end

    # Performs stop jump through the core DSL without returning internals.
    def stop_jump : Nil
      @bot.stop_jump
      nil
    end

    # Performs jump by height through the core DSL without returning internals.
    def jump_by_height(height : Number = 1, timeout_ticks : Int32 = 20) : Nil
      @bot.jump_by_height(height, timeout_ticks)
      nil
    end

    # Performs land on ground through the core DSL without returning internals.
    def land_on_ground(timeout_ticks : Int32 = 120) : Nil
      @bot.land_on_ground(timeout_ticks)
      nil
    end

    # Performs unsneak through the core DSL without returning internals.
    def unsneak : Nil
      @bot.unsneak
      nil
    end

    # Performs unsprint through the core DSL without returning internals.
    def unsprint : Nil
      @bot.unsprint
      nil
    end

    # Performs leave bed through the core DSL without returning internals.
    def leave_bed : Nil
      @bot.leave_bed
      nil
    end

    # Sets hotbar selection through the vanilla controls.
    def hotbar_selection=(value : Int)
      @bot.hotbar_selection=(value.to_u8)
    end

    # Performs swap hands through the core DSL without returning internals.
    def swap_hands(timeout : Time::Span = 5.seconds) : Nil
      @bot.swap_hands(timeout)
      nil
    end

    # Performs drop hand single through the core DSL without returning internals.
    def drop_hand_single : Nil
      @bot.drop_hand_single
      nil
    end

    # Performs drop hand full through the core DSL without returning internals.
    def drop_hand_full : Nil
      @bot.drop_hand_full
      nil
    end

    # Performs start using hand through the core DSL without returning internals.
    def start_using_hand(hand : Rosegold::Hand = :main_hand) : Nil
      @bot.start_using_hand(hand)
      nil
    end

    # Performs use hand through the core DSL without returning internals.
    def use_hand(target : Rosegold::Vec3d | Rosegold::Look | Nil = nil, hand : Rosegold::Hand = :main_hand) : Nil
      @bot.use_hand(target, hand)
      nil
    end

    # Performs place block against through the core DSL without returning internals.
    def place_block_against(block : Rosegold::Vec3i, face : ::BlockFace) : Nil
      @bot.place_block_against(block, face)
      nil
    end

    # Performs eat through the core DSL without returning internals.
    def eat : Nil
      @bot.eat
      nil
    end

    # Performs eat! through the core DSL without returning internals.
    def eat! : Nil
      @bot.eat!
      nil
    end

    # Performs craft through the core DSL without returning internals.
    def craft(item_name : String, count : Int32 = 1, table : Rosegold::Vec3i? = nil) : Nil
      @bot.craft(item_name, count, table)
      nil
    end

    # Performs craft all through the core DSL without returning internals.
    def craft_all(item_name : String, table : Rosegold::Vec3i? = nil) : Nil
      @bot.craft_all(item_name, table)
      nil
    end

    # Performs craft pattern through the core DSL without returning internals.
    def craft_pattern(pattern : Array(Array(String?)), count : Int32 = 1, table : Rosegold::Vec3i? = nil) : Nil
      @bot.craft_pattern(pattern, count, table)
      nil
    end

    # Performs start digging through the core DSL without returning internals.
    def start_digging(target : Rosegold::Vec3d | Rosegold::Look | Nil = nil) : Nil
      @bot.start_digging(target)
      nil
    end

    # Performs dig through the core DSL without returning internals.
    def dig(ticks : Int32, target : Rosegold::Vec3d | Rosegold::Look | Nil = nil) : Nil
      @bot.dig(ticks, target)
      nil
    end

    # Performs attack through the core DSL without returning internals.
    def attack(target : Rosegold::Vec3d | Rosegold::Look | Nil = nil) : Nil
      @bot.attack(target)
      nil
    end

    # Sets auto respawn through the vanilla controls.
    def auto_respawn=(value : Bool)
      @bot.auto_respawn=(value)
    end

    # Moves to caller-provided horizontal coordinates.
    def move_to(x : Float, z : Float, stuck_timeout_ticks : Int32 = 60) : Nil
      @bot.move_to(x, z, stuck_timeout_ticks)
      nil
    end

    # Moves to the center of a caller-provided block column.
    def move_to(x : Int, z : Int, stuck_timeout_ticks : Int32 = 60) : Nil
      @bot.move_to(x, z, stuck_timeout_ticks)
      nil
    end

    # Computes a destination using only the bot's own position.
    def move_to(stuck_timeout_ticks : Int32 = 10, &block : Rosegold::Vec3d -> Rosegold::Vec3d) : Nil
      @bot.move_to(stuck_timeout_ticks, &block)
      nil
    end

    # Computes a new orientation from the current orientation.
    def look(&block : Rosegold::Look -> Rosegold::Look) : Nil
      @bot.look(&block)
      nil
    end

    # The bot's own eye position.
    def eyes
      @bot.eyes
    end

    # Returns the selected inventory item as a detached snapshot.
    def main_hand
      inventory.main_hand
    end

    # Returns the bot's potion effects, detached from live state.
    def effects
      @bot.effects.map(&.dup)
    end

    # Looks up a potion effect by name.
    def effect_by_name(name)
      @bot.effect_by_name(name).try(&.dup)
    end

    # Returns only server-provided tab-list entries.
    def tab_list
      @bot.client.player_list.values.map do |entry|
        Rosegold::PlayerList::Entry.new(entry.uuid, entry.name, entry.properties.dup,
          entry.gamemode, entry.ping, entry.display_name)
      end
    end

    # Returns the server-provided boss bars.
    def boss_bar_states
      @bot.client.boss_bar_states
    end

    # Enchants carried inventory at a caller-selected, already aimed-at table.
    def enchant(spec : String | UInt32, *, option : Int32, timeout : Time::Span = 5.seconds)
      @bot.enchant(spec, option: option, timeout: timeout)
    end

    # Selects an inventory item through a detached predicate argument.
    def enchant(spec : Rosegold::Slot -> _, *, option : Int32, timeout : Time::Span = 5.seconds)
      enchant(option: option, timeout: timeout) { |slot| spec.call(slot) }
    end

    # Selects the inventory item to enchant with an inventory-only predicate.
    def enchant(*, option : Int32, timeout : Time::Span = 5.seconds, &spec : Rosegold::Slot -> _)
      @bot.enchant(option: option, timeout: timeout) { |slot| spec.call(InventorySnapshot.copy(slot)) }
    end

    # Opens the aimed-at container and closes it after the block exits.
    def open_container(timeout : Time::Span = 5.seconds, &) : Nil
      @bot.open_container(timeout) { yield }
      nil
    end

    # Opens a container and yields only its restricted handle.
    def open_container_handle(timeout : Time::Span = 5.seconds, &) : Nil
      @bot.open_container_handle(timeout) { |handle| yield ContainerHandle.new(handle) }
      nil
    end

    # Opens a command-driven container and yields its restricted handle.
    def open_container_handle(command : String, timeout : Time::Span = 5.seconds, &) : Nil
      @bot.open_container_handle(command, timeout) { |handle| yield ContainerHandle.new(handle) }
      nil
    end

    # Runs a command and checks only server chat for confirmation.
    def run_command_with_confirmation(command : String, expected_message : String, max_tries : Int32 = 3, inverse_message : String? = nil)
      @bot.run_command_with_confirmation(command, expected_message, max_tries, inverse_message)
    end

    # Starts a loopback-only viewer for a human Minecraft client.
    def start_spectating(port : Int32 = 25566) : Nil
      raise "Spectator already started" if @spectator
      server = Rosegold::SpectateServer.new("127.0.0.1", port)
      server.attach_client(@bot.client)
      server.start
      @spectator = server
      nil
    end

    # Stops the human viewer without exposing its relay or client.
    def stop_spectating : Nil
      @spectator.try(&.stop)
      @spectator = nil
      nil
    end
  end
end

module Rosegold::CivMC
  # Directional input state without a reference to the physics controller.
  class MovementKeys
    def initialize(@keys : Rosegold::MovementKeys); end

    delegate state, forward?, backward?, left?, right?, none?, to: @keys

    # Tests the supplied directional input flags.
    def pressed?(keys : Rosegold::MovementKeys::Key) : Bool
      @keys.pressed?(keys)
    end

    # Sets the directional input flags.
    def state=(value : Rosegold::MovementKeys::Key)
      @keys.state = value
    end

    # Presses the supplied movement inputs.
    def press(*keys : Rosegold::MovementKeys::Key) : Nil
      @keys.press(*keys)
      nil
    end

    # Releases the supplied movement inputs.
    def release(*keys : Rosegold::MovementKeys::Key) : Nil
      @keys.release(*keys)
      nil
    end

    # Releases all directional inputs.
    def release_all : Nil
      @keys.release_all
      nil
    end
  end
end
