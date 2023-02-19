include("TgBot.jl")
using .TgBot
include("TgBotMacro.jl")
using .TgBotMacro

@tgbot begin
    case
    btn  : "Home"
    func : home_menu

    case
    btn  : "List"
    func : list
end

run_tgbot()