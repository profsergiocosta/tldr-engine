---
title: A arena — dando cara própria à batalha
tags:
  - tldr-engine
  - gamemaker
  - combate
  - tutorial
---

# Tutorial 2: a arena — dando cara própria à batalha

> Continuação direta de [`tutorial-primeiro-inimigo.md`](tutorial-primeiro-inimigo.md). Lá o Sonso ganhou personalidade através dos ACTs e dos padrões de bala. Aqui ele ganha **um lugar**: a caixa onde a alma se move deixa de ser um quadrado neutro e passa a fazer parte da atuação dele.
>
> Nove passos, cada um testável sozinho. Você pode parar em qualquer um.

---

## Do que você precisa antes

O Sonso do tutorial 1 funcionando: `rpg_enemy_sonso()`, `rpg_enc_set_sonso()` e o objeto `o_turn_sonso` com os quatro eventos. Se `TAB` → `encounter_select` → `sonso` abre a luta e o gato ataca, você está pronto.

Se os acentos ainda não aparecem, veja [`tutorial-fontes-acentos.md`](tutorial-fontes-acentos.md) — ou escreva sem acento por enquanto.

## A ideia deste tutorial

No tutorial 1, o humor do Sonso mudava o **padrão de balas**. Aqui ele vai mudar também **o tamanho, a inclinação e o conteúdo da arena**.

Isso importa porque a caixa é o espaço pessoal do jogador. Encolher a caixa não é "aumentar a dificuldade" — é o gato chegando perto demais. Girar a caixa não é um efeito bonito — é você perdendo o chão. O jogador sente antes de entender.

| Humor | O que a arena faz | O que comunica |
|---|---|---|
| `sonso` | quadrado normal, 75×75 | ele está de boa |
| `irritado` | encolhe para 55×55 e treme | ele te encurralou |
| `curioso` | cresce para 90×90 e gira devagar | ele está te rondando |

---

## Passo 1 — Onde se mexe na arena

A caixa é a instância **`o_enc.mybox`** (objeto `o_enc_box`), criada pela engine no começo de cada turno de defesa. Ela existe do momento em que a caixa abre até o momento em que fecha.

O lugar certo de configurá-la é o **User Event 2** do seu `turn_object` — o evento que a engine chama com a descrição *"box is created"*, logo depois de a caixa e a alma nascerem e **antes** de o turno começar.

Se você seguiu o tutorial 1, o `o_turn_sonso` ainda não tem esse evento. Adicione: **Add Event → Other → User Events → User Event 2** (arquivo `Other_12.gml`).

> [!warning] Chame o pai neste evento
> O `o_turn` base usa o User Event 2 para sortear o `pattern` a partir do `pattern_pool`. Se você sobrescrever sem `event_inherited()`, quebra o sorteio de padrões de qualquer inimigo que use `pattern_pool`. A primeira linha é sempre `event_inherited()`.

### O que dá para mexer

| Propriedade | Efeito |
|---|---|
| `width` / `height` | tamanho da arena (default 75×75) |
| `x` / `y` | posição dela na tela |
| `image_angle` | inclinação |
| `sprite_index` + `mask_index` + `sprite_back` | o formato da arena |
| `color` | cor da moldura |

### Experimento de dois minutos

Escreva isto e rode:

```gml
// Other_12.gml — User Event 2 ("box is created")
event_inherited()

o_enc.mybox.width  = 140
o_enc.mybox.height = 50
```

Você deve ver uma arena larga e baixa, como uma fresta. Volte para `75`/`75` depois de conferir — o passo 2 faz isso direito.

> [!info] Por que não no Create ou no User Event 0
> Nesses dois eventos a caixa **ainda não existe** — `o_enc.mybox` é criada só quando o estado da batalha vira `TURN`. Tentar configurá-la antes dá erro de instância inexistente.

---

## Passo 2 — A arena reage ao humor

Agora ligando a arena ao personagem. No mesmo `Other_12.gml`:

```gml
// Other_12.gml — User Event 2
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
```

