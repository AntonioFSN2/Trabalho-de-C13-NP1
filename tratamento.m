load("Forno_G5.mat")
whos

% A planta envolve um funcionamento de um forno simples, onde há um sensor
% para medira temperatura atual,
% que range de 0 a 100°C, atrelado
% a um controlador, e uma resistência de aquecimento monitorada 
% por um módulo PWM, qu vai de 0 a 100% de potência

figure
plot(t,Saida,'LineWidth',1.5); hold on 
plot(t,Degrau, '--', 'LineWidth',1.5);
xlabel("Tempo (s)");ylabel("Amplitude");
legend("Saída (PV)", "Degrau (SP)", 'Location', 'best');
grid on

%% instante de degrau (tempo t = 0)
indice = find(Degrau >= 50, 1);
t0 = t(indice);

Vinicio = mean(Degrau(1:indice-1));
Vfinal = mean(Degrau(end - round(0.05*numel(Degrau)):end));
du = Vfinal - Vinicio;

%Saída (média das amostras para reduzir o ruído
yInicio = mean(Saida(1:max(indice-1,1)));
yFinal = mean(Saida(end - round(0.05*numel(Saida)):end));
dy = yFinal - yInicio;

k = dy / du;

%Saída normalizada
yNormalizado = (Saida - yInicio) / dy;

%ver os instantes que yNormalizado cruza cada percentual
cruzaPercentual = @(percentual) t(find(yNormalizado >= percentual, 1)) - t0;

%% medições de sundaresan e smith:
% y(t) = 0                           para t < θ
% y(t) = 1 - exp(-(t - θ)/τ)         para t ≥ θ   (normalizada)
t1Smith = cruzaPercentual(0.283);
t2Smith = cruzaPercentual(0.632);
t1Sund =  cruzaPercentual(0.353);
t2Sund = cruzaPercentual(0.853);

tauSmith = 1.5*(t2Smith - t1Smith);
thetaSmith = t2Smith - tauSmith;
tauSundaresan = (2/3) * (t2Sund - t1Sund);
thetaSundaresan = 1.3*t1Sund - 0.29*t2Sund;

%simulação dos modelos
u = du * (t >= t0);
sysSundaresan = tf(k, [tauSundaresan, 1], 'InputDelay', thetaSundaresan);
sysSmith = tf(k, [tauSmith, 1], 'InputDelay', thetaSmith);

ySundaresan = lsim(sysSundaresan, u, t) + yInicio;
ySmith = lsim(sysSmith, u, t) + yInicio;

erroSmith = ySmith - Saida;
erroSundaresan = ySundaresan - Saida;

eqmSundaresan = sqrt(mean(erroSundaresan.^2))
eqmSmith = sqrt(mean(erroSmith.^2))

%% gráficos
% 1) Dados x modelos
figure
plot(t, Saida, 'Color', [0.7 0.7 0.7]); hold on
plot(t, ySmith, 'LineWidth', 1.5);
plot(t, ySundaresan, 'LineWidth', 1.5);
xlabel("Tempo (s)"); ylabel("Temperatura (°C)");
legend("Experimental", "Smith", "Sundaresan", 'Location', 'best');
grid on
exportgraphics(gcf, 'modelos_vs_dados.png', 'Resolution', 300);

% 2) Erro de cada modelo
figure
plot(t, erroSmith); hold on
plot(t, erroSundaresan);
yline(0, 'k--');
xlabel("Tempo (s)"); ylabel("Erro (°C)");
legend("Smith", "Sundaresan", "Zero", 'Location', 'best');
grid on
exportgraphics(gcf, 'erro_modelos.png', 'Resolution', 300);

% 3) Ruído medido no trecho parado, para comparar com o EQM
ruido = std(Saida(1:indice-1))

%% calculo ero sistematico
eqmModelo = @(tau, theta) sqrt(mean((lsim(tf(k,[tau 1],'InputDelay',theta), u, t) + yInicio - Saida).^2));

%% varrer theta e tau
thetas = thetaSmith + (-0.5:0.1:1.5);
eqms = arrayfun(@(th) eqmModelo(tauSmith, th), thetas);
plot(thetas, eqms, 'o-'); xlabel('\theta (s)'); ylabel('EQM (°C)'); grid on
[eqmMin, i] = min(eqms);
thetaAjust = thetas(i)

taus = tauSmith + (-0.5:0.1:1.5)
eqmsTau = arrayfun(@(ta) eqmModelo(ta, thetaAjust), taus);
[eqmMinTau, j] = min(eqmsTau)
tauAjust = taus(j)
%% graficos

yAjust = lsim(tf(k,[tauAjust 1],'InputDelay',thetaAjust), u, t) + yInicio;
erroAjust = yAjust - Saida;
eqmAjust = sqrt(mean(erroAjust.^2))

%Figura 1: dados x modelos
figure
plot(t, Saida, 'Color', [0.7 0.7 0.7]); hold on
plot(t, ySmith, 'LineWidth', 1.5);
plot(t, yAjust, 'LineWidth', 1.5);
xlabel("Tempo (s)"); ylabel("Temperatura (°C)");
legend("Experimental", "Smith original", "Smith ajustado", 'Location', 'best');
grid on
exportgraphics(gcf, 'modelos_vs_dados.png', 'Resolution', 300);

%Figura 2: erro dos modelos
figure
plot(t, erroSmith); hold on
plot(t, erroAjust);
yline(0, 'k--');
xlabel("Tempo (s)"); ylabel("Erro (°C)");
legend("Smith original", "Smith ajustado", "Zero", 'Location', 'best');
grid on
exportgraphics(gcf, 'erro_modelos.png', 'Resolution', 300);