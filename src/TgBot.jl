module TgBot

export run_tgbot, State, @tgbot, @tgfun
using Telegram, Telegram.API, Telegram.JSON3
using ConfigEnv
using Logging, LoggingExtras

include("Types.jl")
using .Types
include("TgBotMacro.jl")
using .TgBotMacro: @tgbot, @tgfun

struct State
    point::String
    variables::Dict{String, Any}
end

const STATES = Ref(Dict{Int64, State}())

const init_state = State("START", Dict())

function set_state(chat_id::Int64, state::State)
    STATES[][chat_id] = state
end

function get_state(chat_id::Int64)::State
    !haskey(STATES[], chat_id) && set_state(chat_id, init_state)
    return STATES[][chat_id]
end

function rget(::Nothing, ::AbstractArray{Symbol, 1})
    return nothing
end

function rget(obj::JSON3.Object, path::AbstractArray{Symbol, 1})
    length(path) == 0 && return obj
    length(path) == 1 && return get(obj, String(path[1]), nothing)
    return rget(get(obj, String(path[1]), nothing), path[2:end])
end

function process_update(upd:: JSON3.Object)
    chat_id = something(rget(upd, [:message, :chat, :id]), rget(upd, [:callback_query, :message, :chat, :id]))
    # TODO: Do proper errors logging including sending to Telegram
    @assert !isnothing(chat_id) "No chat id in message:\t$(upd)"
    state_pointT = StatePoint(get_state(chat_id).point)
    buttonT = Button(rget(upd, [:message, :text]))
    text = rget(upd, [:message, :text])
    textT = Letter{!isnothing(text)}()
    # TODO: Deal with all image sizes
    image_sizes = rget(upd, [:message, :photo])
    image = isnothing(image_sizes) ? nothing : maximum(ps -> ps.width, image_sizes).file_id
    imageT = Image{!isnothing(image)}()
    
    callback_query_data_json = rget(upd, [:callback_query, :data])
    callback_query_data = isnothing(callback_query_data_json) ? [nothing, Dict{String, Any}()] : JSON.Parser.parse(callback_query_data_json)
    @assert (isnothing(callback_query_data[1]) || callback_query_data[1] isa AbstractString) "Bad callback query data action:\t$callback_query_data"
    @assert callback_query_data[2] isa Dict{String, Any} "Bad callback query data variables:\t$callback_query_data"
    callback_actionT = CallbackAction(callback_query_data[1])
    callback_variables = length(callback_query_data) > 1 ? callback_query_data[2] : Dict{String, Any}()

    @debug "Calling process_update with arguments:" state_pointT buttonT textT imageT callback_actionT chat_id callback_variables text image
    process_update(state_pointT, buttonT, textT, imageT, callback_actionT; chat_id, callback_variables, text, image)
end

function process_update(::Any, ::Any, ::Any, ::Any, ::Any; kwargs...)
    sendMessage(chat_id = kwargs[:chat_id], text="🏗️ Not implemented! 🚧")
end

function run_tgbot() 
    @assert isfile(".env") "No .env environment file"
    dotenv()

    ms = methods(process_update)
    @info "Found $(length(ms) - 2) custom update processing methods."
    @debug ms
    @info "Running bot..."

    run_bot(;timeout = 3) do msg
        @info "Incoming message:\t" chat_id=msg.message.chat.id msg
        process_update(msg)
        # response = sendMessage(text = msg.message.text, chat_id = msg.message.chat.id)
    end
end 

end # module TgBot
