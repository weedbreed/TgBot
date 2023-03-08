# push!(LOAD_PATH, joinpath(pwd(), "src"))

using TgBot

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
    println(["Item #$i" for i in 1:10])
end

run_tgbot()