O `pattern` já foi definido no User Event 0 (`pattern = enemy_struct.humor`), e o User Event 2 roda depois dele — então aqui ele já vale o humor certo.

**Teste:** entre na luta, use `Chamar` e repare que a arena da rodada seguinte é visivelmente menor. Use `Ignorar` e ela abre. Se você criou o ACT `DEBUG` do tutorial 1, é mais rápido ainda.

> [!tip] Encolher é mais forte que acelerar
> Uma arena 55×55 com as mesmas balas é mais tensa que uma arena 75×75 com balas 30% mais rápidas — e é mais legível, porque o jogador **vê** a mudança antes de sentir. Prefira mexer no espaço antes de mexer na velocidade.

---

## Passo 3 — A arena treme e gira

Tamanho é um estado; movimento é uma emoção. Vamos fazer a caixa tremer quando o gato está irritado e girar devagar quando ele está curioso.

Isso vai no **Step**, porque precisa acontecer todo frame. Mas o Step exige um cuidado que o User Event 2 não exigia:

```gml
// Step_0.gml de o_turn_sonso
event_inherited()

if timer == 0
    exit                    // a caixa e a alma ainda não existem

if pattern == "irritado"
    o_enc.mybox.image_angle = sine(4, 2)        // tremor rápido e curto
else if pattern == "curioso"
    o_enc.mybox.image_angle = sine(40, 12)      // balanço lento e largo

// ... os padrões de bala do tutorial 1 continuam aqui ...

__support_destroy_check()
```

> [!warning] O `if timer == 0 exit` não é enfeite
> O `turn_object` **nasce antes da caixa**: ele é criado no estado `DIALOGUE`, e `o_enc.mybox` só passa a existir quando o estado vira `TURN` (`objects/o_enc/Step_0.gml:321`). Como `mybox` nem é inicializada no Create do `o_enc`, ler ela antes da hora não devolve `noone` — devolve **erro de variável inexistente**, e o jogo para.
>
> A guarda resolve porque `timer` só começa a contar depois do User Event 1, que roda **depois** de a caixa nascer. Se `timer > 0`, a caixa existe com certeza. É o idioma da própria engine — veja `objects/o_turn_default_dark/Step_0.gml`.
>
> O código do tutorial 1 escapava disso por acaso: todos os padrões de bala estavam dentro de condições como `timer % 30 == 0 && timer > 0` ou `timer == 10`, que já exigiam `timer > 0`. Ao acrescentar qualquer linha solta no Step, a guarda passa a ser necessária.

`sine(divisor, multiplicador)` é da engine (`scripts/custom/custom.gml:491`): devolve um seno baseado em `o_world.frames`. Divisor menor = mais rápido; multiplicador maior = amplitude maior.

> [!info] A alma é carregada junto — e isso é de graça
> Girar a caixa não faz o jogador atravessar a parede. O `o_enc_box_solid` mede o próprio deslocamento, rotação e mudança de escala a cada frame (`objects/o_enc_box_solid/Step_1.gml`), e o `o_enc_soul/Step_1.gml` usa esses valores para empurrar e girar a alma junto com a arena.
>
> Vale para os três: mover, girar e redimensionar. Uma parede que avança **empurra** o jogador em vez de engoli-lo.

**Teste:** a diferença entre `sine(4, 2)` e `sine(40, 12)` é a coisa toda. Rode os dois e repare em como o mesmo padrão de bala fica com outra sensação.

### O `Step_0.gml` inteiro, depois deste passo

Juntando com os padrões de bala do tutorial 1, o arquivo fica assim:

