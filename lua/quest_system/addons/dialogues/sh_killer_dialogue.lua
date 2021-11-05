local lang = slib.language({
	['default'] = {
		['name'] = 'Killer',
		['start'] = {'I suppose you have business with me?', 'What do you need?'},
		['start_answers_1'] = 'I want to order a murder ...',
		['select_target'] = 'Whoa, right like that? And who is this lucky one?',
		['select_target_cancel'] = 'Sorry, I changed my mind.',
		['select_target_prefix'] = 'This ',
		['finish_select'] = 'So this is %player%, ok, the order is accepted.',
		['cancel'] = 'Maybe this is the right decision. Goodbye.',
	},
	['russian'] = {
		['name'] = 'Киллер',
		['start'] = {'Я полагаю, у тебя есть ко мне дело?', 'Что нужно?'},
		['start_answers_1'] = 'Я хочу заказать убийство...',
		['select_target'] = 'Ого вот так прямо? И кто же этот счастливчик?',
		['select_target_cancel'] = 'Прости, я передумал.',
		['select_target_prefix'] = 'Это ',
		['finish_select'] = 'Значит это %player%, хорошо, заказ принят.',
		['cancel'] = 'Может оно и к лучшему. Бывай.',
	}
})

local conversation = {
	id = 'killer',
	name = lang['name'],
	auto_parent = true,
	parent_chance = 30,
	class = 'npc_citizen',
	condition = function(ply, npc)
		if not bgNPC then return false end

		local actor = bgNPC:GetActor(npc)
		if not actor then
			if not slib.chance(30) then return false end
			actor = BGN_ACTOR:Instance(npc, 'gangster')
		end

		return actor:GetType() == 'gangster'
	end,
	steps = {
		start = {
			text = lang['start'],
			answers = {
				{
					text = lang['start_answers_1'],
					event = function(eDialogue)
						if CLIENT then return end
						eDialogue:Next('select_target')
					end
				},
			},
		},
		select_target = {
			text = lang['select_target'],
			answers = function()
				local result = {}

				table.insert(result, {
					text = lang['select_target_cancel'],
					event = function(eDialogue)
						if CLIENT then return end
						eDialogue:Next('cancel')
					end
				})

				for _, ply in ipairs(player.GetAll()) do
					table.insert(result, {
						text = lang['select_target_prefix'] .. ply:Nick(),
						event = function(eDialogue)
							if CLIENT then return end
							eDialogue:slibSetVar('murder_target', ply)
							eDialogue:Next('finish_select')
						end
					})
				end

				return result
			end
		},
		finish_select = {
			text = function(eDialogue)
				local ply = eDialogue:slibGetVar('murder_target')
				return string.Replace(lang['finish_select'], '%player%',  ply:Nick())
			end,
			delay = 3.5,
			eventDelay = function(eDialogue)
				if CLIENT then return end
				local ply = eDialogue:slibGetVar('murder_target')
				local npc = eDialogue:GetNPC()
				local actor = bgNPC:GetActor(npc)
				eDialogue:Stop()

				timer.Simple(1, function()
					actor:AddEnemy(ply, nil, true)
					actor:SetState('killer')
				end)
			end
		},
		cancel = {
			text = lang['cancel'],
			delay = 3.5,
			eventDelay = function(eDialogue)
				if CLIENT then return end
				eDialogue:Stop()
			end
		}
	}
}

list.Set('QuestSystemDialogue', conversation.id, conversation)