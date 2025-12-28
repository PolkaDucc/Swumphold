extends Node

#ts is for all the signals that any scripts can connect to :D (below u can find ways to cheat on your girlfri

#combat signals
signal enemy_damaged(enemy, damage, source)
signal enemy_killed(enemy)
signal player_damaged(amount, source)
signal player_healed(amount)

#weapon signals
signal weapon_fired(weapon_data)
signal weapon_reloaded(weapon_data)
signal weapon_swapped(old_weapon, new_weapon)

#economy signals
signal gm_changed(new_amount)
signal duumite_changed(new_amount)

#room/stage signals
signal room_cleared
signal stage_completed(stage_index)
signal wave_started(wave_number)
signal wave_completed(wave_number)
