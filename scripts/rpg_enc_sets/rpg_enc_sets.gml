function rpg_enc_set_sonso() : enc_set() constructor {
    debug_name = "sonso"                    // o nome que aparece no console

    enemies = [ new rpg_enemy_sonso() ]     // repare no `new`

      flavor = function() {
        if o_enc.turn_count == 0
            return "* Um gato bloqueia a passagem. Tecnicamente."

        switch o_enc.encounter_data.enemies[0].humor {
            case "irritado": return "* O ar está tenso. E peludo."
            case "curioso":  return "* O Sonso está mais perto do que estava."
            default:         return "* Cheiro de telhado quente."
        }
    }

    enemies_pos = [ [0, 0, true] ]          // [x, y, relativo ao ponto padrão]
    bgm = mus_battle
}