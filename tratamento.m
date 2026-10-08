%% Identificação da planta (Forno, Grupo 5) - Smith e Sundaresan
% A planta é um forno simples: um sensor mede a temperatura atual
% (faixa de 0 a 100 °C), ligado a um controlador, e uma resistência de
% aquecimento é acionada por um módulo PWM (0 a 100 % de potência).

clear; clc; close all

%% pasta de saída das figuras
pastaFig = "figuras";
if ~exist(pastaFig, "dir")
    mkdir(pastaFig);
end

%% carregar dataset
load("Forno_G5.mat")
whos

%% dados brutos
figure
plot(t, Saida, 'LineWidth', 1.5); hold on
plot(t, Degrau, '--', 'LineWidth', 1.5);
xlabel("Tempo (s)"); ylabel("Amplitude");
legend("Saída (PV)", "Degrau (SP)", 'Location', 'best');
grid on
exportgraphics(gcf, fullfile(pastaFig, 'dados_brutos.png'), 'Resolution', 300);

%% instante do degrau (t0 = instante em que o degrau é aplicado, não o início do ensaio)
indice = find(Degrau >= 50, 1);   % limiar no meio do salto (0 -> 60), longe do ruído
t0 = t(indice);

% patamares da entrada, por média de trecho (reduz o ruído)
Vinicio = mean(Degrau(1:indice-1));
Vfinal = mean(Degrau(end - round(0.05*numel(Degrau)):end));   % últimas 51 amostras
du = Vfinal - Vinicio;

% patamares da saída, por média de trecho
yInicio = mean(Saida(1:max(indice-1,1)));
yFinal = mean(Saida(end - round(0.05*numel(Saida)):end));     % últimas 51 amostras
dy = yFinal - yInicio;

k = dy / du;   % ganho estático (°C/%)

% saída normalizada (0 a 1)
yNormalizado = (Saida - yInicio) / dy;

% tempo, a partir de t0, em que yNormalizado cruza cada percentual
cruzaPercentual = @(percentual) t(find(yNormalizado >= percentual, 1)) - t0;

%% medições de Smith e Sundaresan
% y(t) = 0                           para t < θ
% y(t) = 1 - exp(-(t - θ)/τ)         para t >= θ   (normalizada)
t1Smith = cruzaPercentual(0.283);
t2Smith = cruzaPercentual(0.632);
t1Sund  = cruzaPercentual(0.353);
t2Sund  = cruzaPercentual(0.853);

tauSmith = 1.5*(t2Smith - t1Smith);
thetaSmith = t2Smith - tauSmith;
tauSundaresan = (2/3) * (t2Sund - t1Sund);
thetaSundaresan = 1.3*t1Sund - 0.29*t2Sund;

%% simulação dos modelos
u = du * (t >= t0);
sysSundaresan = tf(k, [tauSundaresan, 1], 'InputDelay', thetaSundaresan);
sysSmith = tf(k, [tauSmith, 1], 'InputDelay', thetaSmith);

ySundaresan = lsim(sysSundaresan, u, t) + yInicio;
ySmith = lsim(sysSmith, u, t) + yInicio;

erroSmith = ySmith - Saida;
erroSundaresan = ySundaresan - Saida;

eqmSundaresan = sqrt(mean(erroSundaresan.^2))
eqmSmith = sqrt(mean(erroSmith.^2))

% ruído medido no trecho parado, para comparar com o EQM
ruido = std(Saida(1:indice-1))

%% gráficos: Smith x Sundaresan
figure
plot(t, Saida, 'Color', [0.7 0.7 0.7]); hold on
plot(t, ySmith, 'LineWidth', 1.5);
plot(t, ySundaresan, 'LineWidth', 1.5);
xlabel("Tempo (s)"); ylabel("Temperatura (°C)");
legend("Experimental", "Smith", "Sundaresan", 'Location', 'best');
grid on
exportgraphics(gcf, fullfile(pastaFig, 'smith_vs_sundaresan.png'), 'Resolution', 300);

figure
plot(t, erroSmith); hold on
plot(t, erroSundaresan);
yline(0, 'k--');
xlabel("Tempo (s)"); ylabel("Erro (°C)");
legend("Smith", "Sundaresan", "Zero", 'Location', 'best');
grid on
exportgraphics(gcf, fullfile(pastaFig, 'erro_smith_vs_sundaresan.png'), 'Resolution', 300);

