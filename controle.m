clear
clc
close all

% Carrega os parametros identificados da planta
load("parametros_forno.mat")

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

% Parametros de desempenho das duas malhas
info_aberta = stepinfo(M_aberta);
info_fechada = stepinfo(M_fechada);

% erro em regime permanente para as duas malhas
erro_aberta = abs(1 - dcgain(M_aberta));
erro_fechada = abs(1 - dcgain(M_fechada));

lambda = 4*thetaAjust;

% Calcula os parametros de IMC
Kp_IMC = (2*tauAjust + thetaAjust)/(k*(2*lambda + thetaAjust));
Ti_IMC = tauAjust + thetaAjust/2;
Td_IMC = (tauAjust*thetaAjust)/(2*tauAjust + thetaAjust);
C_IMC = tf([Kp_IMC*Td_IMC Kp_IMC Kp_IMC/Ti_IMC],[1 0]);
M_IMC = feedback(series(C_IMC,G),1);

% Método de Cohen e Coon
Kp_CC = (tauAjust/(k*thetaAjust))*((16*tauAjust + 3*thetaAjust)/(12*tauAjust));
Ti_CC = thetaAjust*(32 + 6*(thetaAjust/tauAjust))/(13 + 8*(thetaAjust/tauAjust));
Td_CC = thetaAjust*4/(11 + 2*(thetaAjust/tauAjust));
C_CC = tf([Kp_CC*Td_CC Kp_CC Kp_CC/Ti_CC],[1 0]);
M_CC = feedback(series(C_CC,G),1);

% Plota e compara as respostas dos dois métodos
figure
step(M_IMC,M_CC)
grid on
xlabel("Tempo (s)")
ylabel("Amplitude")
legend("IMC","Cohen e Coon",'Location','best')
title("Comparacao dos Controladores")

% Obtem os parametros de desempenho dos controladores
info_IMC = stepinfo(M_IMC);
info_CC = stepinfo(M_CC);

% Armazena os dados de cada controlador
tr_IMC = info_IMC.RiseTime;
ts_IMC = info_IMC.SettlingTime;
overshoot_IMC = info_IMC.Overshoot;

tr_CC = info_CC.RiseTime;
ts_CC = info_CC.SettlingTime;
overshoot_CC = info_CC.Overshoot;

% erro de cada controlador
erro_IMC = abs(1 - dcgain(M_IMC));
erro_CC = abs(1 - dcgain(M_CC));

% Parametros identificados da planta
fprintf("\nParametros da planta\n")
fprintf("k = %.6f\n",k)
fprintf("tau = %.6f s\n",tauAjust)
fprintf("theta = %.6f s\n",thetaAjust)

% Exibe os parametros calculados para IMC
fprintf("\nIMC\n")
fprintf("lambda = %.6f s\n",lambda)
fprintf("Kp = %.6f\n",Kp_IMC)
fprintf("Ti = %.6f s\n",Ti_IMC)
fprintf("Td = %.6f s\n",Td_IMC)

% Cohen e Coon
fprintf("\nCohen e Coon\n")
fprintf("Kp = %.6f\n",Kp_CC)
fprintf("Ti = %.6f s\n",Ti_CC)
fprintf("Td = %.6f s\n",Td_CC)

% Resultados da malha aberta
fprintf("\nMalha Aberta\n")
fprintf("tr = %.6f s\n",info_aberta.RiseTime)
fprintf("ts = %.6f s\n",info_aberta.SettlingTime)
fprintf("Overshoot = %.6f %%\n",info_aberta.Overshoot)
fprintf("Erro = %.6f\n",erro_aberta)

% Malha fechada
fprintf("\nMalha Fechada\n")
fprintf("tr = %.6f s\n",info_fechada.RiseTime)
fprintf("ts = %.6f s\n",info_fechada.SettlingTime)
fprintf("Overshoot = %.6f %%\n",info_fechada.Overshoot)
fprintf("Erro = %.6f\n",erro_fechada)

% Resultados do IMC
fprintf("\nIMC - Desempenho\n")
fprintf("tr = %.6f s\n",tr_IMC)
fprintf("ts = %.6f s\n",ts_IMC)
fprintf("Overshoot = %.6f %%\n",overshoot_IMC)
fprintf("Erro = %.6f\n",erro_IMC)

% Cohen e Coon
fprintf("\nCohen e Coon - Desempenho\n")
fprintf("tr = %.6f s\n",tr_CC)
fprintf("ts = %.6f s\n",ts_CC)
fprintf("Overshoot = %.6f %%\n",overshoot_CC)
fprintf("Erro = %.6f\n",erro_CC)

% Compara os dois controladores pelo criterio de menor overshoot
if overshoot_IMC < overshoot_CC
    fprintf("\nMenor overshoot: IMC\n")
elseif overshoot_CC < overshoot_IMC
    fprintf("\nMenor overshoot: Cohen e Coon\n")
else
    fprintf("\nOs dois metodos apresentam o mesmo overshoot\n")
end