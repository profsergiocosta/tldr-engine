// ---------- Step_0.gml ----------
event_inherited()          // ← é ISTO que faz o timer_end funcionar

if timer == 0
    exit 

// (os padrões entram aqui no Passo 7)
if pattern == "sonso" {
    if timer % 30 == 0 && timer > 0 && timer < timer_end - 30 {
        _lado *= -1                              // alterna esquerda/direita
        var _falha = irandom_range(-20, 20)      // onde fica o buraco

        for (var i = -1; i <= 1; i ++) {
            instance_create(o_enc_bullet,
                o_enc_box.x + 80 * _lado,
                o_enc_box.y + _falha + i * 26,
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    speed: 3,
                    direction: (_lado == 1 ? 180 : 0),
                    att: 4
                })
        }
    }
}
else if pattern == "irritado" {
	
	o_enc.mybox.image_angle = sine(4, 2)        // tremor rápido e curto
	
    // 1) chuvisco rápido, caindo de cima
    if timer % 10 == 0 && timer > 0 && timer < timer_end - 50 {
        instance_create(o_enc_bullet,
            o_enc_box.x + irandom_range(-32, 32),
            o_enc_box.y - 60,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                speed: 4, direction: 270, att: 4
            })
    }

    // 2) O BOTE: uma parede AZUL atravessa a box inteira
    if timer == timer_end - 45 {
        audio_play(snd_spawn_attack)

        instance_create(o_enc_bullet,
            o_enc_box.x - 100, o_enc_box.y,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                color: BULLET_COLOR.BLUE,
                speed: 4, direction: 0, att: 5,
                image_xscale: 1.5, image_yscale: 6    // 22 x 90 px — não dá pra desviar
            })
    }
	
}
else if pattern == "curioso" {
    if timer == 10 {
        for (var i = 0; i < 10; i ++) {
            var _ang = i * 36                      // 360/10

            instance_create(o_enc_bullet,
                o_enc_box.x + lengthdir_x(90, _ang),
                o_enc_box.y + lengthdir_y(90, _ang),
                DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                    color: BULLET_COLOR.ORANGE,
                    speed: 1, direction: _ang + 180,
                    att: 3
                })
        }
    }
	
	o_enc.mybox.image_angle = sine(40, 12) 
}

__support_destroy_check()