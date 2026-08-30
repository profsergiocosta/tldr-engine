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