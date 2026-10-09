function [k, tau, theta, eqm, y_modelo] = identificar_sundaresan(t, u, y)
%IDENTIFICAR_SUNDARESAN Identificacao FOPDT pelo metodo de Sundaresan.
%   [k, tau, theta, eqm, y_modelo] = identificar_sundaresan(t, u, y)
%
%   VERSAO PROVISORIA (stub): sera substituida pela implementacao oficial.
%   Pontos em 35,3% e 85,3% de dy, medidos a partir do instante do degrau:
%     tau = (2/3)*(t2 - t1)      theta = 1,3*t1 - 0,29*t2      k = dy/du

t = t(:); u = u(:); y = y(:);
d = detectar_degrau(t, u, y);

k  = d.dy / d.du;
yN = (y - d.y0) / d.dy;

t1 = tempo_cruzamento(t, yN, d, 0.353);
t2 = tempo_cruzamento(t, yN, d, 0.853);

tau = (2/3)*(t2 - t1);
if tau <= 0
    error('identificacao:tau', 'Sundaresan: tau calculado nao e positivo.');
end
theta = max(1.3*t1 - 0.29*t2, 0);

y_modelo = resposta_fopdt(t, d, k, tau, theta);
eqm = calcular_eqm(y, y_modelo);
end
