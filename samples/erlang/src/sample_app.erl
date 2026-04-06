-module(sample_app).
-export([greeting/0]).

greeting() ->
    io:format("hello from the erlang sample~n").
