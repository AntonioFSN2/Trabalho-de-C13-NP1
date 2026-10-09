function [tr, ts, overshoot] = calcular_metricas(M)

info = stepinfo(M);

tr = info.RiseTime;
ts = info.SettlingTime;
overshoot = info.Overshoot;

end