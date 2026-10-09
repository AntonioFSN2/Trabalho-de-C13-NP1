%% testes_interface.m
% Verifica os valores de referencia do Grupo 5 chamando as funcoes do
% grupo: as oficiais da raiz (sintonia_*, simular_malha, calcular_metricas)
% e as provisorias de stubs/ (carregar_dataset, identificar_*, ajuste_fino,
% calcular_eqm).
%
%   1) Sintonia e desempenho com o modelo de referencia (Smith ajustado)
%   2) Teste de estabilidade usado pela interface
%   3) Identificacao a partir do Forno_G5.mat (se o arquivo existir)
%   4) Abertura da interface com o Forno_G5.mat (se o arquivo existir)

raiz = fileparts(mfilename('fullpath'));
addpath(raiz);
addpath(fullfile(raiz, 'interface'));
if exist('carregar_dataset', 'file') == 0
    addpath(fullfile(raiz, 'stubs'), '-end');
end

falhas = 0;
fprintf('\n=== Testes da interface (Grupo 5) ===\n');

%% 1) Sintonia e desempenho com o modelo de referencia
k = 0.7041;  tau = 21.85;  theta = 5.05;  lambda = 20.2;
G = tf(k, [tau 1], 'InputDelay', theta);

fprintf('\n-- IMC (lambda = %.2f s) --\n', lambda);
[Kp, Ti, Td] = sintonia_imc(k, tau, theta, lambda);
falhas = falhas + verificar('Kp', Kp, 1.523, 0.002);
falhas = falhas + verificar('Ti (s)', Ti, 24.38, 0.01);
falhas = falhas + verificar('Td (s)', Td, 2.263, 0.002);
[tr, ts, mp] = calcular_metricas(simular_malha(G, Kp, Ti, Td));
falhas = falhas + verificar('tr (s)', tr, 43.7, 0.1);
falhas = falhas + verificar('ts (s)', ts, 81.2, 0.1);
falhas = falhas + verificar('Mp (%)', mp, 0, 0.01);

fprintf('\n-- Cohen e Coon --\n');
[Kp, Ti, Td] = sintonia_cohen_coon(k, tau, theta);
falhas = falhas + verificar('Kp', Kp, 8.548, 0.002);
falhas = falhas + verificar('Ti (s)', Ti, 11.35, 0.01);
falhas = falhas + verificar('Td (s)', Td, 1.762, 0.002);
[~, ~, mp] = calcular_metricas(simular_malha(G, Kp, Ti, Td));
falhas = falhas + verificar('Mp (%)', mp, 90, 1.0);

%% 2) Estabilidade (Pade de 3a ordem)
fprintf('\n-- Estabilidade --\n');
falhas = falhas + verificarLogico('IMC estavel', ...
    IHM_PID.malhaEstavel(k, tau, theta, 1.523, 24.38, 2.263), true);
falhas = falhas + verificarLogico('Cohen e Coon estavel', ...
    IHM_PID.malhaEstavel(k, tau, theta, 8.548, 11.35, 1.762), true);
falhas = falhas + verificarLogico('Kp = 50, Ti = 1, Td = 0 instavel', ...
    IHM_PID.malhaEstavel(k, tau, theta, 50, 1, 0), false);

%% 3) Identificacao com o dataset
arquivo = '';
candidatos = {fullfile(raiz, 'Forno_G5.mat'), fullfile(raiz, 'dados', 'Forno_G5.mat')};
for i = 1:numel(candidatos)
    if exist(candidatos{i}, 'file') == 2
        arquivo = candidatos{i};
        break
    end
end

if isempty(arquivo)
    fprintf('\n-- Identificacao: Forno_G5.mat nao encontrado, testes 3 e 4 pulados --\n');
else
    fprintf('\n-- Identificacao (%s) --\n', arquivo);
    [t, u, y, unidade] = carregar_dataset(arquivo);
    [kS, tauS, thS, eqmS] = identificar_smith(t, u, y);
    falhas = falhas + verificar('Smith k', kS, 0.7041, 0.001);
    falhas = falhas + verificar('Smith tau (s)', tauS, 22.05, 0.05);
    falhas = falhas + verificar('Smith theta (s)', thS, 4.65, 0.05);
    falhas = falhas + verificar('Smith EQM', eqmS, 0.6950, 0.005);

    [~, ~, ~, eqmSu] = identificar_sundaresan(t, u, y);
    falhas = falhas + verificar('Sundaresan EQM', eqmSu, 0.9585, 0.005);

    [tauA, thA, eqmA] = ajuste_fino(t, u, y, kS, tauS, thS);
    falhas = falhas + verificar('Ajustado tau (s)', tauA, 21.85, 0.05);
    falhas = falhas + verificar('Ajustado theta (s)', thA, 5.05, 0.05);
    falhas = falhas + verificar('Ajustado EQM', eqmA, 0.6538, 0.005);

    %% 4) Interface: carga do dataset e valores padrao
    fprintf('\n-- Interface --\n');
    app = IHM_PID;
    limpeza = onCleanup(@() delete(app));
    app.carregarArquivo(arquivo);
    falhas = falhas + verificarLogico('padrao = Smith ajustado (menor EQM)', ...
        strcmp(app.MetodoIdentDropDown.Items{app.MetodoIdentDropDown.Value}, 'Smith ajustado'), true);
    falhas = falhas + verificarLogico('k, tau, theta somente leitura', ...
        all(strcmp({app.kField.Editable, app.tauField.Editable, app.thetaField.Editable, ...
                    app.kPIDField.Editable, app.tauPIDField.Editable, app.thetaPIDField.Editable}, 'off')), true);
    falhas = falhas + verificar('lambda padrao = 4*theta', app.LambdaField.Value, 20.2, 0.05);
    falhas = falhas + verificar('Kp na interface', str2double(app.KpField.Value), 1.523, 0.002);
    falhas = falhas + verificar('Mp na interface (%)', sscanf(app.mpField.Value, '%f'), 0, 0.5);
    clear limpeza
end

%% Resultado
fprintf('\n');
if falhas == 0
    fprintf('Todos os testes passaram.\n');
else
    error('testes_interface:falha', '%d teste(s) falharam.', falhas);
end

%% Funcoes auxiliares
function n = verificar(nome, valor, esperado, tol)
if abs(valor - esperado) <= tol
    fprintf('[OK]    %-38s %10.4f  (esperado %.4f +/- %.4g)\n', nome, valor, esperado, tol);
    n = 0;
else
    fprintf(2, '[FALHA] %-38s %10.4f  (esperado %.4f +/- %.4g)\n', nome, valor, esperado, tol);
    n = 1;
end
end

function n = verificarLogico(nome, valor, esperado)
if isequal(logical(valor), esperado)
    fprintf('[OK]    %s\n', nome);
    n = 0;
else
    fprintf(2, '[FALHA] %s\n', nome);
    n = 1;
end
end