%% EQM em função de τ e θ (ajuste fino, um parâmetro por vez)
eqmModelo = @(tau, theta) sqrt(mean((lsim(tf(k,[tau 1],'InputDelay',theta), u, t) + yInicio - Saida).^2));

% varredura de θ, com τ fixo no valor de Smith
thetas = thetaSmith + (-0.5:0.1:1.5);
eqms = arrayfun(@(th) eqmModelo(tauSmith, th), thetas);
[eqmMin, iMin] = min(eqms);
thetaAjust = thetas(iMin)

figure
plot(thetas, eqms, 'o-');
xlabel('\theta (s)'); ylabel('EQM (°C)'); grid on
exportgraphics(gcf, fullfile(pastaFig, 'eqm_vs_theta.png'), 'Resolution', 300);

% varredura de τ, com θ fixo no valor ajustado
taus = tauSmith + (-0.5:0.1:1.5);
eqmsTau = arrayfun(@(ta) eqmModelo(ta, thetaAjust), taus);
[eqmMinTau, jMin] = min(eqmsTau)
tauAjust = taus(jMin)

figure
plot(taus, eqmsTau, 'o-');
xlabel('\tau (s)'); ylabel('EQM (°C)'); grid on
exportgraphics(gcf, fullfile(pastaFig, 'eqm_vs_tau.png'), 'Resolution', 300);

%% modelo ajustado
yAjust = lsim(tf(k,[tauAjust 1],'InputDelay',thetaAjust), u, t) + yInicio;
erroAjust = yAjust - Saida;
eqmAjust = sqrt(mean(erroAjust.^2))

figure
plot(t, Saida, 'Color', [0.7 0.7 0.7]); hold on
plot(t, ySmith, 'LineWidth', 1.5);
plot(t, yAjust, 'LineWidth', 1.5);
xlabel("Tempo (s)"); ylabel("Temperatura (°C)");
legend("Experimental", "Smith original", "Smith ajustado", 'Location', 'best');
grid on
exportgraphics(gcf, fullfile(pastaFig, 'smith_vs_ajustado.png'), 'Resolution', 300);

figure
plot(t, erroSmith); hold on
plot(t, erroAjust);
yline(0, 'k--');
xlabel("Tempo (s)"); ylabel("Erro (°C)");
legend("Smith original", "Smith ajustado", "Zero", 'Location', 'best');
grid on
exportgraphics(gcf, fullfile(pastaFig, 'erro_smith_vs_ajustado.png'), 'Resolution', 300);

%% efeito de θ e τ sobre os dados (item 3 do enunciado)
% θ - 0,3 piora o EQM, θ + 0,3 melhora, e o par ajustado é o menor
ySimTheta1 = lsim(tf(k,[tauSmith 1],'InputDelay',thetaSmith - 0.3), u, t) + yInicio;
ySimTheta2 = lsim(tf(k,[tauSmith 1],'InputDelay',thetaSmith + 0.3), u, t) + yInicio;

figure
plot(t, Saida, 'Color', [0.7 0.7 0.7]); hold on
plot(t, ySimTheta1, 'LineWidth', 1.5);
plot(t, ySmith, 'LineWidth', 1.5);
plot(t, ySimTheta2, 'LineWidth', 1.5);
plot(t, yAjust, 'LineWidth', 1.5);
xlabel("Tempo (s)"); ylabel("Temperatura (°C)");
legend("Experimental", ...
       sprintf("\\theta = %.2f (EQM %.4f)", thetaSmith - 0.3, eqmModelo(tauSmith, thetaSmith - 0.3)), ...
       sprintf("Smith \\theta = %.2f (EQM %.4f)", thetaSmith, eqmSmith), ...
       sprintf("\\theta = %.2f (EQM %.4f)", thetaSmith + 0.3, eqmModelo(tauSmith, thetaSmith + 0.3)), ...
       sprintf("Ajustado \\tau = %.2f, \\theta = %.2f (EQM %.4f)", tauAjust, thetaAjust, eqmAjust), ...
       'Location', 'southeast');
grid on
xlim([0 60])   % foco no atraso e na subida, onde os modelos diferem
exportgraphics(gcf, fullfile(pastaFig, 'efeito_theta.png'), 'Resolution', 300);

%% salvar parâmetros do modelo final (origem rastreável para a main)
save("parametros_forno.mat", "k", "tauAjust", "thetaAjust")