function tc = tempo_cruzamento(t, yN, d, p)
%TEMPO_CRUZAMENTO Tempo (a partir do degrau) em que a saida normalizada atinge p.
%   tc = tempo_cruzamento(t, yN, d, p), com d vindo de detectar_degrau.
%   A busca comeca no instante do degrau, para o ruido antes dele nao contar.

idx = find(yN(d.indice:end) >= p, 1);
if isempty(idx)
    error('identificacao:semCruzamento', ...
        'A saida normalizada nao atinge %.1f%% de dy (ensaio curto demais?).', 100*p);
end
tc = t(d.indice + idx - 1) - d.t0;
end