```gml
// ---------- Step_0.gml de o_turn_sonso ----------
event_inherited()

if timer == 0
    exit                   // a caixa e a alma ainda não existem

// ---------- a arena reage ao humor ----------
if pattern == "irritado"
    o_enc.mybox.image_angle = sine(4, 2)
else if pattern == "curioso"
    o_enc.mybox.image_angle = sine(40, 12)

// ---------- os padrões de bala ----------
if pattern == "sonso" {
    if timer % 30 == 0 && timer < timer_end - 30 {
        _lado *= -1
        var _falha = irandom_range(-20, 20)

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
    if timer % 10 == 0 && timer < timer_end - 50 {
        instance_create(o_enc_bullet,
            o_enc_box.x + irandom_range(-32, 32),
            o_enc_box.y - 60,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                speed: 4, direction: 270, att: 4
            })
    }

    if timer == timer_end - 45 {
        audio_play(snd_spawn_attack)

        instance_create(o_enc_bullet,
            o_enc_box.x - 100, o_enc_box.y,
            DEPTH_ENCOUNTER.BULLETS_OUTSIDE, {
                color: BULLET_COLOR.BLUE,
                speed: 4, direction: 0, att: 5,
                image_xscale: 1.5, image_yscale: 6
            })
    }
}
else if pattern == "curioso" {
    if timer == 10 {
        for (var i = 0; i < 10; i ++) {
            var _ang = i * 36

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
}

__support_destroy_check()
```

Duas mudanças em relação ao tutorial 1, além da guarda:

**A rotação ficou num bloco próprio**, antes dos padrões. Funcionaria dentro de cada `else if` também, mas separado deixa claro o que é *arena* e o que é *bala* — e evita esquecer de um dos humores.

**Sumiram os `&& timer > 0`** das condições de bala. Com o `exit` no topo eles viraram redundantes.


---

## Passo 4 — Mudando o formato da arena

Até aqui a caixa continua retangular. Para mudar o formato de verdade, são **três** sprites:

```gml
// Other_12.gml
o_enc.mybox.sprite_index = spr_ex_box_complex        // a moldura
o_enc.mybox.mask_index   = spr_ex_box_complex_mask   // as paredes (colisão)
o_enc.mybox.sprite_back  = spr_ex_box_complex_back_2x // o fundo interno

with o_enc.mybox {
    sprite_w = sprite_get_width(sprite_index)
    sprite_h = sprite_get_height(sprite_index)
}
```

Os três precisam andar juntos:

| Sprite | Papel | Cuidado |
|---|---|---|
| `sprite_index` | o que se vê da moldura | — |
| `mask_index` | **onde a alma bate** | tem que ser a moldura **vazada** — só a borda é sólida, o miolo é buraco |
| `sprite_back` | o preenchimento interno | se usar nine-slice, tem que ser 2x |

O `with` no final é obrigatório: o Step da caixa recalcula a escala com `image_xscale = width / sprite_w`, e se `sprite_w` continuar com o valor do sprite antigo, o tamanho sai errado.

> [!warning] A máscara é vazada, não cheia
> A alma anda onde **não** há colisão (`o_enc_soul/Step_0.gml`). Se a máscara for um retângulo preenchido, a alma não consegue entrar em lugar nenhum. Por isso o `spr_enc_box_mask` padrão é só o contorno. Ao desenhar a sua, desenhe **as paredes**, não a sala.

O exemplo pronto na engine é o **`o_ex_turn_complex_box`** — vale abrir e rodar (`encounter_select`) antes de desenhar o seu.

---

## Passo 5 — Obstáculos dentro da arena

Aqui está um detalhe que abre bastante coisa: **`o_enc_box` é filho de `o_enc_box_solid`**, e a alma testa colisão contra o **pai**:

```gml
if !place_meeting(x + xstep + sign(xstep)*1.5, y, o_enc_box_solid)
```

Ou seja: **qualquer instância extra de `o_enc_box_solid` vira parede sólida dentro da arena.** Pilares, corredores, uma parede que desce no meio do turno.

Para o Sonso, a ideia: quando ele está irritado, ele derruba **caixas de papelão** na arena.

```gml
// Create_0.gml — guarde a lista para poder limpar depois
event_inherited()

_lado = choose(-1, 1)
_caixas = []
```

```gml
// Other_12.gml — depois do que você já tem
if pattern == "irritado" {
    repeat (2) {
        var _c = instance_create(o_enc_box_solid,
            o_enc_box.x + irandom_range(-25, 25),
            o_enc_box.y + irandom_range(-25, 25),
            DEPTH_ENCOUNTER.BOX - 1)

        _c.sprite_index = spr_pixel
        _c.image_xscale = 14
        _c.image_yscale = 14
        _c.image_blend  = c_olive
        _c.visible      = true      // o o_enc_box_solid nasce invisível

        array_push(_caixas, _c)
    }
}
```

