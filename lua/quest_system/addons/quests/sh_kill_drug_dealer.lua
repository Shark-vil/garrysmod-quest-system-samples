local language_data = {
	['default'] = {
		['title'] = 'Kill drug dealer',
		['description'] = 'There was an order to kill a drug dealer. Use the scrap given to you for this, if you do not have it.',
		['spawn_construct_tilte'] = 'The enemy is close',
		['spawn_construct_description'] = 'The drug dealer is somewhere nearby. Find and kill him.',
		['spawn_dealer_name'] = 'Drug dealer',
		['spawn_dealer_text'] = 'Damn, a round-up! Hey, whoever it is, I\'ll defend myself!',
		['failed_title'] = 'Failed',
		['failed_description'] = 'You used the wrong weapon.',
		['success_title'] = 'Completed',
		['complete'] = 'The drug dealer was terminated. Our customer will be satisfied.',
		['compensation'] = 'The drug dealer was eliminated, but not by you. You will receive compensation for the task.',
	},
	['russian'] = {
		['title'] = 'Убить наркоторговца',
		['description'] = 'Поступил заказ на убийство наркоторговца. Используйте для этого выданный вам лом, если его у вас нет.',
		['spawn_construct_tilte'] = 'Враг близко',
		['spawn_construct_description'] = 'Наркоторговец где-то поблизости. Найдите и убейте его.',
		['spawn_dealer_name'] = 'Наркодилер',
		['spawn_dealer_text'] = 'Чёрт, облава! Эй, кто бы там ни был, я буду защищаться!',
		['failed_title'] = 'Провалено',
		['failed_description'] = 'Вы использовали не то оружие.',
		['success_title'] = 'Завершено',
		['complete'] = 'Наркоторговец был устранён. Наш заказчик будет доволен.',
		['compensation'] = 'Наркоторговец был устранён, но не вами. Вы получите компенсацию за задание.',
	}
}

local quest = {
	id = 'kill_drug_dealer',
	lang = language_data,
	title = 'title',
	description = 'description',
	payment = 500,
	steps = {
		start = {
			onStart = function(eQuest)
				if CLIENT then return end
				eQuest:GiveQuestWeapon('weapon_crowbar')
			end,
			triggers = {
				spawn_dealer_trigger = {
					onStart = function(eQuest, center)
						if CLIENT then return end
						eQuest:SetArrow(center)
					end,
					onEnter = function(eQuest, ent)
						if CLIENT or ent ~= eQuest:GetPlayer() then return end
						eQuest:NextStep('spawn')
					end,
				}
			}
		},
		spawn = {
			structures = {
				barricades = true
			},
			onStart = function(eQuest)
				if SERVER then return end
				eQuest:Notify('spawn_construct_tilte', 'spawn_construct_description')
			end,
			points = {
				spawn_dealer = function(eQuest, positions)
					if CLIENT then return end

					local npc = eQuest:SpawnQuestNPC('npc_citizen', {
						pos = positions,
						weapon_class = 'weapon_pistol',
						type = 'enemy'
					})

					eQuest:SetArrow(npc)
					QuestDialogue:SingleReplic(eQuest:GetPlayer(), npc, 'spawn_dealer_name', 'spawn_dealer_text', 6)
				end,
			},
			onQuestNPCKilled = function(eQuest, data, attacker, inflictor)
				if CLIENT then return end

				if not eQuest:QuestNPCIsAlive('enemy') then
					if eQuest:GetPlayer() == attacker then
						if not eQuest:IsQuestWeapon(attacker:GetActiveWeapon()) then
							eQuest:Notify('failed_title', 'failed_description')
							eQuest:Failed()
						else
							eQuest:NextStep('complete')
						end
					else
						eQuest:NextStep('compensation')
					end
				end
			end
		},
		complete = {
			onStart = function(eQuest)
				if CLIENT then
					eQuest:Notify('success_title', 'complete')
					return
				end

				eQuest:Reward()
				eQuest:Complete()
			end,
		},
		compensation = {
			onStart = function(eQuest)
				if CLIENT then
					eQuest:Notify('success_title', 'compensation')
					return
				end

				eQuest:Reparation()
				eQuest:Complete()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)