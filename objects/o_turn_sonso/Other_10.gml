// ---------- Other_10.gml  (User Event 0 — "init") ----------
event_inherited()
__support_init_default()

// o padrão deste turno É o humor do gato
pattern = enemy_struct.humor

if !am_support {
    switch pattern {
        case "irritado": timer_end = 150 break   // 5s — o mais longo e mais denso
        case "curioso":  timer_end = 90  break   // 3s — quase um carinho
        default:         timer_end = 120 break   // 4s
    }
}