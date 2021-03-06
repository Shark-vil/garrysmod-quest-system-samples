local language_data = {
	['default'] = {
		['title'] = 'Kill zombies',
		['description'] = 'Find and kill the zombie that bothers the locals. Any weapon can be used.',
		['spawn_construct_title'] = 'The enemy is close',
		['spawn_construct_description'] = 'Suddenly. There were more of them than in the order. But it doesn\'t matter, kill everyone.',
		['complete_title'] = 'Completed',
		['complete_description'] = 'Thanks for your help! This brat will not bother anyone anymore.',
	},
	['russian'] = {
		['title'] = 'Убить зомби',
		['description'] = 'Найдите и убейте зомби который докучает местным жителям. Можно использовать любое оружие.',
		['spawn_construct_title'] = 'Враг близко',
		['spawn_construct_description'] = 'Неожиданно. Их оказалось больше, чем в заказе. Но это не важно, убейте всех.',
		['complete_title'] = 'Завершено',
		['complete_description'] = 'Спасибо за вашу помощь! Больше это отродье не будет никому мешать.',
	}
}

local quest = {
	id = 'kill_zombie',
	lang = language_data,
	title = 'title',
	description = 'description',
	payment = 500,
	quest_time = 600,
	steps = {
		start = {
			triggers = {
				spawn_zombie_trigger = {
					onStart = function(eQuest, center)
						if CLIENT then return end
						eQuest:SetArrow(center)
					end,
					onEnter = function(eQuest, ent)
						if CLIENT then return end
						if ent ~= eQuest:GetPlayer() then return end
						eQuest:NextStep('spawn')
					end
				},
			}
		},
		spawn = {
			onStart = function(eQuest)
				if SERVER then return end
				eQuest:Notify('spawn_construct_title', 'spawn_construct_description')
			end,
			points = {
				spawn_zombie = function(eQuest, positions)
					if CLIENT then return end

					local index = 0

					for _, pos in pairs(positions) do
						index = index + 1
						if index > 5 and math.random(0, 1) == 1 then continue end

						eQuest:SpawnQuestNPC({'npc_zombie', 'npc_headcrab', 'npc_fastzombie'}, {
							pos = pos,
							type = 'enemy'
						})
					end

					eQuest:SetArrowNPC('enemy')
				end,
			},
			onQuestNPCKilled = function(eQuest, data, attacker, inflictor)
				if CLIENT or eQuest:QuestNPCIsAlive('enemy') then return end
				eQuest:NextStep('complete')
			end
		},
		complete = {
			onStart = function(eQuest)
				if CLIENT then
					eQuest:Notify('complete_title', 'complete_description')
					return
				end

				eQuest:Reward()
				eQuest:Complete()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)