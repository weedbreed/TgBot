module Types
 
export StatePoint, Button, Letter, Image, CallbackAction

struct StatePoint{T} end
StatePoint(s::String) = StatePoint{Symbol(s)}()

struct Button{T} end
Button(s::String) = Button{Symbol(s)}()

struct Letter{T} end
struct Image{T} end

struct CallbackAction{T} end
CallbackAction(s::String) = CallbackAction{Symbol(s)}()

end # module Types