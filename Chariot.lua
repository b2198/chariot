local chariot = SMODS.current_mod
local to_big = to_big or function(x) return x end
chariot.config_tab = function()
    return {n = G.UIT.ROOT, config = {r = 0.1, minw = 5, align = "cm", padding = 0.2, colour = G.C.BLACK}, nodes = {
        create_option_cycle({
            label = localize('chariot_spend_limit'),
            options = chariot.config.spend_limit_opts,
            w = 4.5,
            opt_callback = 'chariot_change_spend_limit',
            focus_args = { snap_to = true, nav = 'wide' },
            current_option = chariot.config.spend_limit_index,
            colour = G.C.RED,
        })
    }}
end
G.FUNCS.chariot_change_spend_limit = function(e)
    chariot.config.spend_limit_index = e.cycle_config.current_option
    chariot.config.spend_limit = chariot.config.spend_limit_opts[chariot.config.spend_limit_index]
    SMODS.save_mod_config(chariot)
end

local cc = Card.click
function Card:click()
    if self.area and self.area.config.collection and G.STATE == G.STATES.SHOP then
        G.FUNCS.exit_overlay_menu()
        local key = self.config.center.key
        local edition = self.edition
        G.E_MANAGER:add_event(Event({
            func = function()
                -- Checks "key == edition.key" to account for cases in which the joker can appear in
                -- the collection with an edition.
                -- The "not edition.key" case happens with Too Many Jokers.
                chariot.reroll(
                    key,
                    edition and (key == edition.key or not edition.key)
                )
                return true
            end
        }))
    end
    return cc(self)
end

local opt = G.FUNCS.options
G.FUNCS.options = function(e)
    if chariot.reroll_active then chariot.cancel_reroll = true end
    return opt(e)
end

chariot.reroll = function(key, is_edition)
    chariot.reroll_active = true
    if chariot.cancel_reroll then
        chariot.cancel_reroll = nil
        chariot.reroll_active = nil
        return
    end
    if G.GAME.current_round.reroll_cost%10000 == 0 then print(G.GAME.current_round.reroll_cost) end
    local spend_limit_reached = (
        to_big(G.GAME.dollars - G.GAME.current_round.reroll_cost) <
        to_big(math.max(chariot.config.spend_limit, 0))
    )
    if(
        is_edition and chariot.edition_in_shop(key) or
        chariot.card_in_shop(key) or
        spend_limit_reached
    ) then
        chariot.reroll_active = nil
        return
    end
    G.FUNCS.reroll_shop()
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 1,
        func = function()
            chariot.reroll(key, is_edition)
            return true
        end
    }))
end

chariot.card_in_shop = function(key)
    if G.STATE ~= G.STATES.SHOP or not G.shop_jokers or not G.shop_jokers.cards then return end
    for _,v in ipairs(G.shop_jokers.cards) do
        if v.config.center_key == key then return true end
    end
end

chariot.edition_in_shop = function(key)
    if G.STATE ~= G.STATES.SHOP or not G.shop_jokers or not G.shop_jokers.cards then return end
    for _,v in ipairs(G.shop_jokers.cards) do
        if v.edition and v.edition.key == key then return true end
    end
end