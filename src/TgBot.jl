module TgBot

export run_tgbot
using Telegram, Telegram.API, Telegram.JSON3
using ConfigEnv
using Logging, LoggingExtras

include("Types.jl")
using .Types

struct State
    point::String
    variables::Dict{String, Any}
end

function get_state(chat_id::Int64)::State 
    error("get_state(chat_id) not implemented!")
end

function rget(::Nothing, ::AbstractArray{Symbol, 1})
    return nothing
end

function rget(obj::JSON3.Object, path::AbstractArray{Symbol, 1})
    length(path) == 0 && return obj
    length(path) == 1 && return get(obj, String(path[1]), nothing)
    return rget(get(obj, String(path[1]), nothing), path[2:end])
end

function process_update(upd)
    chat_id::Int64 = rget(upd, [:message, :chat, :id]) || rget(upd, [:callback_query, :message, :chat, :id])
    # TODO: Do proper errors logging including sending to Telegram
    @assert isnothing(chat_id) "No chat id in message:\t$upd"
    state_point = StatePoint{Symbol(get_state(chat_id).point)}()
    button = Button{Symbol(rget(upd, [:message, :text]))}()
    text = rget(upd, [:message, :text])
    textT = Text(!isnothing(text))()
    # TODO: Deal with all image sizes
    image_sizes = rget(upd, [:message, :photo])
    image = isnothing(image_sizes) ? nothing : maximum(ps -> ps.width, image_sizes).file_id
    imageT = Image{!isnothing(image)}()
    
    callback_query_data = JSON.Parser.parse(rget(upd, [:callback_query, :data])) || [nothing, Dict{String, Any}()]
    @assert (isnothing(callback_query_data[1]) || callback_query_data[1] isa AbstractString) "Bad callback query data action:\t$callback_query_data"
    @assert callback_query_data[2] isa Dict{String, Any} "Bad callback query data variables:\t$callback_query_data"
    callback_action = CallbackAction{Symbol(callback_query_data[1])}()
    callback_variables = length(callback_query_data) > 1 ? callback_query_data[2] : Dict{String, Any}()

    process_update(state_point, button, textT, imageT, callback_action; chat_id, callback_variables, text, image)
end

function run_tgbot() 
    @assert isfile(".env") "No .env environment file"
    dotenv()

    @info "Running bot..."
    @info methods(process_update)

    run_bot() do msg
        @info "Incoming message:\t" chat_id=msg.message.chat.id text=rget(msg, [:message, :text])
        @info typeof(msg.message)
        response = sendMessage(text = msg.message.text, chat_id = msg.message.chat.id)
    end
end 

end # module TgBot
