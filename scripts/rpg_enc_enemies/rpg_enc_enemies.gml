function rpg_enemy_sonso() : enemy() constructor {
    name = "Sonso"
    obj  = o_actor_e          // ator genérico da engine; serve perfeitamente

    // stats
    hp      = 60
    max_hp  = 60              // atenção ao underline: maxhp NÃO existe
    attack  = 4
    defense = 1
    carrying_money = 12

    // sprites (já existem no projeto)
    s_idle  = spr_ex_e_tasque
    s_hurt  = spr_ex_e_tasque_hurt
    s_spare = spr_ex_e_tasque_spared

	humor    = "sonso"     // "sonso" | "irritado" | "curioso"
    chamados = 0           // quantas vezes o jogador insistiu em chamar
	
    dialogue = method(self, function() {
        switch humor {
            case "irritado":
                return "* O Sonso bufa. As orelhas estão pra trás."

            case "curioso":
                return "* O Sonso finge olhar pro outro lado.";

            default:
                if o_enc.turn_count == 0
                    return "* Um gato te encara. Ele não parece impressionado."

                return choose(
                    "* O Sonso lambe a pata.",
                    "* O Sonso boceja.",
                    "* O Sonso não faz nada. De propósito."
                )
        }
    })
	
	    acts = [
        {
            name: "Checar",
            desc: "Análise inútil",
            party: [],
            exec: function(slot, user) {
                encounter_scene_dialogue(
                    "* SONSO - ATK 4 DEF 1{br}{resetx}"
                  + "* Gato de rua. Decide sozinho de quem ele gosta.{br}{resetx}"
                  + "* Detesta ser chamado."
                )
            }
        },
        {
            name: "Chamar",
            desc: "Psiu, psiu, psiu",
            party: [],
            exec: function(slot, user) {
                var me = o_enc.encounter_data.enemies[slot]
                me.chamados ++
                me.humor = "irritado"

                audio_play(snd_ui_cant_select)

                if me.chamados == 1
                    encounter_scene_dialogue("* " + party_getname(user) + " chamou o Sonso.{br}{resetx}* Ele virou as costas.")
                else
                    encounter_scene_dialogue("* " + party_getname(user) + " chamou de novo.{br}{resetx}* Agora ele está OFENDIDO.")
            }
        },
        {
            name: "Ignorar",
            desc: "Olhar fixamente para qualquer outra coisa",
            party: [],
            exec: function(slot, user) {
                var me = o_enc.encounter_data.enemies[slot]
                me.humor = "curioso"

                enc_enemy_add_spare(slot, 50)   // metade da barra de MERCY

                encounter_scene_dialogue("* " + party_getname(user) + " olhou fixamente para o nada.{br}{resetx}* O Sonso deu um passo na sua direção.")
            }
        }
    ]

    turn_object = o_turn_sonso  // por enquanto: uma bala parada
}