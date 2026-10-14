import pathlib
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
CASES = {
    "client": ("bot.client", "undefined method 'client'"),
    "world": ("bot.world", "undefined method 'world'"),
    "block": ("bot.block_at(Rosegold::Vec3i.new(0, 0, 0))", "undefined method 'block_at'"),
    "subscribe": ("bot.subscribe(Rosegold::Event::RawPacket)", "undefined method 'subscribe'"),
    "raw_on": ("bot.on(Rosegold::Event::RawPacket) { |event| }", "not Rosegold::Event::RawPacket.class"),
    "raw_once": ("bot.once(Rosegold::Event::RawPacket) { |event| }", "not Rosegold::Event::RawPacket.class"),
    "raw_wait": ("bot.wait_for(Rosegold::Event::RawPacket)", "not Rosegold::Event::RawPacket.class"),
    "event_registry": ("bot.event_handlers", "undefined method 'event_handlers'"),
    "inventory_client": ("bot.inventory.client", "undefined method 'client'"),
    "inventory_update": ("bot.inventory.update_slot(0, Rosegold::Slot.new, 0_u32)", "undefined method 'update_slot'"),
    "menu_client": ("bot.on(Rosegold::CivMC::ContainerOpened) { |event| event.menu.client }", "undefined method 'client'"),
    "menu_properties": ("bot.on(Rosegold::CivMC::ContainerOpened) { |event| event.menu.properties }", "undefined method 'properties'"),
    "join_return": ("bot.join_game.client", "undefined method 'client'"),
    "join_yield": ("bot.join_game { |connected| connected.client }", "undefined method 'client'"),
    "future_core_method": ("class Rosegold::Bot\n  def new_unrestricted_method\n    client\n  end\nend\nbot.new_unrestricted_method", "undefined method 'new_unrestricted_method'"),
    "entities": ("bot.entities", "undefined method 'entities'"),
    "raw_emit": ("bot.emit_event(Rosegold::Event::RawPacket.new(Bytes.empty))", "undefined method 'emit_event'"),
    "raw_off": ("bot.off(Rosegold::Event::RawPacket, UUID.random)", "not Rosegold::Event::RawPacket.class"),
    "raw_action_wait": ("bot.wait_for(Rosegold::Event::RawPacket) { bot.chat(\"hello\") }", "not Rosegold::Event::RawPacket.class"),
    "core_constructor": ("Rosegold::CivMC::Bot.new(Rosegold::Bot.new(\"localhost:25565\"))", "not Rosegold::Bot"),
    "client_constructor": ("Rosegold::CivMC::Bot.new(Rosegold::Client.new(\"localhost:25565\"))", "not Rosegold::Client"),
    "handle_menu_client": ("bot.open_container_handle { |handle| handle.menu.client }", "undefined method 'client'"),
    "handle_menu_properties": ("bot.open_container_handle { |handle| handle.menu.properties }", "undefined method 'properties'"),
    "typed_chest_client": ("bot.open_container_handle { |handle| handle.as_chest.not_nil!.client }", "undefined method 'client'"),
    "typed_enchant_seed": ("bot.open_container_handle { |handle| handle.as_enchantment.not_nil!.properties }", "undefined method 'properties'"),
    "typed_menu_unwrap": ("bot.open_container_handle { |handle| handle.as_furnace.not_nil!.menu }", "undefined method 'menu'"),
    "spectator_return": ("bot.start_spectating.client", "undefined method 'client' for Nil"),
    "keys_client": ("bot.keys.client", "undefined method 'client'"),
    "gamemode": ("bot.gamemode", "undefined method 'gamemode'"),
    "break_estimate": ("bot.estimated_break_ticks(\"stone\")", "undefined method 'estimated_break_ticks'"),
    "block_pick": ("bot.pick_item_from_block(Rosegold::Vec3i.new(0, 0, 0))", "undefined method 'pick_item_from_block'"),
    "selection_predicate_client": ("bot.inventory.pick(->(slot : Rosegold::Slot) { slot.client; true })", "undefined method 'client' for Rosegold::Slot"),
    "enchant_predicate_client": ("bot.enchant(->(slot : Rosegold::Slot) { slot.client; true }, option: 2)", "undefined method 'client' for Rosegold::Slot"),
}


def compile_source(source):
    with tempfile.NamedTemporaryFile(mode="w", suffix=".cr", dir=ROOT, delete=False) as fixture:
        fixture.write(f'require "./src/rosegold-civmc"\nbot = Rosegold::CivMC::Bot.new("localhost:25565")\n{source}\n')
        path = pathlib.Path(fixture.name)
    try:
        return subprocess.run(["crystal", "build", "--no-codegen", "--no-color", str(path)], cwd=ROOT, capture_output=True, text=True)
    finally:
        path.unlink()


baseline = compile_source('''
bot.on(Rosegold::Event::HealthChanged) { |event| puts event.health }
bot.start_using_hand(:main_hand)
bot.use_hand(hand: :off_hand)
bot.place_block_against(Rosegold::Vec3i.new(0, 0, 0), :top)
bot.keys.press(:forward)
bot.keys.release(:forward)
bot.keys.state = :forward
bot.keys.pressed?(:forward)
bot.raise_level_with("emerald", 30)
bot.elevator(10)
bot.open_container_handle { |handle| handle.as_chest.try(&.contents) }
bot.enchant("diamond_pickaxe", option: 2)
bot.enchant(option: 2) { |slot| slot.name == "diamond_pickaxe" }
bot.enchant(->(slot : Rosegold::Slot) { slot.name == "diamond_pickaxe" }, option: 2)
bot.start_spectating
bot.stop_spectating
''')
if baseline.returncode:
    raise SystemExit(baseline.stdout + baseline.stderr)
print("PASS permitted workflows")
if "--positive-only" in sys.argv:
    raise SystemExit(0)
for name, (source, diagnostic) in CASES.items():
    result = compile_source(source)
    output = result.stdout + result.stderr
    if result.returncode == 0 or diagnostic not in output:
        raise SystemExit(f"{name}: expected rejection containing {diagnostic!r}\n{output}")
    print(f"PASS {name}")
