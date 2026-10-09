function [tau, theta, eqm, y_modelo] = ajuste_fino(t, u, y, k, tau0, theta0)
%AJUSTE_FINO Ajuste fino de tau e theta por varredura (um parametro por vez).
%   [tau, theta, eqm, y_modelo] = ajuste_fino(t, u, y, k, tau0, theta0)
%
%   VERSAO PROVISORIA (stub): sera substituida pela implementacao oficial.
%   Mesmo procedimento do tratamento.m:
%     1) varre theta em theta0 + (-0,5 : 0,1 : 1,5) com tau0 fixo;
%     2) varre tau em tau0 + (-0,5 : 0,1 : 1,5) com o theta ajustado fixo.
%   O ganho k nao e alterado.

t = t(:); u = u(:); y = y(:);
d = detectar_degrau(t, u, y);

eqmDe = @(ta, th) calcular_eqm(y, resposta_fopdt(t, d, k, ta, th));

% 1) theta, com tau fixo
thetas = theta0 + (-0.5:0.1:1.5);
thetas = thetas(thetas >= 0);
eqmsTheta = arrayfun(@(th) eqmDe(tau0, th), thetas);
[~, i] = min(eqmsTheta);
theta = thetas(i);

% 2) tau, com o theta ajustado fixo
taus = tau0 + (-0.5:0.1:1.5);
taus = taus(taus > 0);
eqmsTau = arrayfun(@(ta) eqmDe(ta, theta), taus);
[~, j] = min(eqmsTau);
tau = taus(j);

y_modelo = resposta_fopdt(t, d, k, tau, theta);
eqm = calcular_eqm(y, y_modelo);
end