```gml
// Destroy_0.gml
event_inherited()
instance_destroy(o_enc_bullet)

for (var i = 0; i < array_length(_caixas); i ++)
    if instance_exists(_caixas[i])
        instance_destroy(_caixas[i])
```

Três detalhes:

**`o_enc_box_solid` nasce invisível** (`"visible": false` no `.yy`) e sem sprite. Precisa de `sprite_index` e `visible = true` para virar algo que o jogador enxerga — senão você cria uma parede fantasma, que é frustrante de jogar.

**`spr_pixel` é 1×1**, então `image_xscale` é literalmente o tamanho em pixels. Prático para protótipo; troque por um sprite de verdade depois.

**Limpar no Destroy não é opcional.** Nada na engine recolhe esses objetos, exatamente como acontece com as balas. Sem isso, a segunda rodada começa com as caixas da primeira ainda lá.

> [!tip] Obstáculo que anda empurra
> Como `o_enc_box_solid` rastreia o próprio movimento, um obstáculo que você anime com `animate(...)` **empurra a alma** em vez de atravessá-la. Uma parede que avança lentamente de um lado da arena é um ataque inteiro, sem uma bala sequer.

---

## Passo 6 — O fundo da tela

O fundo é a única parte da batalha que a engine desenha **atrás** de tudo, e é a que mais muda a atmosfera com menos esforço. Antes de trocar, vale entender o que está lá.

### 6.1 Como o fundo padrão funciona

Tudo vem de um objeto só, o **`o_eff_bg`**, criado pela engine na depth `DEPTH_ENCOUNTER.BACKGROUND` no começo da batalha (`o_enc_anim/Alarm_1.gml:72`). O `Draw` dele empilha **três camadas**:

| Camada | O que é | Controlada por |
|---|---|---|
| 1. Cortina preta | um retângulo preto cobrindo a tela, que some o overworld | `image_alpha` (sobe de 0 a 1 sozinho, 0.1 por frame) |
| 2. A grade | `spr_enc_bg` desenhado **duas vezes**, em velocidades e opacidades diferentes — é isso que dá a sensação de profundidade | `image_blend`, e só existe se `bg_type == ENC_BG.GRID` |
| 3. O véu | outro retângulo preto por cima de tudo | `fade` — a engine anima para `0.75` quando o turno de defesa começa |

A camada 1 e a 2 só aparecem com `bg_type = ENC_BG.GRID`. A camada 3 **sempre** existe, mesmo com `NONE` — é ela que escurece a cena quando a caixa abre, e você provavelmente quer manter.

> [!info] O fundo é desenhado em coordenadas de sala, não de interface
> A batalha acontece numa janela de **320×240** ancorada na câmera. Por isso todo desenho de fundo soma `guipos_x()` e `guipos_y()` — que são a posição da câmera (`scripts/custom/custom.gml:2`). Sem esse deslocamento, o seu fundo fica no canto errado assim que a câmera não estiver na origem.
>
> Não confunda com a interface (nomes, HP, botões), que é desenhada no `Draw GUI` num espaço de 640×480 — o dobro.

### 6.2 Nível 1 — recolorir a grade

A grade é desenhada com `image_blend`, então trocar a cor do fundo inteiro é **uma linha**. E como o Sonso já tem humor, dá para amarrar as duas coisas.

No `Step_0.gml` do `o_turn_sonso`, junto do bloco da arena:

```gml
// ---------- a arena reage ao humor ----------
if pattern == "irritado" {
    o_enc.mybox.image_angle = sine(4, 2)
    o_eff_bg.image_blend = make_color_rgb(255, 120, 90)   // o mundo esquenta
}
else if pattern == "curioso" {
    o_enc.mybox.image_angle = sine(40, 12)
    o_eff_bg.image_blend = make_color_rgb(150, 190, 255)  // e esfria
}
else
    o_eff_bg.image_blend = c_white                        // neutro
```

