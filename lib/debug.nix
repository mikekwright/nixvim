{ ... }:

let
  # If you want to see what is happening, just enable debug and hopefully you will have more
  #    useful data to work with.
  debug = false;
in
{
  trace = if debug then builtins.trace else (traceItem: returnItem: returnItem);
  traceResult = if debug then (r: builtins.trace r r) else (r: r);
}

