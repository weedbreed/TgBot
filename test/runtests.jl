# push!(LOAD_PATH, joinpath(pwd(), "src"))

using TgBot
using Telegram.API

@tgbot begin

    case
    btn  : "Home"
    func : home_menu

    case
    cback : :terms_accept
    func  : terms_accept
end

keyboard(args::Vector) = keyboard(args...)

function keyboard(args...)
    Dict("inline_keyboard" => filter(arg->arg!=false, args))
end

key(text, cbdata; kwargs...) =
    merge(kwargs, Dict("text" => text, "callback_data" => cbdata))

@tgfun home_menu begin
    again = if user.has_agreed_terms "снова " else "" end
    sendMessage(;
        chat_id,
        parse_mode = "Markdown",
        text = """
        *Привет!*

        Рады $(again)видеть тебя в нашем сервисе.
        """,
        reply_markup = keyboard(
            user.has_agreed_terms && [key("ℹ️ Информация", :info)],
            !user.has_agreed_terms && [key("🖋️ Принять соглашение", :terms_accept)]
        )
    )
end

run_tgbot()