Duas rodadas de teste e você vê o quanto isso muda a leitura da cena sem uma bala nova sequer. É o retorno mais alto por linha escrita deste tutorial inteiro.

> [!warning] `o_eff_bg` não existe fora da batalha
> Ele nasce junto com a luta e se destrói no fim. Dentro do `turn_object` isso é seguro — se o turno existe, a batalha existe. Fora dele, teste com `if instance_exists(o_eff_bg)` antes.

### 6.3 Nível 2 — um fundo próprio

Quando a grade não serve, o caminho é desligá-la e desenhar o seu.

**Primeiro, desligue a grade** no `enc_set()`:

```gml
    bg_type = ENC_BG.NONE
```

Isso apaga as camadas 1 e 2. Sobra a camada 3, o véu — que continua sendo o que dá foco à arena.

**Depois crie o objeto.** Um telhado noturno para o gato, sem precisar desenhar nenhum sprite novo — tudo com o `spr_pixel`, que é 1×1 com origem no canto, então `image_xscale` é literalmente a largura em pixels:

```gml
// ---------- o_bg_telhado / Create_0.gml ----------
depth = DEPTH_ENCOUNTER.BACKGROUND + 10   // número MAIOR = mais ao fundo

// as estrelas são sorteadas uma vez só, não a cada frame
estrelas = []
repeat (40)
    array_push(estrelas, {
        xx:   random(320),
        yy:   random(150),
        fase: random(360)
    })
```

```gml
// ---------- o_bg_telhado / Draw_0.gml ----------
var _ox = guipos_x()
var _oy = guipos_y()

// o céu
draw_sprite_ext(spr_pixel, 0, _ox, _oy, 320, 240, 0, make_color_rgb(14, 16, 34), 1)

// as estrelas, piscando fora de fase
for (var i = 0; i < array_length(estrelas); i ++) {
    var _e = estrelas[i]
    var _brilho = 0.35 + 0.35 * dsin(o_world.frames * 2 + _e.fase)

    draw_sprite_ext(spr_pixel, 0, _ox + _e.xx, _oy + _e.yy, 1, 1, 0, c_white, _brilho)
}

// a silhueta do telhado
draw_sprite_ext(spr_pixel, 0, _ox, _oy + 170, 320, 70, 0, make_color_rgb(6, 7, 16), 1)
```

```gml
// ---------- o_bg_telhado / Step_0.gml ----------
if !instance_exists(o_enc)
    instance_destroy()
```

**Por fim, mande criar** no hook `ev_init` do `enc_set()` — ele roda um frame depois de `o_enc` existir:

```gml
    ev_init = function() {
        instance_create(o_bg_telhado)
    }
```

Três decisões que valem explicar:

**As estrelas nascem no Create, não no Draw.** Sortear posição dentro do `Draw` faria elas piscarem de lugar todo frame. Guardar num array e só ler no desenho é o padrão para qualquer elemento decorativo estático.

**O `Step` que se autodestrói.** Sem ele, o fundo sobrevive ao fim da batalha e aparece no overworld. Amarrar a vida dele à existência do `o_enc` cobre todos os finais — vitória, fuga, derrota — sem você precisar tratar cada um.

**A depth é `BACKGROUND + 10`, não `- 10`.** Em GameMaker, **depth maior é mais ao fundo**. É o erro mais comum aqui: usar um número menor coloca o seu fundo na frente dos inimigos.

| Depth | O que fica lá |
|---|---|
| `-6500` `BULLETS_OUTSIDE` | balas na frente de tudo |
| `-6400` `SOUL` | a alma |
| `-6300` `BOX` | a moldura da arena |
| `-6200` `BULLETS_INSIDE` | balas recortadas, atrás da moldura |
| `-6100` `ACTORS` | os inimigos e o grupo |
| `-6000` `BACKGROUND` | o `o_eff_bg` — grade e véu |
| `-5990` | **o seu fundo** |

