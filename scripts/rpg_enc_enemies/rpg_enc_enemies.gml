function ex_enemy_dustling() : enemy() constructor {
    name = "Dustling"
    obj  = o_actor_e_virovirokun

    hp     = 20
    max_hp = 20
    attack = 4
    defense = 1
    // element = ELEMENT.NONE     ← removido, campo é opcional (default undefined)
    carrying_money = 15

    mercy = 0
    can_spare = function() { return mercy >= 100 }
    no_mercy_text = "* (Não está pronto para ser poupado ainda.)"

    dialogue = function(slot) {
        if o_enc.turn_count == 0
            return "* Um Dustling te encara, nervoso."
        return choose(
            "* O Dustling treme.",
            "* O Dustling parece querer sair dali."
        )
    }

    // sprites — trio confirmado no guia
    s_idle  = spr_e_virovirokun_idle
    s_hurt  = spr_e_virovirokun_hurt
    s_spare = spr_e_virovirokun_spare

    acts = [
        {
            name: "Check",
            desc: "Dustling. Ataque 4, Defesa 1. Parece assustado.",
            party: [],
            tp_cost: 0,
            enabled: true,
            exec: function(enemy_slot, user_index) {}
        },
        {
            name: "Acalmar",
            desc: "Fala com calma pro Dustling relaxar.",
            party: [],
            tp_cost: 0,
            enabled: true,
            exec: function(enemy_slot, user_index) {
                enc_enemy_add_spare(enemy_slot, 60)
            }
        }
    ]

    turn_object = o_turn_default   // confirmado no guia
    recruit = new enemy_recruit()

    ev_hurt = function(dmg) {}
    ev_win = function() {}
}


function ex_enc_set_dustling() : enc_set() constructor {
    debug_name = "dustling_tutorial"
    enemies = [ new ex_enemy_dustling() ]

    flavor = function() {
        if o_enc.turn_count == 0
            return "* Um encontro tímido."
        return "* O Dustling ainda está ali."
    }

    enemies_pos = [ [0, 0, true] ]
    bgm = mus_ex_spawn
}