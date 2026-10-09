clear
clc
close all

%% Carrega os parametros identificados da planta
load("parametros_forno.mat")

%% Malhas Aberta e fechada
% Modelo FOPDT da planta:
G = tf(k,[tauAjust 1],'InputDelay',thetaAjust);

% Malha Aberta e Fechada
M_aberta = G;
M_fechada = feedback(G,1);

% Plota e compara a resposta da malha aberta com a malha fechada
figure
step(M_aberta,M_fechada)
grid on
xlabel("Tempo (s)")
ylabel("Amplitude")
legend("Malha Aberta","Malha Fechada",'Location','best')
title("Malha Aberta x Malha Fechada")

%% SINTONIA IMC

lambda_15 = 1.5*thetaAjust;
lambda_2 = 2*thetaAjust;
lambda_4 = 4*thetaAjust;

[Kp_15,Ti_15,Td_15] = sintonia_imc(k,tauAjust,thetaAjust,lambda_15);
[Kp_2,Ti_2,Td_2] = sintonia_imc(k,tauAjust,thetaAjust,lambda_2);
[Kp_4,Ti_4,Td_4] = sintonia_imc(k,tauAjust,thetaAjust,lambda_4);

M_IMC_15 = simular_malha(G,Kp_15,Ti_15,Td_15);
M_IMC_2 = simular_malha(G,Kp_2,Ti_2,Td_2);
M_IMC_4 = simular_malha(G,Kp_4,Ti_4,Td_4);

[tr_15,ts_15,overshoot_15] = calcular_metricas(M_IMC_15);
[tr_2,ts_2,overshoot_2] = calcular_metricas(M_IMC_2);
[tr_4,ts_4,overshoot_4] = calcular_metricas(M_IMC_4);

%% COMPARACAO DOS VALORES DE LAMBDA

figure
step(M_IMC_15,M_IMC_2,M_IMC_4)
grid on
xlabel("Tempo (s)")
ylabel("Amplitude")
legend("\lambda = 1,5\theta","\lambda = 2\theta","\lambda = 4\theta",'Location','best')
title("Comparacao dos valores de lambda")

%% ESCOLHA DO LAMBDA

lambda = lambda_4;

Kp_IMC = Kp_4;
Ti_IMC = Ti_4;
Td_IMC = Td_4;

M_IMC = M_IMC_4;

[tr_IMC,ts_IMC,overshoot_IMC] = calcular_metricas(M_IMC);

%% SINTONIA COHEN E COON

[Kp_CC,Ti_CC,Td_CC] = sintonia_cohen_coon(k,tauAjust,thetaAjust);

M_CC = simular_malha(G,Kp_CC,Ti_CC,Td_CC);

[tr_CC,ts_CC,overshoot_CC] = calcular_metricas(M_CC);

%% COMPARACAO IMC X COHEN E COON

figure
step(M_IMC,M_CC)
grid on
xlabel("Tempo (s)")
ylabel("Amplitude")
legend("IMC","Cohen e Coon",'Location','best')
title("Comparacao dos Controladores")

%% EXPORTACAO DOS GRAFICOS

exportgraphics(figure(1),"Malha_Aberta_Malha_Fechada.png")
exportgraphics(figure(2),"Comparacao_Lambda.png")
exportgraphics(figure(3),"Comparacao_IMC_Cohen_Coon.png")

%% Respostas
fprintf("\nParametros da planta\n")
fprintf("k = %.6f\n",k)
fprintf("tau = %.6f s\n",tauAjust)
fprintf("theta = %.6f s\n",thetaAjust)

fprintf("\nCOMPARACAO DOS VALORES DE LAMBDA\n")

fprintf("\nlambda = 1,5*theta\n")
fprintf("lambda = %.6f s\n",lambda_15)
fprintf("tr = %.6f s\n",tr_15)
fprintf("ts = %.6f s\n",ts_15)
fprintf("Overshoot = %.6f %%\n",overshoot_15)

fprintf("\nlambda = 2*theta\n")
fprintf("lambda = %.6f s\n",lambda_2)
fprintf("tr = %.6f s\n",tr_2)
fprintf("ts = %.6f s\n",ts_2)
fprintf("Overshoot = %.6f %%\n",overshoot_2)

fprintf("\nlambda = 4*theta\n")
fprintf("lambda = %.6f s\n",lambda_4)
fprintf("tr = %.6f s\n",tr_4)
fprintf("ts = %.6f s\n",ts_4)
fprintf("Overshoot = %.6f %%\n",overshoot_4)

fprintf("\nIMC ESCOLHIDO\n")
fprintf("lambda = %.6f s\n",lambda)
fprintf("Kp = %.6f\n",Kp_IMC)
fprintf("Ti = %.6f s\n",Ti_IMC)
fprintf("Td = %.6f s\n",Td_IMC)

fprintf("\nCOHEN E COON\n")
fprintf("Kp = %.6f\n",Kp_CC)
fprintf("Ti = %.6f s\n",Ti_CC)
fprintf("Td = %.6f s\n",Td_CC)

fprintf("\nDESEMPENHO IMC\n")
fprintf("tr = %.6f s\n",tr_IMC)
fprintf("ts = %.6f s\n",ts_IMC)
fprintf("Overshoot = %.6f %%\n",overshoot_IMC)

fprintf("\nDESEMPENHO COHEN E COON\n")
fprintf("tr = %.6f s\n",tr_CC)
fprintf("ts = %.6f s\n",ts_CC)
fprintf("Overshoot = %.6f %%\n",overshoot_CC)

fprintf("\n")

if overshoot_IMC < overshoot_CC
    fprintf("Metodo escolhido pelo menor overshoot: IMC\n")
elseif overshoot_CC < overshoot_IMC
    fprintf("Metodo escolhido pelo menor overshoot: Cohen e Coon\n")
else
    fprintf("Os dois metodos apresentam o mesmo overshoot\n")
end