### 6.4 O véu escuro, como recurso dramático

A camada 3 (`o_eff_bg.fade`) é um retângulo preto por cima de tudo. A engine anima ele para `0.75` quando o turno de defesa começa (`o_enc/Step_0.gml:241`) e de volta a `0` quando termina.

Como é só uma variável, dá para usar de propósito. Escurecer mais quando o gato está irritado, por exemplo — o mundo some e sobra só a arena:

```gml
// no Other_12.gml, depois de configurar a caixa
if pattern == "irritado"
    animate(o_eff_bg.fade, 0.92, 20, anime_curve.sine_out, o_eff_bg, "fade")
```

`animate(de, para, frames, curva, instância, "campo")` é a função de animação da engine (`scripts/anime_custom/anime_custom.gml:17`). Não precisa desfazer: a engine devolve o `fade` a zero no fim do turno.

### Como testar o fundo

| Passo | O que fazer | O que confirma |
|---|---|---|
| 1 | Ponha `o_eff_bg.image_blend = c_red` e rode | se não ficar vermelho, `bg_type` já está em `NONE` ou o código está no evento errado |
| 2 | Troque para `ENC_BG.NONE` sem criar objeto nenhum | o fundo tem que ficar **preto** com o véu; se a grade continuar, você mexeu no `enc_set()` errado |
| 3 | Crie o `o_bg_telhado` com uma cor berrante (`c_lime`) | se não aparecer, é a depth; se aparecer **na frente** dos inimigos, também |
| 4 | Ande com a câmera antes de entrar na batalha | se o fundo escorregar, faltou somar `guipos_x()` / `guipos_y()` |
| 5 | Ganhe ou fuja da luta | o fundo tem que sumir junto; se ficar no overworld, faltou o `Step` |

---

## Passo 7 — Dois Sonsos

Mais inimigos é só mexer no array do `enc_set()`:

```gml
function rpg_enc_set_sonso_duplo() : enc_set() constructor {
    debug_name = "sonso_duplo"

    enemies = [
        new rpg_enemy_sonso(),
        new rpg_enemy_sonso(),
    ]

    enemies_pos = [
        [ -10, -14, true ],     // [x, y, relativo ao ponto padrão]
        [  10,  14, true ],
    ]

    bgm = mus_battle
}
```

Cada `new` é um struct independente: os dois gatos têm humor, HP e MERCY próprios.

### A parte que surpreende: eles não atacam duas vezes

Você espera dois turnos de bala e recebe **um**. Não é bug. Olhe o User Event 0 do `o_turn` base:

```gml
with object_index {
    count ++
    if id != iid && !allow_same_turns
        instance_destroy()      // turnos duplicados se destroem
}
buff = count - 1                // e o sobrevivente ganha "buff"
```

Com `allow_same_turns = false` (o default), dois inimigos do mesmo tipo geram **um** turn_object com `buff = 1`. A engine assume que dois ataques idênticos simultâneos viram sopa visual — então, em vez disso, ela te entrega um contador para **intensificar** o ataque.

Aproveite o `buff` no `Step_0.gml`:

```gml
if pattern == "sonso" {
    var _periodo = clamp(30 - 8 * buff, 14, 30)   // com 2 gatos: 22 em vez de 30
    if timer % _periodo == 0 && timer > 0 && timer < timer_end - 30 {
        // ... as patadas de sempre
    }
}
```

É o mesmo truque que o `o_turn_default_dark` usa.

> [!warning] Só um humor manda
> Como sobra um turn_object só, o `pattern = enemy_struct.humor` do User Event 0 lê o humor de **um** dos gatos. Se você quiser que os dois humores contem, leia os dois no User Event 0:
>
> ```gml
> var _algum_irritado = false
> for (var i = 0; i < array_length(o_enc.encounter_data.enemies); i ++)
>     if enc_enemy_is_fighting(i) && o_enc.encounter_data.enemies[i].humor == "irritado"
>         _algum_irritado = true
>
> pattern = _algum_irritado ? "irritado" : enemy_struct.humor
> ```
>
> Se você quiser mesmo **dois turnos independentes**, ponha `allow_same_turns = true` no Create do `o_turn_sonso`. Aí prepare-se: dois padrões ao mesmo tempo na mesma caixa.

