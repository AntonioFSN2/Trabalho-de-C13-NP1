function d = detectar_degrau(t, u, y)
%DETECTAR_DEGRAU Localiza o degrau da entrada e os patamares (auxiliar dos stubs).
%   d = detectar_degrau(t, u, y) devolve uma struct com:
%     indice, t0 - primeira amostra (e instante) depois do salto da entrada
%     u0, uf, du - patamares da entrada (media de trecho) e amplitude do degrau
%     y0, yf, dy - patamares da saida (media de trecho) e variacao total
%   Gera erro se nao houver um degrau identificavel na entrada.
%
%   Fica em stubs/private: so as funcoes de stubs/ enxergam este arquivo.

N  = numel(u);
n5 = max(1, round(0.05*N));     % 5% das amostras

% Limiar no meio do salto (mediana dos 5% iniciais e finais, robusta ao ruido)
uIniRef = median(u(1:n5));
uFimRef = median(u(end-n5+1:end));
limiar  = (uIniRef + uFimRef)/2;
if uFimRef >= uIniRef
    indice = find(u >= limiar, 1);
else
    indice = find(u <= limiar, 1);
end
if isempty(indice) || indice < 3
    error('identificacao:semDegrau', ...
        'Nao foi possivel localizar o degrau: e preciso haver amostras antes do salto da entrada.');
end

% Patamares por media de trecho (reduz o ruido)
u0 = mean(u(1:indice-1));
uf = mean(u(end-n5:end));
du = uf - u0;
if abs(du) < max(1e-6, 5*std(u(1:indice-1)))
    error('identificacao:semDegrau', ...
        'A entrada nao apresenta um degrau (amplitude desprezivel frente ao ruido).');
end

y0 = mean(y(1:indice-1));
yf = mean(y(end-n5:end));
dy = yf - y0;
if abs(dy) < 1e-9
    error('identificacao:semResposta', 'A saida nao responde ao degrau (dy = 0).');
end

d = struct('indice', indice, 't0', t(indice), ...
           'u0', u0, 'uf', uf, 'du', du, ...
           'y0', y0, 'yf', yf, 'dy', dy);
end
