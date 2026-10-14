module Rosegold::CivMC
  module InventorySnapshot
    # Round-trip components too: a shallow slot copy shares mutable inventory state.
    def self.detached(slot : Rosegold::Slot) : Rosegold::Slot
      io = Minecraft::IO::Memory.new
      slot.write(io)
      io.rewind
      Rosegold::Slot.read(io)
    end

    def self.copy(slot : Rosegold::Slot) : Rosegold::Slot
      detached(slot)
    end

    def self.copy(slot : Rosegold::WindowSlot) : Rosegold::WindowSlot
      Rosegold::WindowSlot.new(slot.slot_number, detached(slot))
    end
  end

  class Menu
    def initialize(@menu : Rosegold::Menu)
    end

    delegate id, menu_id, total_slots, player_inventory_start, offhand_slot_index,
      hotbar_slot_index, crafting_grid_range, to: @menu

    {% for name in %w(cursor main_hand) %}
      def {{name.id}}
        InventorySnapshot.copy(@menu.{{name.id}})
      end
    {% end %}

    {% for name in %w(slots content inventory hotbar container_slots inventory_slots hotbar_window_slots player_window_slots player_inventory_slots hotbar_slots main_inventory_slots) %}
      def {{name.id}}
        @menu.{{name.id}}.map { |slot| InventorySnapshot.copy(slot) }
      end
    {% end %}

    def [](index : Int32)
      InventorySnapshot.copy(@menu[index])
    end

    def send_click(slot_index : Int32, operation : Rosegold::ClickOperation) : Nil
      @menu.send_click(slot_index, operation)
      nil
    end

    def send_click(slot_index : Int32, button : Int32, click_type) : Nil
      @menu.send_click(slot_index, button, click_type)
      nil
    end

    def swap_hotbar(hotbar_nr : Int32, slot_number : Int32) : Nil
      @menu.swap_hotbar(hotbar_nr, slot_number)
      nil
    end

    def swap_hotbar(hotbar_nr : Int32, slot : Rosegold::WindowSlot) : Nil
      swap_hotbar(hotbar_nr, slot.slot_number)
    end

    def close : Nil
      @menu.close
      nil
    end
  end

  {% for entry in { {"ChestMenu", {"contents"}, [] of String}, {"CraftingMenu", {"grid"}, {"result"}}, {"FurnaceMenu", [] of String, {"ingredient", "fuel", "result"}}, {"AnvilMenu", [] of String, {"first_input", "second_input", "result"}}, {"BrewingStandMenu", {"bottles"}, {"ingredient", "fuel"}}, {"EnchantmentMenu", [] of String, {"item", "lapis"}}, {"HopperMenu", {"contents"}, [] of String}, {"MerchantMenu", [] of String, {"first_input", "second_input", "result"}} } %}
    class {{entry[0].id}} < Menu
      def initialize(@typed_menu : Rosegold::{{entry[0].id}})
        super(@typed_menu)
      end

      {% for name in entry[1] %}
        def {{name.id}}
          @typed_menu.{{name.id}}.map { |slot| InventorySnapshot.copy(slot) }
        end
      {% end %}

      {% for name in entry[2] %}
        def {{name.id}}
          InventorySnapshot.copy(@typed_menu.{{name.id}})
        end
      {% end %}
    end
  {% end %}

  class ChestMenu
    delegate rows, to: @typed_menu
  end

  class FurnaceMenu
    # Values stay unknown until the server sends the corresponding property.
    {% for name, index in {"fuel_ticks_remaining" => 0, "fuel_ticks_total" => 1, "cook_ticks" => 2, "cook_ticks_total" => 3} %}
      def {{name.id}} : Int16?
        @typed_menu.properties[{{index}}_i16]?
      end
    {% end %}
  end

  class BrewingStandMenu
    def brewing_ticks : Int16?
      @typed_menu.properties[0_i16]?
    end

    def fuel_uses_remaining : Int16?
      @typed_menu.properties[1_i16]?
    end
  end

  class AnvilMenu
    def level_cost : Int16?
      @typed_menu.properties[0_i16]?
    end
  end

  class EnchantmentMenu
    delegate offers, to: @typed_menu

    def enchant(option : Int32, timeout : Time::Span = 5.seconds) : Rosegold::Slot
      InventorySnapshot.copy(@typed_menu.enchant(option, timeout))
    end
  end

  class MerchantMenu
    delegate villager_level, villager_xp, show_progress?, can_restock?, to: @typed_menu

    def trades
      @typed_menu.trades.map do |offer|
        io = Minecraft::IO::Memory.new
        offer.write(io)
        io.rewind
        Rosegold::Clientbound::MerchantOffers::MerchantOffer.read(io)
      end
    end

    def select_trade(index : Int32) : Nil
      @typed_menu.select_trade(index)
      nil
    end
  end

  class Inventory
    def initialize(@inventory : Rosegold::Inventory)
    end

    {% for name in %w(cursor main_hand helmet chestplate leggings boots off_hand) %}
      def {{name.id}}
        InventorySnapshot.copy(@inventory.{{name.id}})
      end
    {% end %}

    {% for name in %w(slots content inventory hotbar container_slots inventory_slots hotbar_window_slots player_window_slots player_inventory_slots hotbar_slots main_inventory_slots) %}
      def {{name.id}}
        @inventory.{{name.id}}.map { |slot| InventorySnapshot.copy(slot) }
      end
    {% end %}

    def [](index : Int32)
      InventorySnapshot.copy(@inventory[index])
    end

    def count(spec, slots = player_inventory_slots)
      slots.select(&.matches?(spec)).sum(&.count.to_i32)
    end

    def count(&spec : Rosegold::Slot -> _)
      count(spec)
    end

    {% for name in %w(pick pick!) %}
      def {{name.id}}(spec : String | UInt32)
        @inventory.{{name.id}}(spec)
      end

      def {{name.id}}(&spec : Rosegold::Slot -> _)
        @inventory.{{name.id}} { |slot| spec.call(InventorySnapshot.copy(slot)) }
      end

      def {{name.id}}(spec : Rosegold::Slot -> _)
        {{name.id}} { |slot| spec.call(slot) }
      end
    {% end %}

    {% for name in %w(withdraw_at_least deposit_at_least replenish) %}
      def {{name.id}}(count, spec : String | UInt32)
        @inventory.{{name.id}}(count, spec)
      end

      def {{name.id}}(count, &spec : Rosegold::Slot -> _)
        @inventory.{{name.id}}(count) { |slot| spec.call(InventorySnapshot.copy(slot)) }
      end

      def {{name.id}}(count, spec : Rosegold::Slot -> _)
        {{name.id}}(count) { |slot| spec.call(slot) }
      end
    {% end %}

    delegate refill_hand, throw_all_of, to: @inventory

    def send_click(slot_index : Int32, operation : Rosegold::ClickOperation) : Nil
      @inventory.send_click(slot_index, operation)
      nil
    end

    def send_click(slot_index : Int32, button : Int32, click_type) : Nil
      @inventory.send_click(slot_index, button, click_type)
      nil
    end

    def swap_hotbar(hotbar_nr : Int32, slot_number : Int32) : Nil
      @inventory.swap_hotbar(hotbar_nr, slot_number)
      nil
    end

    def swap_hotbar(hotbar_nr : Int32, slot : Rosegold::WindowSlot) : Nil
      swap_hotbar(hotbar_nr, slot.slot_number)
    end

    def close : Nil
      @inventory.close
      nil
    end
  end

  class ContainerHandle
    def initialize(@handle : Rosegold::ContainerHandle)
    end

    def menu : Menu
      Menu.new(@handle.menu)
    end

    {% for type in %w(chest crafting furnace anvil brewing_stand enchantment hopper merchant) %}
      def as_{{type.id}}
        @handle.as_{{type.id}}.try { |value| {{type.camelcase.id}}Menu.new(value) }
      end
    {% end %}

    {% for name in %w(find_in_container find_in_inventory) %}
      def {{name.id}}(spec : String | UInt32)
        @handle.{{name.id}}(spec).try { |slot| InventorySnapshot.copy(slot) }
      end

      def {{name.id}}(&spec : Rosegold::Slot -> _)
        predicate = ->(slot : Rosegold::Slot) { !!spec.call(InventorySnapshot.copy(slot)) }
        @handle.{{name.id}}(predicate).try { |slot| InventorySnapshot.copy(slot) }
      end

      def {{name.id}}(spec : Rosegold::Slot -> _)
        {{name.id}} { |slot| spec.call(slot) }
      end
    {% end %}

    {% for name in %w(count_in_container count_in_player) %}
      def {{name.id}}(spec : String | UInt32)
        @handle.{{name.id}}(spec)
      end

      def {{name.id}}(&spec : Rosegold::Slot -> _)
        predicate = ->(slot : Rosegold::Slot) { !!spec.call(InventorySnapshot.copy(slot)) }
        @handle.{{name.id}}(predicate)
      end

      def {{name.id}}(spec : Rosegold::Slot -> _)
        {{name.id}} { |slot| spec.call(slot) }
      end
    {% end %}

    {% for name in %w(withdraw deposit) %}
      def {{name.id}}(spec : String | UInt32, count : Int32 = Int32::MAX) : Int32
        @handle.{{name.id}}(spec, count)
      end

      def {{name.id}}(count : Int32 = Int32::MAX, &spec : Rosegold::Slot -> _) : Int32
        predicate = ->(slot : Rosegold::Slot) { !!spec.call(InventorySnapshot.copy(slot)) }
        @handle.{{name.id}}(predicate, count)
      end

      def {{name.id}}(spec : Rosegold::Slot -> _, count : Int32 = Int32::MAX) : Int32
        {{name.id}}(count) { |slot| spec.call(slot) }
      end
    {% end %}

    {% for name in %w(pickup put_down) %}
      def {{name.id}}(slot : Int32, count : Int32 = Int32::MAX) : Nil
        @handle.{{name.id}}(slot, count)
        nil
      end
    {% end %}

    {% for name in %w(quick_move swap_with_offhand) %}
      def {{name.id}}(slot : Int32) : Nil
        @handle.{{name.id}}(slot)
        nil
      end
    {% end %}

    def swap_with_hotbar(slot : Int32, hotbar_slot : Int32) : Nil
      @handle.swap_with_hotbar(slot, hotbar_slot)
      nil
    end

    def drop(slot : Int32, full_stack : Bool = false) : Nil
      @handle.drop(slot, full_stack)
      nil
    end

    def close : Nil
      @handle.close
      nil
    end
  end
end