**Teste:** `encounter_select` → `sonso_duplo`. Confira que aparecem dois nomes na lista, que dá pra escolher qual atacar, e que o ataque ficou mais denso que o de um gato só.

> [!info] Quantos cabem?
> Não há limite no código, mas a lista de nomes é desenhada em `375 + 30*i` numa interface de 480px de altura (`o_enc/Draw_64.gml:190`). Na prática: **3 confortáveis, 4 apertado**. Os exemplos da engine usam 2.

---

## Passo 8 — Uma condição de vitória própria

Por padrão a luta acaba quando todos os inimigos saem de campo. Mas `win_condition` é uma função sua — dá para encerrar por qualquer motivo.

Um Sonso que só quer ser deixado em paz: se você aguentar três rodadas sem atacá-lo, ele vai embora sozinho.

```gml
// no enc_set()
    win_condition = function() {
        if o_enc.turn_count >= 3
            return true

        for (var i = 0; i < array_length(o_enc.encounter_data.enemies); ++i)
            if enc_enemy_is_fighting(i)
                return false

        return true    // regra padrão: ninguém mais lutando
    }
```

A engine avalia isso durante a execução das ações (`o_enc/Step_0.gml:216`), então a luta encerra na rodada seguinte a bater a condição.

Outras condições que a mesma estrutura permite: sobreviver até `o_enc.turn_count == N`, acumular TP (`o_enc.tp >= 100`), derrotar só um inimigo específico, ou uma flag que um ACT liga.

---

## Passo 9 — A posição do grupo

O time também é posicionável, pelo `enc_set()`:

```gml
    party_pos = function(i) {           // i = índice do membro
        return [
            guipos_x() + 52,
            guipos_y() + 130 - 22 * party_length() + i*44,
        ]
    }
```

Esse é o default — uma coluna à esquerda, centralizada verticalmente conforme o tamanho do grupo. Para uma cena diferente, devolva outras coordenadas:

```gml
    party_pos = function(i) {           // fila horizontal embaixo
        return [
            guipos_x() + 90 + i*60,
            guipos_y() + 190,
        ]
    }
```

`guipos_x()` e `guipos_y()` são o canto da interface — some sempre, ou as posições saem do lugar quando a câmera se mexe.

---

## Como testar cada coisa

| O que você mexeu | Como confirmar rápido |
|---|---|
| tamanho da arena | entre na luta e compare com um encontro de exemplo (`encounter_select`) |
| tamanho **por humor** | use o ACT `DEBUG` do tutorial 1 para forçar cada humor |
| rotação / tremor | exagere primeiro: `sine(2, 25)`. Se não mexeu, o código está no evento errado |
| formato (sprites) | ande até a parede em quatro direções. Se a alma sai, a máscara não é a certa |
| obstáculos | eles precisam **aparecer**; parede invisível é bug, não desafio |
| fundo próprio | `bg_type = ENC_BG.NONE` primeiro; se a grade continua, você mexeu no `enc_set()` errado |
| dois inimigos | confira se o ataque ficou mais denso — se ficou igual, o `buff` não está sendo usado |
| `win_condition` | force `return true` e veja a luta acabar na hora |

> [!tip] O teste que vale mais que todos
> Jogue as três rodadas do Sonso seguidas e pergunte: **dá para saber o humor dele sem ler nenhum texto?** Se a arena encolheu e tremeu, a resposta é sim — e aí a customização cumpriu o papel dela, que é atuar junto com o personagem.

---

## Erros comuns

