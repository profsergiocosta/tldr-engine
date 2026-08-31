// Other_12.gml — User Event 2 ("box is created")
event_inherited()



switch pattern {                    // lembre: pattern É o humor do gato
    case "irritado":
        o_enc.mybox.width  = 55     // ele te encurrala
        o_enc.mybox.height = 55
        break

    case "curioso":
        o_enc.mybox.width  = 90     // ele te ronda, com espaço de sobra
        o_enc.mybox.height = 90
        break

    default:
        o_enc.mybox.width  = 75
        o_enc.mybox.height = 75
        break
}

// Other_12.gml
o_enc.mybox.sprite_index = spr_ex_box_complex        // a moldura
o_enc.mybox.mask_index   = spr_ex_box_complex_mask   // as paredes (colisão)
o_enc.mybox.sprite_back  = spr_ex_box_complex_back_2x // o fundo interno

with o_enc.mybox {
    sprite_w = sprite_get_width(sprite_index)
    sprite_h = sprite_get_height(sprite_index)
}