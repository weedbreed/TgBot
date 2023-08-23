module TgBotMacro

export @tgbot, @tgfun
using MacroTools
using Logging

include("Types.jl")
using .Types

case = nothing
expr = Expr(:block)

macro tgbot(ex)
    MacroTools.postwalk(tgbot_walk, ex)
    create_process_update()
    @debug "Generated expression:" (expr |> rmlines)
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

function create_type(T::Symbol, v)
    isnothing(v) ? :(TgBot.Types.$T) : :(TgBot.Types.$T{Symbol($v)})
end

function create_process_update()
    global case
    @debug "Found case:" case
    isnothing(case) && return nothing
    ex = Expr(
        :function, 
        :($(esc(:(TgBot.process_update)))(
            state_pointT::$(esc(create_type(:StatePoint, case.state_point))),
            buttonT::$(esc(create_type(:Button, case.button))),
            $(esc(:(::TgBot.Types.Letter{$(case.text)}))),
            $(esc(:(::TgBot.Types.Image{$(case.image)}))),
            callback_actionT::$(esc(create_type(:CallbackAction, case.callback_action)))
            ; chat_id, user, callback_variables, text, image
        )),
        quote
            function takeP(x)
                v = collect(typeof(x).parameters)[1]
                return isnothing(v) ? nothing : String(v)
            end

            state_point = takeP(state_pointT)
            button = takeP(buttonT)
            callback_action = takeP(callback_actionT)

            @debug "Calling function $(case.func) with arguments:" chat_id user state_point button text image callback_action callback_variables

            $(esc(case.func))(
                chat_id=chat_id,
                user=user,
                state_point=state_point,
                button=button,
                text=text,
                image=image,
                callback_action=callback_action,
                callback_variables=callback_variables
            )
        end
    )
    push!(expr.args, ex)
end

function tgbot_walk(ex)
    global case
    ex == :case && begin
        fn = create_process_update()
        global case = Case()
        return fn
    end

    if @capture(ex, state:state_)
        global case.state_point = state
    end

    if @capture(ex, btn:btn_)
        global case.button = btn
        global case.text = true
    end

    if @capture(ex, cback:cback_)
        global case.callback_action = cback
    end

    if @capture(ex, func:func_)
        global case.func = func
    end

    if !isnothing(case)
        ex == :text && (case.text = true)
        ex == :image && (case.image = true)
    end

    return ex
end

macro tgfun(name, body)
    return Expr(
        :function,
        :($(esc(name))(;chat_id, user, state_point, button, text, image, callback_action, callback_variables)),
        esc(body)) 
end

end # module TgBotMacro

