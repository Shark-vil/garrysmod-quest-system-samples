local language_data = {
	['default'] = {
		['title'] = 'Find the box',
		['description'] = 'Our employer has lost his box of valuables. Find it and take it to the customer.',
		['spawn_enemy_title'] = 'Uninvited guests',
		['spawn_enemy_description'] = 'Oh no, it seems our customer has been attacked! Save him in order not to fail the mission.',
		['complete_title'] = 'Completed',
		['loss_description'] = 'You saved the client. Now you can place your order.',
		['give_box_title'] = 'Delivery',
		['give_box_description'] = 'The case is small. Find a client and give him the box.',
		['attack_on_the_customer_title'] = 'Completed',
		['attack_on_the_customer_description'] = 'Great, you found the box. Now take it to the customer.',
		['complete_description'] = 'You have successfully delivered your order to the recipient.',
		['failed_title'] = 'Провалено',
		['failed_description'] = 'The customer is dead, you will not receive a reward for completing it.',
	},
	['russian'] = {
		['title'] = 'Найти коробку',
		['description'] = 'Наш наниматель потерял свою коробку с ценными вещами. Найдите её и отнесите заказчику.',
		['spawn_enemy_title'] = 'Незваные гости',
		['spawn_enemy_description'] = 'О нет, кажется на нашего заказчика напали! Спасите его, чтобы не провалить задание.',
		['complete_title'] = 'Завершено',
		['loss_description'] = 'Вы спасли клиента. Теперь можете отдать заказ.',
		['give_box_title'] = 'Доставка',
		['give_box_description'] = 'Дело за малым. Найдите клиента и отдайте ему коробку.',
		['attack_on_the_customer_title'] = 'Завершено',
		['attack_on_the_customer_description'] = 'Отлично, вы нашли коробку. Теперь отнесите её заказчику.',
		['complete_description'] = 'Вы успешно доставили заказ получателю.',
		['failed_title'] = 'Провалено',
		['failed_description'] = 'Заказчик мёртв, вы не получите награду за выполнение.',
	}
}

local _customer_spawner = function(eQuest, positions)
	eQuest:QuestFunction('f_spawn_customer', eQuest, table.Random(positions))
end

local quest = {
	id = 'search_box',
	lang = language_data,
	title = 'title',
	description = 'description',
	payment = 500,
	npc_ignore_other_players = false,
	functions = {
		f_spawn_enemy_npcs = function(eQuest, ent)
			if ent ~= eQuest:GetPlayer() then return end
			if CLIENT then
				eQuest:Notify('spawn_enemy_title', 'spawn_enemy_description')
				return
			end

			eQuest:NextStep('safe_customer')
		end,
		f_loss_conditions = function(eQuest)
			if not eQuest:QuestNPCIsAlive('friend', 'customer') then
				if SERVER then
					eQuest:NextStep('failed')
				end
			elseif not eQuest:QuestNPCIsAlive('enemy') then
				if SERVER then
					eQuest:NextStep('give_box')
				else
					eQuest:Notify('complete_title', 'loss_description')
				end
			end
		end,
		f_spawn_customer = function(eQuest, pos)
			if CLIENT then return end
			if eQuest:QuestNPCIsAlive('friend', 'customer') then return end

			eQuest:SpawnQuestNPC('npc_citizen', {
				pos = pos,
				weapon_class = {
					'weapon_pistol',
					'weapon_smg1',
					'weapon_smg1',
					'weapon_shotgun',
					'weapon_357'
				},
				type = 'friend',
				tag = 'customer',
				health = '*2',
				onSpawn = function(_, data)
					local npc = data.npc
					eQuest:MoveQuestNpcToPosition(npc:GetPos(), 'enemy')
				end
			})
		end
	},
	steps = {
		start = {
			points = {
				spawn_quest_item_points = function(eQuest, positions)
					if CLIENT then return end

					local item = eQuest:SpawnQuestItem('quest_item', {
						id = 'box',
						model = 'models/props_junk/cardboard_box004a.mdl',
						pos = positions,
						ang = AngleRand()
					})
					-- item:SetFreeze(true)
					eQuest:SetArrow(item)
				end,
				customer = _customer_spawner,
			},
			onUseItem = function(eQuest, item, activator, caller, useType, value)
				if CLIENT then return end

				if eQuest:GetQuestItem('box') == item then
					item:FadeRemove()

					local customer = eQuest:GetQuestNpc('friend', 'customer')
					eQuest:SetArrow(customer)

					if slib.chance(50) then
						eQuest:SetVariable('is_customer_attack', true)
						eQuest:NextStep('attack_on_the_customer')
					else
						eQuest:NextStep('give_box')
					end
				end
			end,
		},
		attack_on_the_customer = {
			onStart = function(eQuest)
				if SERVER then return end
				eQuest:Notify('attack_on_the_customer_title', 'attack_on_the_customer_description')
			end,
			triggers = {
				spawn_enemy_trigger_on_enter = {
					onEnter = function(eQuest, ent)
						eQuest:QuestFunction('f_spawn_enemy_npcs', eQuest, ent)
					end
				},
			},
		},
		safe_customer = {
			structures = {
				barricades = true
			},
			points = {
				enemy = function(eQuest, positions)
					if CLIENT then return end

					for _, pos in ipairs(positions) do
						eQuest:SpawnQuestNPC('npc_combine_s', {
							pos = pos,
							weapon_class = 'weapon_ar2',
							type = 'enemy'
						})
					end
				end,
				customer = _customer_spawner,
			},
			onQuestNPCKilled = function(eQuest, data, attacker, inflictor)
				eQuest:QuestFunction('f_loss_conditions', eQuest)
			end,
		},
		give_box = {
			onStart = function(eQuest)
				if SERVER then return end
				eQuest:Notify('give_box_title', 'give_box_description')
			end,
			points = { customer = _customer_spawner },
			onUse = function(eQuest, ply, ent)
				if CLIENT then return end
				local npc = eQuest:GetQuestNpc('friend', 'customer')

				if IsValid(ent) and ent == npc then
					eQuest:NextStep('complete')
				end
			end,
			onQuestNPCKilled = function(eQuest, data, attacker, inflictor)
				eQuest:QuestFunction('f_loss_conditions', eQuest)
			end,
		},
		complete = {
			onStart = function(eQuest)
				if CLIENT then return end
				eQuest:Notify('complete_title', 'complete_description')

				if eQuest:GetVariable('is_customer_attack') then
					eQuest:Reward(nil, 500)
				else
					eQuest:Reward()
				end

				eQuest:Complete()
				eQuest:DisableArrowVector()
			end,
		},
		failed = {
			onStart = function(eQuest)
				if CLIENT then return end
				eQuest:Notify('failed_title', 'failed_description')
				eQuest:Failed()
				eQuest:DisableArrowVector()
			end,
		}
	}
}

list.Set('QuestSystem', quest.id, quest)