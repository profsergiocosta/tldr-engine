interaction_code = function() {
    cutscene_create()
    if memory_get("npcs", id)
        cutscene_dialogue("{char(gerson, 1)}* De novo você?{p}{e}")
    else {
        cutscene_dialogue("{char(gerson, 0)}* Olá, forasteiro.{p}{e}")
        cutscene_func(memory_set, ["npcs", id, true])
    }
    cutscene_play()
}