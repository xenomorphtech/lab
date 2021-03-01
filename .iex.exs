require Logger

#Inspect overrides
#import Kernel, except: [inspect: 1]
import Inspect.Algebra
#alias Code.Identifier

#This makes 0.000412 print as 0.000412
defimpl Inspect, for: Float do
  def inspect(term, opts) do
    inspected = :erlang.float_to_binary(term, [:compact, { :decimals, 7 }])
    color(inspected, :number, opts)
  end
end
