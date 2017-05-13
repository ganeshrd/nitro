-module(wf_event).
-author('Maxim Sokhatsky').
-author('Andrey Martemyanov').
-include_lib ("n2o/include/n2o.hrl").
-include_lib ("nitro/include/nitro.hrl").
-compile(export_all).

-define(B(E), nitro:to_binary(E)).
-define(L(E), nitro:to_list(E)).
target({qs,S}) -> ["qs('",nitro:js_escape(?L(S)), "')"];
target(Id)     -> ["qi('",nitro:js_escape(?L(Id)),"')"].

new(P,E,D,N,Data,Source) -> new(P,E,D,N,Data,Source,<<>>).

new(bin,Data) -> <<"ws.send(enc(tuple(atom('bin'),bin('",(nitro:pickle(Data))/binary,"'))));">>.
new(undefined, _, _, _, _, _, _) -> <<>>;
new(Postback, Element, Delegate, Name, Data, Source, Validation) ->
    wf:info(?MODULE,"CTX#cx.module: ~p~n",[?CTX#cx.module]),
    Module = nitro:coalesce([Delegate, ?CTX#cx.module]),
    Join=fun([]) -> [];
           ([E]) -> [$'|E]++[$'];
         ([H|T]) -> [[$'|H]++[$']] ++ [ [$,,$'|E]++[$'] || E <- T ] end,
    Event = #ev{name=Name, module=Module, msg=Postback, trigger=Element},
    list_to_binary(["{ if (validateSources([",Join([ nitro:to_list(S) || S <- Source, S =/= []]),
        "])) { ",?B(Validation)," ws.send(enc(tuple(atom('",?B(application:get_env(n2o,event,pickle)),"'),bin('",
        Element,"'),bin('",nitro:pickle(Event),"'),",Data,"))); } else console.log('Validation Error'); }"]).
