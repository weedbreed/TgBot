module TgBotMacro

export @tgbot
using MacroTools
using Logging

include("Types.jl")
using .Types

case = nothing
expr = Expr(:block)

macro tgbot(ex)
    MacroTools.postwalk(tgbot_walk, ex)
    create_process_update()
    @info "final ex" expr
    return expr
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

function create_type(T, v)
    isnothing(v) ? :($T) : :($T{Symbol($v)})
end

function create_process_update()
    global case
    @info "case" case
    isnothing(case) && return nothing
    push!(expr.args, :(function Main.TgBot.process_update(
        state_pointT::$(create_type(StatePoint, case.state_point)),
        buttonT::$(create_type(Button, case.button)),
        ::Letter{$(case.text)},
        ::Image{$(case.image)},
        callback_actionT::$(create_type(CallbackAction, case.callback_action))
        ; chat_id, callback_variables, text, image
    )

        println("HERE!!!")
            takeP = x -> String(collect(typeof(x).parameters)[1])

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
    ))
end 

function tgbot_walk(ex)
    global case
    @debug "walk" ex
    ex == :case && begin
        fn = create_process_update()
        global case = Case()
        return fn
    end

    if @capture(ex, state : state_)
        global case.state_point = state
        @info "capture state" case
    end

    if @capture(ex, btn : btn_)
        global case.button = btn
        @info "capture btn" case
    end

    (!isnothing(case)) && (case.image = (ex == :image))

    if @capture(ex, cback : cback_)
        global case.callback_action = cback_
        @info "capture cback" case
    end

    if @capture(ex, func : func_)
        global case.func = func
        @info "capture func" case
    end

    @debug "final case" case

    return ex
end

end # module TgBotMacro

