function [k, tau, theta, eqm, y_modelo] = identificar_smith(t, u, y)
%IDENTIFICAR_SMITH Identificacao FOPDT pelo metodo de Smith.
%   [k, tau, theta, eqm, y_modelo] = identificar_smith(t, u, y)
%
%   VERSAO PROVISORIA (stub): sera substituida pela implementacao oficial.
%   Pontos em 28,3% e 63,2% de dy, medidos a partir do instante do degrau:
%     tau = 1,5*(t2 - t1)      theta = t2 - tau      k = dy/du

t = t(:); u = u(:); y = y(:);
d = detectar_degrau(t, u, y);

k  = d.dy / d.du;
yN = (y - d.y0) / d.dy;     % saida normalizada (0 -> 1)

t1 = tempo_cruzamento(t, yN, d, 0.283);
t2 = tempo_cruzamento(t, yN, d, 0.632);

tau = 1.5*(t2 - t1);
if tau <= 0
    error('identificacao:tau', 'Smith: tau calculado nao e positivo.');
end
theta = max(t2 - tau, 0);   % atraso negativo nao tem sentido fisico

y_modelo = resposta_fopdt(t, d, k, tau, theta);
eqm = calcular_eqm(y, y_modelo);
end
