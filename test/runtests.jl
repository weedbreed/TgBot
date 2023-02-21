push!(LOAD_PATH, joinpath(pwd(), "src"))

using TgBot
import TgBot: process_update

function TgBot.get_state(chat_id::Int64) 
    return State("START", Dict())
end

expanded = @macroexpand(@tgbot begin
    case
    btn  : "Home"
    func : home_menu

    case
    btn  : "List"
    func : list
end)

@info "MACROEXPAND" expanded

@tgbot begin
    case
    btn  : "Home"
    func : home_menu

    case
    btn  : "List"
    func : list
end

@tgfun home_menu begin
    println("Home MENU!") 
end

@tgfun list begin
    println("Chat id: $chat_id") 
    println(["Iten #$i" for i in 1:10])
end

run_tgbot()