| Sintoma | Causa |
|---|---|
| Erro de instância inexistente ao mexer na caixa | você configurou no Create ou no User Event 0; a caixa só existe a partir do User Event 2 |
| Erro de variável inexistente no Step, logo que a luta começa | falta o `if timer == 0 exit` — o turn_object roda alguns frames antes de a caixa existir |
| O `pattern_pool` parou de sortear | você sobrescreveu o User Event 2 sem `event_inherited()` |
| A arena ficou com tamanho errado depois de trocar o sprite | faltou recalcular `sprite_w` / `sprite_h` |
| A alma não consegue entrar na arena | a máscara está preenchida; ela tem que ser vazada |
| A alma atravessa a parede quando a caixa gira | você mudou `image_angle` de algum objeto que não é a caixa |
| Obstáculos invisíveis | `o_enc_box_solid` nasce com `visible = false` e sem sprite |
| Obstáculos da rodada anterior continuam lá | faltou destruí-los no Destroy do turn_object |
| Dois inimigos iguais atacam como um só | comportamento esperado — use `buff`, ou `allow_same_turns = true` |
| O fundo customizado não aparece | `bg_type` continua `GRID`, ou o objeto não foi criado no `ev_init` |
| O fundo aparece **na frente** dos inimigos | depth menor que `DEPTH_ENCOUNTER.BACKGROUND` — em GameMaker, maior é mais ao fundo |
| O fundo fica deslocado quando a câmera não está na origem | faltou somar `guipos_x()` / `guipos_y()` no desenho |
| O fundo continua na tela depois da batalha | faltou o `Step` que se destrói quando `o_enc` some |
| As estrelas (ou outro enfeite) tremem de lugar | você sorteia a posição dentro do `Draw`; sorteie no `Create` e guarde num array |
| A batalha nunca acaba | `win_condition` nunca devolve `true` |

---

## Referência rápida

> [!warning] No Step, sempre depois do `if timer == 0 exit`
> A caixa só existe a partir do User Event 2. No Step, use `if timer == 0 exit` logo depois do `event_inherited()` antes de tocar em `o_enc.mybox`.

> [!info] `o_enc_box` e `o_enc.mybox` são a mesma caixa
> A engine usa as duas formas: `o_turn_default` escreve `o_enc_box.x`, o `o_ex_turn_complex_box` escreve `o_enc.mybox.x`. Só existe uma instância por turno, então tanto faz. Use `o_enc.mybox` quando quiser deixar claro que é *aquela* caixa da batalha em curso.

```gml
// a caixa (existe a partir do User Event 2 do turn_object)
o_enc.mybox.width / .height      // tamanho, default 75x75
o_enc.mybox.x / .y               // posição
o_enc.mybox.image_angle          // inclinação
o_enc.mybox.sprite_index         // moldura
o_enc.mybox.mask_index           // paredes (máscara VAZADA)
o_enc.mybox.sprite_back          // fundo interno
o_enc.mybox.color                // cor da moldura
// depois de trocar sprite: recalcular sprite_w / sprite_h

// obstáculos: qualquer o_enc_box_solid extra vira parede
instance_create(o_enc_box_solid, xx, yy, DEPTH_ENCOUNTER.BOX - 1)
// lembre de sprite_index, visible = true, e destruir no Destroy

// no enc_set()
enemies          // quantos e quais
enemies_pos      // [[x, y, relativo], ...] ou function(i, xx, yy)
party_pos        // function(i) -> [x, y]
bg_type          // ENC_BG.GRID | ENC_BG.NONE
win_condition    // function() -> bool
target_calculation  // ENC_TARGET.RANDOM | ANY | ALL
display_target   // mostra quem vai apanhar
bgm / bgm_pitch / bgm_gain

// no turn_object
buff             // quantos inimigos iguais atacam juntos (0 = só um)
allow_same_turns // false: turnos duplicados viram buff; true: turnos independentes

// utilidades
sine(divisor, amplitude)                          // seno por frame
animate(de, para, frames, curva, inst, "campo")   // anima qualquer variável
```

---

*Continuação de `docs/tutorial-primeiro-inimigo.md`. Verificado contra `o_enc`, `o_enc_box`, `o_enc_box_solid`, `o_enc_soul`, `o_eff_bg`, `o_turn`, `o_ex_turn_complex_box`, `o_turn_default_dark`, `scripts/enc_sets/enc_sets.gml` e `scripts/custom/custom.gml`.*
