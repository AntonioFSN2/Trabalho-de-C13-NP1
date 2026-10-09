function yModelo = resposta_fopdt(t, d, k, tau, theta)
%RESPOSTA_FOPDT Simula o modelo FOPDT para o degrau ideal do ensaio.
%   yModelo = resposta_fopdt(t, d, k, tau, theta), com d vindo de
%   detectar_degrau. A entrada ideal e du*(t >= t0); como o lsim parte de
%   zero, soma-se o patamar inicial y0 da saida.

uIdeal  = d.du * double(t >= d.t0);
yModelo = lsim(tf(k, [tau 1], 'InputDelay', theta), uIdeal, t) + d.y0;
end
