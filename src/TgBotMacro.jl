module TgBotMacro

export @tgbot
using MacroTools
using Logging

include("Types.jl")
using .Types

macro tgbot(ex)
    MacroTools.postwalk(walk, ex)
end

mutable struct Case
    state_point
    button
    text
    image
    callback_action
    func
    
    Case() = new(nothing, nothing, false, false, nothing, nothing)
end

case = nothing

function takeP(x)
    return String(collect(typeof(x).parameters)[1])
end

function create_process_update()
    isnothing(case) && return nothing
    return :(
        function process_update(
            state_pointT::StatePoint{$(Symbol(case.state_point))},
            buttonT::$(isnothing(case.button) ? :(Button) : :(Button{$(Symbol(case.button))})),
            ::Text{$(case.text)},
            ::Image{$(case.image)},
            callback_actionT::CallbackAction{$(Symbol(case.callback_action))}
            ; chat_id, callback_variables, text, image)

            state_point = takeP(state_pointT)
            button = takeP(buttonT)

            @info "Calling function $(case.func) with arguments:" chat_id=chat_id state_point=state_point button=button text=text image=image callback_action=callback_action callback_variables=callback_variables

            $(case.func)(
                chat_id = chat_id,
                state_point = state_point,
                button = button,
                text = text,
                image = image,
                callback_action = callback_action,
                callback_variables = callback_variables
            )
        end
    )
end

function walk(ex)
    ex == :case && begin
        pu = create_process_update()
        case = Case()
        return pu
    end

    if @capture(ex, state : state_)
        case.state_point = state
    end

    if @capture(ex, btn : btn_)
        case.button = btn
    end

    case.image = ex == :image

    if @capture(ex, cback : cback_)
        case.callback_action = cback_
    end

    if @capture(ex, func : func_)
        case.func = func
    end

    return ex
end

@tgbot begin
    
    case : 1
    text : "Home"
    func : home_menu

    case : 2
    text : "List"
    func : list
end

end # module TgBotMacro

