local language_data = {
	['default'] = {
		['title'] = 'Kill drug dealer',
		['description'] = 'A detachment of enemy combines has landed somewhere. Find and eliminate them!',
		['cancel_title'] = 'Event canceled',
		['cancel_description'] = 'The event did not take place due to a lack of players in the event area.',
		['spawn_combines_title'] = 'The enemy is close',
		['spawn_combines_description'] = 'Kill the arriving enemies',
		['complete_title'] = 'Completed',
		['complete_description'] = 'All enemies were killed',
		['enter_zone_title'] = 'You entered the event area',
		['enter_zone_description'] = 'Expect the start of the event and do not leave the area.',
		['exit_zone_title'] = 'You left the event area',
		['exit_zone_description'] = 'Return to the event area to participate in it.',
	},
	['russian'] = {
		['title'] = 'Убить комбайнов',
		['description'] = 'Где-то высадился отряд вражеских комбайнов. Найдите и устраните их!',
		['cancel_title'] = 'Событие отменено',
		['cancel_description'] = 'Событие не состоялось из-за нехватки игроков в зоне ивента.',
		['spawn_combines_title'] = 'Враг близко',
		['spawn_combines_description'] = 'Убейте прибывших противников',
		['complete_title'] = 'Завершено',
		['complete_description'] = 'Все противники были уничтожены',
		['enter_zone_title'] = 'Вы вошли в зону ивента',
		['enter_zone_description'] = 'Ожидайте начало ивента и не покидайте зону.',
		['exit_zone_title'] = 'Вы покинули зону ивента',
		['exit_zone_description'] = 'Вернитесь в зону ивента, чтобы участвовать в нём.',
	}
}

local lang = slib.language(language_data)

local quest = {
	id = 'event_kill_combine',
	title = lang['title'],
	description = lang['description'],
	payment = 500,
	is_event = true,
	auto_add_players = false,
	npc_ignore_other_players = true,
	auto_next_step_delay = 60,
	auto_next_step = 'spawn_combines',
	-- auto_next_step_validaotr = function(eQuest)
	-- 	local count = #eQuest.players

	-- 	if count == 0 then
	-- 		for _, ply in ipairs(player.GetHumans()) do
	-- 			local player_language = ply:slibLanguage(language_data)
	-- 			ply:QuestNotify(player_language['cancel_title'], player_language['cancel_description'])
	-- 		end
	-- 	end

	-- 	return count ~= 0
	-- end,
	quest_time = 120,
	failed_text = {
		title = 'Quest failed :(',
		text = 'The execution time has expired.'
	},
	steps = {
		start = {
			onEnd = function(eQuest)
				if CLIENT then return end
				if #eQuest.players == 0 then
					eQuest:Failed()
					return true
				end
			end,
			triggers = {
				spawn_combines_trigger = {
					onStart = function(eQuest, center)
						if CLIENT then return end
						eQuest:SetArrowVector(center)
					end,
					onEnter = function(eQuest, ply)
						if CLIENT or not ply:IsPlayer() then return end
						eQuest:AddPlayer(ply)

						local player_language = ply:slibLanguage(language_data)
						ply:QuestNotify(player_language['enter_zone_title'], player_language['enter_zone_description'])
					end,
					onExit = function(eQuest, ply)
						if CLIENT or not eQuest:HasQuester(ply) then return end
						eQuest:RemovePlayer(ply)

						local player_language = ply:slibLanguage(language_data)
						ply:QuestNotify(player_language['exit_zone_title'], player_language['exit_zone_description'])
					end
				},
			},
		},
		spawn_combines = {
			onStart = function(eQuest)
				if SERVER then return end
				eQuest:NotifyOnlyRegistred(lang['spawn_combines_title'], lang['spawn_combines_description'])
			end,
			structures = {
				barricades = true
			},
			points = {
				spawn_combines = function(eQuest, positions)
					if CLIENT then return end

					for _, pos in ipairs(positions) do
						eQuest:SpawnQuestNPC('npc_combine_s', {
							type = 'enemy',
							pos = pos,
							model = table.RandomBySeq({
								'models/Combine_Soldier.mdl',
								'models/Combine_Soldier_PrisonGuard.mdl',
								'models/Combine_Super_Soldier.mdl'
							}),
							weapon_class = table.RandomBySeq({
								'weapon_ar2',
								'weapon_shotgun'
							})
						})
					end

					eQuest:MoveEnemyToRandomPlayer()
				end,
			},
			hooks = {
				OnNPCKilled = function(eQuest, npc, attacker, inflictor)
					if SERVER and not eQuest:IsAliveQuestNPC('enemy') then
						eQuest:NextStep('complete')
					end
				end
			}
		},
		complete = {
			onStart = function(eQuest)
				if CLIENT then
					eQuest:Notify(lang['complete_title'], lang['complete_description'])
					return
				end

				eQuest:Reward()
				eQuest:Complete()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)