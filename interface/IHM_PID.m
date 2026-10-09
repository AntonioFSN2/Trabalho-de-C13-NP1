classdef IHM_PID < matlab.apps.AppBase
    %IHM_PID Interface grafica do Projeto Pratico C13 - Sistemas Embarcados.
    %   Identificacao de processos (Smith, Sundaresan, Smith ajustado) e
    %   sintonia de controladores PID (IMC, Cohen e Coon ou manual).
    %
    %   Uso:  app = IHM_PID;     (ou apenas IHM_PID na Command Window)
    %
    %   A classe so faz a interface: todo o calculo e feito pelas funcoes
    %   do grupo:
    %     - raiz do repositorio (oficiais): sintonia_imc, sintonia_cohen_coon,
    %       simular_malha(G, Kp, Ti, Td) e calcular_metricas(M);
    %     - stubs/ (provisorias): carregar_dataset, identificar_smith,
    %       identificar_sundaresan, ajuste_fino, calcular_eqm.
    %   As pastas sao adicionadas ao path automaticamente se faltar alguma.
    %
    %   Compativel com MATLAB R2019a ou superior. O arquivo e todo em ASCII
    %   porque o R2019a no Windows nao le .m em UTF-8; acentos e simbolos
    %   dos textos sao escritos como entidades (ex.: '&ccedil;') e
    %   convertidos por IHM_PID.tx.

    %% Dados do grupo (edite aqui)
    properties (Constant, Access = public)
        GRUPO       = 'Grupo 5'
        INTEGRANTES = {''}      % um nome por celula, ex.: {'Nome 1', 'Nome 2'}
    end

    %% Componentes da interface
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        TabGroup                    matlab.ui.container.TabGroup

        % Aba Inicio
        TabInicio                   matlab.ui.container.Tab
        TituloLabel                 matlab.ui.control.Label
        SubtituloLabel              matlab.ui.control.Label
        GrupoLabel                  matlab.ui.control.Label
        GrupoEditField              matlab.ui.control.EditField
        IntegrantesLabel            matlab.ui.control.Label
        IntegrantesTextArea         matlab.ui.control.TextArea
        InstrucoesLabel             matlab.ui.control.Label
        InstrucoesTextArea          matlab.ui.control.TextArea

        % Aba Identificacao (Figura 11a)
        TabIdent                    matlab.ui.container.Tab
        EscolherArquivoButton       matlab.ui.control.Button
        ArquivoLabel                matlab.ui.control.Label
        MetodoIdentLabel            matlab.ui.control.Label
        MetodoIdentDropDown         matlab.ui.control.DropDown
        kLabel                      matlab.ui.control.Label
        kField                      matlab.ui.control.EditField
        tauLabel                    matlab.ui.control.Label
        tauField                    matlab.ui.control.EditField
        thetaLabel                  matlab.ui.control.Label
        thetaField                  matlab.ui.control.EditField
        eqmLabel                    matlab.ui.control.Label
        eqmField                    matlab.ui.control.EditField
        ComparacaoLabel             matlab.ui.control.Label
        ComparacaoTextArea          matlab.ui.control.TextArea
        IdentAxes                   matlab.ui.control.UIAxes

        % Aba Controle PID (Figuras 11b, 12a e 12b)
        TabPID                      matlab.ui.container.Tab
        SintoniaButtonGroup         matlab.ui.container.ButtonGroup
        MetodoRadio                 matlab.ui.control.RadioButton
        ManualRadio                 matlab.ui.control.RadioButton
        MetodoPIDLabel              matlab.ui.control.Label
        MetodoPIDDropDown           matlab.ui.control.DropDown
        LambdaLabel                 matlab.ui.control.Label
        LambdaField                 matlab.ui.control.NumericEditField
        AvisoLambdaLabel            matlab.ui.control.Label
        KpLabel                     matlab.ui.control.Label
        KpField                     matlab.ui.control.EditField
        LimparKpButton              matlab.ui.control.Button
        TiLabel                     matlab.ui.control.Label
        TiField                     matlab.ui.control.EditField
        LimparTiButton              matlab.ui.control.Button
        TdLabel                     matlab.ui.control.Label
        TdField                     matlab.ui.control.EditField
        LimparTdButton              matlab.ui.control.Button
        SintonizarButton            matlab.ui.control.Button
        ModeloPIDLabel              matlab.ui.control.Label
        kPIDLabel                   matlab.ui.control.Label
        kPIDField                   matlab.ui.control.EditField
        tauPIDLabel                 matlab.ui.control.Label
        tauPIDField                 matlab.ui.control.EditField
        thetaPIDLabel               matlab.ui.control.Label
        thetaPIDField               matlab.ui.control.EditField
        SPLabel                     matlab.ui.control.Label
        SPField                     matlab.ui.control.NumericEditField
        trLabel                     matlab.ui.control.Label
        trField                     matlab.ui.control.EditField
        tsLabel                     matlab.ui.control.Label
        tsField                     matlab.ui.control.EditField
        mpLabel                     matlab.ui.control.Label
        mpField                     matlab.ui.control.EditField
        ExportarButton              matlab.ui.control.Button
        PIDAxes                     matlab.ui.control.UIAxes
    end

    %% Estado interno
    properties (Access = private)
        Dados               % struct: t, u, y, unidade, y0, yFinal, arquivo
        Modelos             % struct array: nome, k, tau, theta, eqm, y_modelo
        MetodosPID          % struct array: nome, usaLambda, calcular
        DatasetCarregado = false
        UltimaSintonia      % struct Kp, Ti, Td, descricao ([] se nao houver)
    end

    properties (Constant, Access = private)
        % Cores fixas de fundo E de texto, para ficar legivel tanto no tema
        % claro quanto no escuro (R2025a+)
        COR_LEITURA  = [1 1 1]           % fundo dos campos somente leitura
        COR_EDITAVEL = [1 1 1]           % fundo dos campos editaveis
        COR_TEXTO    = [0.10 0.10 0.10]  % texto dentro das caixas
        COR_AVISO    = [0.85 0.15 0.15]
        COR_OK       = [0.15 0.60 0.15]
    end

    %% Metodos publicos auxiliares (usados tambem pelo testes_interface.m)
    methods (Access = public)

        function carregarArquivo(app, arquivo)
            % Carrega o dataset, faz as tres identificacoes e libera a aba PID.
            % Se algo falhar, mostra uialert e mantem o estado anterior.
            try
                [t, u, y, unidade] = carregar_dataset(arquivo);
                modelos = IHM_PID.identificarTodos(t, u, y);
            catch ME
                uialert(app.UIFigure, ME.message, IHM_PID.tx('Dataset inv&aacute;lido'));
                return
            end

            [~, nome, ext] = fileparts(arquivo);
            app.Dados = struct('t', t, 'u', u, 'y', y, 'unidade', unidade, ...
                'arquivo', [nome ext]);
            % Temperatura inicial: patamar antes do degrau, igual ao inicio do modelo
            app.Dados.y0 = modelos(1).y_modelo(1);
            % Valor final da saida: media das ultimas 5% amostras (reduz o ruido)
            app.Dados.yFinal = mean(y(end - round(0.05*numel(y)):end));
            app.Modelos = modelos;
            app.DatasetCarregado = true;

            % Lista de identificacao: padrao = menor EQM
            [~, iMelhor] = min([modelos.eqm]);
            app.MetodoIdentDropDown.Items = {modelos.nome};
            app.MetodoIdentDropDown.ItemsData = 1:numel(modelos);
            app.MetodoIdentDropDown.Value = iMelhor;

            app.ArquivoLabel.Text = ['Arquivo: ' app.Dados.arquivo];
            app.ArquivoLabel.FontColor = app.COR_OK;
            app.atualizarComparacao(iMelhor);
            app.atualizarRotulosUnidade();
            app.SPField.Value = round(app.Dados.yFinal, 2);

            app.aplicarModeloSelecionado();
        end
    end

    methods (Static, Access = public)

        function estavel = malhaEstavel(k, tau, theta, Kp, Ti, Td)
            % Verifica a estabilidade da malha fechada com PID aproximando o
            % atraso por Pade de 3a ordem (malha montada pelo simular_malha).
            G = IHM_PID.modeloFOPDT(struct('k', k, 'tau', tau, 'theta', theta));
            estavel = isstable(simular_malha(pade(G, 3), Kp, Ti, Td));
        end

        function G = modeloFOPDT(mdl)
            % Planta FOPDT G(s) = k/(tau*s + 1)*exp(-theta*s) a partir do modelo.
            G = tf(mdl.k, [mdl.tau 1], 'InputDelay', mdl.theta);
        end

        function s = tx(s)
            % Converte entidades (ex.: '&ccedil;') em caracteres Unicode.
            % Aceita char ou cell de char.
            persistent mapa
            if isempty(mapa)
                mapa = {'&aacute;', 225; '&eacute;', 233; '&iacute;', 237; ...
                        '&oacute;', 243; '&uacute;', 250; '&atilde;', 227; ...
                        '&otilde;', 245; '&acirc;',  226; '&ecirc;',  234; ...
                        '&ocirc;',  244; '&ccedil;', 231; '&agrave;', 224; ...
                        '&Eacute;', 201; '&Ccedil;', 199; '&Atilde;', 195; ...
                        '&Aacute;', 193; ...
                        '&tau;',    964; '&theta;',  952; '&lambda;', 955; ...
                        '&deg;',    176; '&ndash;', 8211; '&le;',    8804; ...
                        '&times;',  215; '&bull;',  8226};
            end
            for i = 1:size(mapa, 1)
                s = strrep(s, mapa{i, 1}, char(mapa{i, 2}));
            end
        end
    end

    methods (Static, Access = private)

        function modelos = identificarTodos(t, u, y)
            % Chama as funcoes de identificacao e monta a lista de modelos.
            [k1, tau1, th1, e1, ym1] = identificar_smith(t, u, y);
            [k2, tau2, th2, e2, ym2] = identificar_sundaresan(t, u, y);
            [tau3, th3, e3, ym3]     = ajuste_fino(t, u, y, k1, tau1, th1);

            modelos = struct( ...
                'nome',     {'Smith', 'Sundaresan', 'Smith ajustado'}, ...
                'k',        {k1, k2, k1}, ...
                'tau',      {tau1, tau2, tau3}, ...
                'theta',    {th1, th2, th3}, ...
                'eqm',      {e1, e2, e3}, ...
                'y_modelo', {ym1, ym2, ym3});
        end

        function m = metodosDisponiveis()
            % Metodos de sintonia oferecidos na lista. Para adicionar um novo
            % metodo, basta incluir uma linha com o nome, se usa lambda e a
            % funcao que devolve [Kp, Ti, Td] a partir de (k, tau, theta, lambda).
            m = struct('nome', {}, 'usaLambda', {}, 'calcular', {});
            m(end+1) = struct('nome', 'IMC', 'usaLambda', true, ...
                'calcular', @(k, tau, theta, lambda) sintonia_imc(k, tau, theta, lambda));
            m(end+1) = struct('nome', 'Cohen e Coon', 'usaLambda', false, ...
                'calcular', @(k, tau, theta, ~) sintonia_cohen_coon(k, tau, theta));
            % Exemplo para o futuro:
            % m(end+1) = struct('nome', 'CHR sem sobrevalor', 'usaLambda', false, ...
            %     'calcular', @(k, tau, theta, ~) sintonia_chr(k, tau, theta));
        end

        function s = onoff(cond)
            if cond
                s = 'on';
            else
                s = 'off';
            end
        end

        function [valor, msg] = lerNumero(texto, nome)
            % Converte o texto de um campo em numero (aceita virgula decimal).
            valor = str2double(strrep(strtrim(texto), ',', '.'));
            msg = '';
            if isempty(strtrim(texto))
                msg = sprintf('Preencha o campo %s.', nome);
            elseif ~isfinite(valor) || ~isreal(valor)
                msg = IHM_PID.tx(sprintf('O campo %s deve ser num&eacute;rico.', nome));
            end
        end
    end

    %% Logica da interface
    methods (Access = private)

        function garantirFuncoesNoPath(~)
            % As funcoes oficiais ficam na raiz do repositorio (pasta acima
            % de interface/); as provisorias, em stubs/. A raiz entra no
            % inicio do path e stubs no FIM, para as oficiais terem prioridade.
            raiz = fullfile(fileparts(mfilename('fullpath')), '..');
            oficiais = {'sintonia_imc', 'sintonia_cohen_coon', 'simular_malha', ...
                'calcular_metricas'};
            if any(cellfun(@(f) exist(f, 'file') == 0, oficiais))
                addpath(raiz);
            end
            provisorias = {'carregar_dataset', 'identificar_smith', ...
                'identificar_sundaresan', 'ajuste_fino', 'calcular_eqm'};
            if any(cellfun(@(f) exist(f, 'file') == 0, provisorias))
                pastaStubs = fullfile(raiz, 'stubs');
                if exist(pastaStubs, 'dir') == 7
                    addpath(pastaStubs, '-end');
                end
            end
        end

        function mdl = modeloAtual(app)
            mdl = app.Modelos(app.MetodoIdentDropDown.Value);
        end

        function aplicarModeloSelecionado(app)
            % Atualiza a aba Identificacao e propaga k, tau e theta para a aba PID.
            mdl = app.modeloAtual();
            un  = app.Dados.unidade;

            app.kField.Value     = sprintf('%.4f', mdl.k);
            app.tauField.Value   = sprintf('%.4f', mdl.tau);
            app.thetaField.Value = sprintf('%.4f', mdl.theta);
            app.eqmField.Value   = sprintf('%.4f', mdl.eqm);
            app.plotarIdentificacao(mdl, un);

            app.kPIDField.Value     = sprintf('%.4f', mdl.k);
            app.tauPIDField.Value   = sprintf('%.4f', mdl.tau);
            app.thetaPIDField.Value = sprintf('%.4f', mdl.theta);

            % lambda padrao = 4*theta (resposta menos agressiva, menor overshoot)
            app.LambdaField.Value = max(4*mdl.theta, 0.01);

            app.UltimaSintonia = [];
            app.atualizarBloqueios();
            if app.MetodoRadio.Value
                app.sintonizarPorMetodo();
            else
                app.limparResultadosPID();
            end
        end

        function atualizarComparacao(app, iMelhor)
            un = app.Dados.unidade;
            linhas = cell(numel(app.Modelos), 1);
            for i = 1:numel(app.Modelos)
                linhas{i} = sprintf('%-15s EQM = %.4f %s', ...
                    app.Modelos(i).nome, app.Modelos(i).eqm, un);
                if i == iMelhor
                    linhas{i} = [linhas{i} '  (menor)'];
                end
            end
            app.ComparacaoTextArea.Value = linhas;
        end

        function atualizarRotulosUnidade(app)
            un = app.Dados.unidade;
            app.kLabel.Text    = ['k (' un '/%)'];
            app.eqmLabel.Text  = ['EQM (' un ')'];
            app.kPIDLabel.Text = ['k (' un '/%)'];
            app.SPLabel.Text   = ['SetPoint (' un ')'];
        end

        function atualizarBloqueios(app)
            % Regras de habilitacao dos campos (ver README).
            carregado = app.DatasetCarregado;
            manual    = app.ManualRadio.Value;
            usaLambda = false;
            if ~isempty(app.MetodosPID)
                usaLambda = app.MetodosPID(app.MetodoPIDDropDown.Value).usaLambda;
            end

            % Identificacao
            app.MetodoIdentDropDown.Enable = IHM_PID.onoff(carregado);

            % Modo de sintonia
            app.MetodoRadio.Enable = IHM_PID.onoff(carregado);
            app.ManualRadio.Enable = IHM_PID.onoff(carregado);

            % Modo Metodo: lista habilitada, lambda so no IMC
            app.MetodoPIDDropDown.Enable = IHM_PID.onoff(carregado && ~manual);
            app.LambdaField.Enable = IHM_PID.onoff(carregado && ~manual && usaLambda);

            % Modo Manual: Kp, Ti, Td editaveis e botoes de limpar/sintonizar
            editavel = IHM_PID.onoff(carregado && manual);
            corPID = app.COR_LEITURA;
            if carregado && manual
                corPID = app.COR_EDITAVEL;
            end
            for campo = [app.KpField, app.TiField, app.TdField]
                campo.Editable = editavel;
                campo.BackgroundColor = corPID;
                campo.FontColor = app.COR_TEXTO;
            end
            app.LimparKpButton.Enable   = editavel;
            app.LimparTiButton.Enable   = editavel;
            app.LimparTdButton.Enable   = editavel;
            app.SintonizarButton.Enable = editavel;

            app.SPField.Enable        = IHM_PID.onoff(carregado);
            app.ExportarButton.Enable = IHM_PID.onoff(carregado);

            % Aviso do criterio lambda/theta > 0,8
            app.AvisoLambdaLabel.Visible = 'off';
            if carregado && ~manual && usaLambda
                mdl = app.modeloAtual();
                theta = mdl.theta;
                if theta > 0
                    razao = app.LambdaField.Value / theta;
                    if razao <= 0.8
                        app.AvisoLambdaLabel.Text = IHM_PID.tx(sprintf( ...
                            'Aten&ccedil;&atilde;o: &lambda;/&theta; = %.2f &le; 0,8', razao));
                        app.AvisoLambdaLabel.Visible = 'on';
                    end
                end
            end
        end

        function sintonizarPorMetodo(app)
            % Calcula Kp, Ti, Td pelo metodo selecionado e simula.
            met = app.MetodosPID(app.MetodoPIDDropDown.Value);
            mdl = app.modeloAtual();
            lambda = app.LambdaField.Value;
            try
                [Kp, Ti, Td] = met.calcular(mdl.k, mdl.tau, mdl.theta, lambda);
            catch ME
                uialert(app.UIFigure, ME.message, 'Erro na sintonia');
                app.limparResultadosPID();
                return
            end
            app.KpField.Value = sprintf('%.4f', Kp);
            app.TiField.Value = sprintf('%.4f', Ti);
            app.TdField.Value = sprintf('%.4f', Td);

            descricao = met.nome;
            if met.usaLambda
                descricao = IHM_PID.tx(sprintf('%s (&lambda; = %.2f s)', met.nome, lambda));
            end
            app.executarSimulacao(Kp, Ti, Td, descricao);
        end

        function executarSimulacao(app, Kp, Ti, Td, descricao)
            % Verifica estabilidade, simula em desvio, calcula metricas e plota.
            mdl = app.modeloAtual();
            y0  = app.Dados.y0;
            ref = app.SPField.Value - y0;    % degrau de referencia em desvio

            if abs(ref) < 1e-9
                uialert(app.UIFigure, IHM_PID.tx( ...
                    'O SetPoint deve ser diferente da temperatura inicial do dataset.'), ...
                    'SetPoint');
                app.limparResultadosPID();
                return
            end

            try
                estavel = IHM_PID.malhaEstavel(mdl.k, mdl.tau, mdl.theta, Kp, Ti, Td);
            catch ME
                uialert(app.UIFigure, ME.message, IHM_PID.tx('Erro na verifica&ccedil;&atilde;o'));
                app.limparResultadosPID();
                return
            end
            if ~estavel
                uialert(app.UIFigure, IHM_PID.tx(sprintf(['A malha fechada &eacute; ' ...
                    'INST&Aacute;VEL com Kp = %.4g, Ti = %.4g s e Td = %.4g s.\n' ...
                    'Ajuste os par&acirc;metros e tente novamente.'], Kp, Ti, Td)), ...
                    IHM_PID.tx('Sistema inst&aacute;vel'), 'Icon', 'error');
                app.limparResultadosPID();
                return
            end

            % Malha fechada e metricas pelas funcoes da main
            % (simular_malha devolve o sistema; calcular_metricas usa stepinfo nele)
            tfinal = ceil(10*(mdl.tau + mdl.theta)/10)*10;
            try
                M = simular_malha(IHM_PID.modeloFOPDT(mdl), Kp, Ti, Td);
                [tr, ts, mp] = calcular_metricas(M);
                m = struct('tr', tr, 'ts', ts, 'mp', mp);
                % Curva para o grafico: degrau unitario escalado pelo SP em desvio
                tOut = (0:tfinal/4000:tfinal)';
                yDesvio = ref * step(M, tOut);
            catch ME
                uialert(app.UIFigure, ME.message, IHM_PID.tx('Erro na simula&ccedil;&atilde;o'));
                app.limparResultadosPID();
                return
            end

            app.UltimaSintonia = struct('Kp', Kp, 'Ti', Ti, 'Td', Td, 'descricao', descricao);
            app.trField.Value = sprintf('%.2f s', m.tr);
            app.tsField.Value = sprintf('%.2f s', m.ts);
            app.mpField.Value = sprintf('%.2f %%', m.mp);

            app.plotarMalhaFechada(tOut, y0 + yDesvio, m, descricao);
        end

        function limparResultadosPID(app)
            app.UltimaSintonia = [];
            app.trField.Value = '';
            app.tsField.Value = '';
            app.mpField.Value = '';
            cla(app.PIDAxes);
            legend(app.PIDAxes, 'off');
            title(app.PIDAxes, 'Resposta em malha fechada');
        end

        function plotarIdentificacao(app, mdl, un)
            ax = app.IdentAxes;
            cla(ax);
            hold(ax, 'on');
            plot(ax, app.Dados.t, app.Dados.y, 'Color', [0.65 0.65 0.65], ...
                'DisplayName', 'Dados experimentais');
            plot(ax, app.Dados.t, mdl.y_modelo, 'LineWidth', 1.8, ...
                'Color', [0 0.447 0.741], 'DisplayName', ['Modelo - ' mdl.nome]);
            hold(ax, 'off');
            grid(ax, 'on');
            xlim(ax, [app.Dados.t(1) app.Dados.t(end)]);
            xlabel(ax, 'Tempo (s)');
            ylabel(ax, IHM_PID.tx(['Sa&iacute;da (' un ')']));
            title(ax, IHM_PID.tx(sprintf( ...
                '%s: k = %.4f, &tau; = %.2f s, &theta; = %.2f s, EQM = %.4f %s', ...
                mdl.nome, mdl.k, mdl.tau, mdl.theta, mdl.eqm, un)), 'Interpreter', 'none');
            legend(ax, 'Location', 'southeast');
        end

        function plotarMalhaFechada(app, tOut, yAbs, m, descricao)
            % Resposta absoluta (y0 + desvio), SetPoint e marcacoes de tr, ts e pico.
            ax = app.PIDAxes;
            un = app.Dados.unidade;
            y0 = app.Dados.y0;
            SP = app.SPField.Value;
            corMarca = [0.85 0.33 0.10];

            cla(ax);
            hold(ax, 'on');
            hSP = plot(ax, [tOut(1) tOut(1) tOut(end)], [y0 SP SP], '--', ...
                'Color', [0.2 0.2 0.2], 'LineWidth', 1.2, 'DisplayName', 'SetPoint');
            hY = plot(ax, tOut, yAbs, 'LineWidth', 1.8, 'Color', [0 0.447 0.741], ...
                'DisplayName', IHM_PID.tx('Sa&iacute;da (malha fechada)'));

            yN = (yAbs - y0) / (yAbs(end) - y0);    % resposta normalizada (0 -> 1)

            % tr: marcado no instante em que a resposta atinge 90% do valor final
            i90 = find(yN >= 0.9, 1);
            if isfinite(m.tr) && ~isempty(i90)
                plot(ax, tOut(i90), yAbs(i90), 'o', 'Color', corMarca, ...
                    'MarkerFaceColor', corMarca);
                text(ax, tOut(i90), yAbs(i90), sprintf('  t_r = %.2f s', m.tr), ...
                    'VerticalAlignment', 'top', 'FontSize', 10);
            end

            % ts: criterio de 2%
            if isfinite(m.ts) && m.ts <= tOut(end)
                yts = interp1(tOut, yAbs, m.ts);
                plot(ax, m.ts, yts, 's', 'Color', corMarca, 'MarkerFaceColor', corMarca);
                text(ax, m.ts, yts, sprintf('  t_s = %.2f s', m.ts), ...
                    'VerticalAlignment', 'bottom', 'FontSize', 10);
            end

            % Pico (so quando ha sobressinal)
            if isfinite(m.mp) && m.mp > 0.01
                if yAbs(end) >= y0
                    [yPico, iPico] = max(yAbs);
                else
                    [yPico, iPico] = min(yAbs);
                end
                plot(ax, tOut(iPico), yPico, '^', 'Color', corMarca, ...
                    'MarkerFaceColor', corMarca);
                text(ax, tOut(iPico), yPico, sprintf('  M_p = %.2f %% (%.2f %s)', ...
                    m.mp, yPico, un), 'VerticalAlignment', 'bottom', 'FontSize', 10);
            end
            hold(ax, 'off');

            grid(ax, 'on');
            xlim(ax, [tOut(1) tOut(end)]);
            xlabel(ax, 'Tempo (s)');
            ylabel(ax, IHM_PID.tx(['Temperatura (' un ')']));
            title(ax, IHM_PID.tx(sprintf('Malha fechada &ndash; %s', descricao)), ...
                'Interpreter', 'none');
            legend(ax, [hY hSP], 'Location', 'southeast');
        end

        function exportarEixos(app, ax, nomePadrao)
            % Salva o grafico de um uiaxes como PNG.
            if isempty(ax.Children)
                uialert(app.UIFigure, IHM_PID.tx('N&atilde;o h&aacute; gr&aacute;fico para exportar.'), ...
                    'Exportar', 'Icon', 'info');
                return
            end
            [arq, pasta] = uiputfile('*.png', IHM_PID.tx('Salvar gr&aacute;fico'), nomePadrao);
            figure(app.UIFigure);    % devolve o foco ao app
            if isequal(arq, 0)
                return
            end
            caminho = fullfile(pasta, arq);

            try
                if ~verLessThan('matlab', '9.8')
                    % R2020a ou superior
                    exportgraphics(ax, caminho, 'Resolution', 300);
                else
                    % R2019a: uiaxes nao exporta direto; copia para figure invisivel
                    f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 600]);
                    limpeza = onCleanup(@() delete(f));
                    axNovo = axes(f);
                    copyobj(allchild(ax), axNovo);
                    xlim(axNovo, ax.XLim);
                    ylim(axNovo, ax.YLim);
                    grid(axNovo, 'on');
                    box(axNovo, 'on');
                    xlabel(axNovo, ax.XLabel.String);
                    ylabel(axNovo, ax.YLabel.String);
                    title(axNovo, ax.Title.String, 'Interpreter', 'none');
                    linhas = findobj(axNovo, 'Type', 'line', '-not', 'DisplayName', '');
                    if ~isempty(linhas)
                        legend(axNovo, flipud(linhas), 'Location', 'southeast');
                    end
                    print(f, caminho, '-dpng', '-r300');
                    clear limpeza
                end
            catch ME
                uialert(app.UIFigure, ME.message, 'Erro ao exportar');
                return
            end
            uialert(app.UIFigure, [IHM_PID.tx('Gr&aacute;fico salvo em ') caminho], ...
                'Exportar', 'Icon', 'success');
        end
    end

    %% Callbacks
    methods (Access = private)

        function startupFcn(app)
            app.garantirFuncoesNoPath();

            % Lista de metodos de sintonia
            app.MetodosPID = IHM_PID.metodosDisponiveis();
            app.MetodoPIDDropDown.Items = {app.MetodosPID.nome};
            app.MetodoPIDDropDown.ItemsData = 1:numel(app.MetodosPID);
            app.MetodoPIDDropDown.Value = 1;

            app.limparResultadosPID();
            app.atualizarBloqueios();
        end

        function TabGroupSelectionChanged(app, event)
            % A aba Controle PID so abre depois de um dataset valido.
            if event.NewValue == app.TabPID && ~app.DatasetCarregado
                app.TabGroup.SelectedTab = event.OldValue;
                uialert(app.UIFigure, IHM_PID.tx(['Carregue um dataset v&aacute;lido ' ...
                    'na aba Identifica&ccedil;&atilde;o antes de acessar o Controle PID.']), ...
                    'Aba bloqueada', 'Icon', 'info');
            end
        end

        function EscolherArquivoButtonPushed(app, ~)
            [arq, pasta] = uigetfile('*.mat', 'Selecione o dataset');
            figure(app.UIFigure);    % devolve o foco ao app
            if isequal(arq, 0)
                return
            end
            app.carregarArquivo(fullfile(pasta, arq));
        end

        function MetodoIdentDropDownValueChanged(app, ~)
            app.aplicarModeloSelecionado();
        end

        function SintoniaButtonGroupSelectionChanged(app, ~)
            app.atualizarBloqueios();
            if app.MetodoRadio.Value
                app.sintonizarPorMetodo();
            end
            % No modo Manual os valores atuais ficam como ponto de partida;
            % a simulacao so roda ao clicar em Sintonizar.
        end

        function MetodoPIDDropDownValueChanged(app, ~)
            app.atualizarBloqueios();
            app.sintonizarPorMetodo();
        end

        function LambdaFieldValueChanged(app, ~)
            app.atualizarBloqueios();
            mdl = app.modeloAtual();
            theta = mdl.theta;
            if theta > 0 && app.LambdaField.Value/theta <= 0.8
                uialert(app.UIFigure, IHM_PID.tx(sprintf(['&lambda;/&theta; = %.2f &le; 0,8: ' ...
                    'o crit&eacute;rio do IMC (&lambda;/&theta; > 0,8) n&atilde;o &eacute; atendido. ' ...
                    'A resposta pode ficar agressiva.'], app.LambdaField.Value/theta)), ...
                    'Aviso', 'Icon', 'warning');
            end
            app.sintonizarPorMetodo();
        end

        function LimparKpButtonPushed(app, ~)
            app.KpField.Value = '';
        end

        function LimparTiButtonPushed(app, ~)
            app.TiField.Value = '';
        end

        function LimparTdButtonPushed(app, ~)
            app.TdField.Value = '';
        end

        function SintonizarButtonPushed(app, ~)
            % Modo Manual: valida as entradas e simula (com teste de estabilidade).
            [Kp, msgKp] = IHM_PID.lerNumero(app.KpField.Value, 'Kp');
            [Ti, msgTi] = IHM_PID.lerNumero(app.TiField.Value, 'Ti');
            [Td, msgTd] = IHM_PID.lerNumero(app.TdField.Value, 'Td');

            erros = {};
            if ~isempty(msgKp), erros{end+1} = msgKp; elseif Kp <= 0, erros{end+1} = 'Kp deve ser maior que zero.'; end
            if ~isempty(msgTi), erros{end+1} = msgTi; elseif Ti <= 0, erros{end+1} = 'Ti deve ser maior que zero.'; end
            if ~isempty(msgTd), erros{end+1} = msgTd; elseif Td < 0,  erros{end+1} = 'Td deve ser maior ou igual a zero.'; end
            if ~isempty(erros)
                uialert(app.UIFigure, strjoin(erros, newline), IHM_PID.tx('Par&acirc;metros inv&aacute;lidos'));
                return
            end

            descricao = sprintf('Manual (Kp = %.4g, Ti = %.4g s, Td = %.4g s)', Kp, Ti, Td);
            app.executarSimulacao(Kp, Ti, Td, descricao);
        end

        function SPFieldValueChanged(app, ~)
            if app.MetodoRadio.Value
                app.sintonizarPorMetodo();
            elseif ~isempty(app.UltimaSintonia)
                s = app.UltimaSintonia;
                app.executarSimulacao(s.Kp, s.Ti, s.Td, s.descricao);
            end
        end

        function ExportarButtonPushed(app, ~)
            app.exportarEixos(app.PIDAxes, 'resposta_malha_fechada.png');
        end
    end

    %% Criacao dos componentes
    methods (Access = private)

        function createComponents(app)
            tx = @IHM_PID.tx;

            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 80 1100 680];
            app.UIFigure.Name = tx('IHM &ndash; Identifica&ccedil;&atilde;o e Sintonia PID (C13)');

            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1100 680];
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);

            % ---------------- Aba Inicio ----------------
            app.TabInicio = uitab(app.TabGroup, 'Title', tx('In&iacute;cio'));

            app.TituloLabel = uilabel(app.TabInicio);
            app.TituloLabel.Position = [40 560 1020 40];
            app.TituloLabel.Text = tx('Projeto Pr&aacute;tico C13 &ndash; Sistemas Embarcados');
            app.TituloLabel.FontSize = 26;
            app.TituloLabel.FontWeight = 'bold';
            app.TituloLabel.HorizontalAlignment = 'center';

            app.SubtituloLabel = uilabel(app.TabInicio);
            app.SubtituloLabel.Position = [40 520 1020 30];
            app.SubtituloLabel.Text = tx('Identifica&ccedil;&atilde;o de Processos & Sintonia de Controladores PID');
            app.SubtituloLabel.FontSize = 18;
            app.SubtituloLabel.HorizontalAlignment = 'center';

            app.GrupoLabel = uilabel(app.TabInicio);
            app.GrupoLabel.Position = [200 450 100 22];
            app.GrupoLabel.Text = 'Grupo:';
            app.GrupoLabel.FontWeight = 'bold';

            app.GrupoEditField = uieditfield(app.TabInicio, 'text');
            app.GrupoEditField.Position = [310 450 300 22];
            app.GrupoEditField.Value = IHM_PID.GRUPO;

            app.IntegrantesLabel = uilabel(app.TabInicio);
            app.IntegrantesLabel.Position = [200 410 100 22];
            app.IntegrantesLabel.Text = 'Integrantes:';
            app.IntegrantesLabel.FontWeight = 'bold';

            app.IntegrantesTextArea = uitextarea(app.TabInicio);
            app.IntegrantesTextArea.Position = [310 300 600 132];
            app.IntegrantesTextArea.Value = IHM_PID.INTEGRANTES;

            app.InstrucoesLabel = uilabel(app.TabInicio);
            app.InstrucoesLabel.Position = [200 255 200 22];
            app.InstrucoesLabel.Text = 'Como usar:';
            app.InstrucoesLabel.FontWeight = 'bold';

            app.InstrucoesTextArea = uitextarea(app.TabInicio);
            app.InstrucoesTextArea.Position = [200 60 710 190];
            app.InstrucoesTextArea.Editable = 'off';
            app.InstrucoesTextArea.BackgroundColor = app.COR_LEITURA;
            app.InstrucoesTextArea.FontColor = app.COR_TEXTO;
            app.InstrucoesTextArea.Value = tx({ ...
                ['1. Na aba Identifica&ccedil;&atilde;o, clique em "Escolher Arquivo" e ' ...
                 'selecione o dataset (.mat).'], ...
                ['2. Os modelos de Smith, Sundaresan e Smith ajustado s&atilde;o calculados; ' ...
                 'o de menor EQM vem selecionado. Troque pela lista, se quiser.'], ...
                ['3. Na aba Controle PID, escolha "M&eacute;todo" (IMC ou Cohen e Coon) ' ...
                 'ou "Manual" (digite Kp, Ti e Td e clique em Sintonizar).'], ...
                ['4. Ajuste o SetPoint, confira tr, ts e Mp no gr&aacute;fico e use ' ...
                 '"Exportar" para salvar a figura em PNG.'], ...
                '', ...
                ['k, &tau; e &theta; v&ecirc;m sempre da identifica&ccedil;&atilde;o ' ...
                 'selecionada e n&atilde;o podem ser editados.']});

            % ---------------- Aba Identificacao ----------------
            app.TabIdent = uitab(app.TabGroup, 'Title', tx('Identifica&ccedil;&atilde;o'));

            app.EscolherArquivoButton = uibutton(app.TabIdent, 'push');
            app.EscolherArquivoButton.Position = [20 590 150 30];
            app.EscolherArquivoButton.Text = 'Escolher Arquivo';
            app.EscolherArquivoButton.ButtonPushedFcn = createCallbackFcn(app, @EscolherArquivoButtonPushed, true);

            app.ArquivoLabel = uilabel(app.TabIdent);
            app.ArquivoLabel.Position = [20 560 300 22];
            app.ArquivoLabel.Text = 'Selecione um dataset';
            app.ArquivoLabel.FontColor = app.COR_AVISO;
            app.ArquivoLabel.FontWeight = 'bold';

            app.MetodoIdentLabel = uilabel(app.TabIdent);
            app.MetodoIdentLabel.Position = [20 515 100 22];
            app.MetodoIdentLabel.Text = tx('Identifica&ccedil;&atilde;o:');

            app.MetodoIdentDropDown = uidropdown(app.TabIdent);
            app.MetodoIdentDropDown.Position = [125 515 195 22];
            app.MetodoIdentDropDown.Items = {'-'};
            app.MetodoIdentDropDown.Enable = 'off';
            app.MetodoIdentDropDown.ValueChangedFcn = createCallbackFcn(app, @MetodoIdentDropDownValueChanged, true);

            [app.kLabel, app.kField]         = IHM_PID.campoLeitura(app.TabIdent, 470, 'k (/%)');
            [app.tauLabel, app.tauField]     = IHM_PID.campoLeitura(app.TabIdent, 435, tx('&tau; (s)'));
            [app.thetaLabel, app.thetaField] = IHM_PID.campoLeitura(app.TabIdent, 400, tx('&theta; (s)'));
            [app.eqmLabel, app.eqmField]     = IHM_PID.campoLeitura(app.TabIdent, 365, 'EQM');

            app.ComparacaoLabel = uilabel(app.TabIdent);
            app.ComparacaoLabel.Position = [20 320 300 22];
            app.ComparacaoLabel.Text = tx('Compara&ccedil;&atilde;o dos m&eacute;todos:');

            app.ComparacaoTextArea = uitextarea(app.TabIdent);
            app.ComparacaoTextArea.Position = [20 240 300 78];
            app.ComparacaoTextArea.Editable = 'off';
            app.ComparacaoTextArea.BackgroundColor = app.COR_LEITURA;
            app.ComparacaoTextArea.FontColor = app.COR_TEXTO;
            app.ComparacaoTextArea.FontName = 'Courier New';
            app.ComparacaoTextArea.Value = {''};

            app.IdentAxes = uiaxes(app.TabIdent);
            app.IdentAxes.Position = [340 20 740 610];
            title(app.IdentAxes, 'Selecione um dataset');
            xlabel(app.IdentAxes, 'Tempo (s)');
            ylabel(app.IdentAxes, tx('Sa&iacute;da'));
            grid(app.IdentAxes, 'on');

            % ---------------- Aba Controle PID ----------------
            app.TabPID = uitab(app.TabGroup, 'Title', 'Controle PID');

            app.SintoniaButtonGroup = uibuttongroup(app.TabPID);
            app.SintoniaButtonGroup.Position = [20 580 300 55];
            app.SintoniaButtonGroup.Title = 'Sintonia';
            app.SintoniaButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SintoniaButtonGroupSelectionChanged, true);

            app.MetodoRadio = uiradiobutton(app.SintoniaButtonGroup);
            app.MetodoRadio.Position = [15 6 100 22];
            app.MetodoRadio.Text = tx('M&eacute;todo');
            app.MetodoRadio.Value = true;

            app.ManualRadio = uiradiobutton(app.SintoniaButtonGroup);
            app.ManualRadio.Position = [160 6 100 22];
            app.ManualRadio.Text = 'Manual';

            app.MetodoPIDLabel = uilabel(app.TabPID);
            app.MetodoPIDLabel.Position = [20 545 80 22];
            app.MetodoPIDLabel.Text = tx('M&eacute;todo:');

            app.MetodoPIDDropDown = uidropdown(app.TabPID);
            app.MetodoPIDDropDown.Position = [100 545 220 22];
            app.MetodoPIDDropDown.Items = {'-'};
            app.MetodoPIDDropDown.ValueChangedFcn = createCallbackFcn(app, @MetodoPIDDropDownValueChanged, true);

            app.LambdaLabel = uilabel(app.TabPID);
            app.LambdaLabel.Position = [20 510 80 22];
            app.LambdaLabel.Text = tx('&lambda; (s):');

            app.LambdaField = uieditfield(app.TabPID, 'numeric');
            app.LambdaField.Position = [100 510 120 22];
            app.LambdaField.Limits = [0 Inf];
            app.LambdaField.LowerLimitInclusive = 'off';
            app.LambdaField.ValueDisplayFormat = '%.2f';
            app.LambdaField.Value = 1;
            app.LambdaField.ValueChangedFcn = createCallbackFcn(app, @LambdaFieldValueChanged, true);

            app.AvisoLambdaLabel = uilabel(app.TabPID);
            app.AvisoLambdaLabel.Position = [20 485 300 22];
            app.AvisoLambdaLabel.Text = '';
            app.AvisoLambdaLabel.FontColor = app.COR_AVISO;
            app.AvisoLambdaLabel.Visible = 'off';

            [app.KpLabel, app.KpField, app.LimparKpButton] = IHM_PID.campoPID(app.TabPID, 450, 'Kp');
            [app.TiLabel, app.TiField, app.LimparTiButton] = IHM_PID.campoPID(app.TabPID, 415, 'Ti (s)');
            [app.TdLabel, app.TdField, app.LimparTdButton] = IHM_PID.campoPID(app.TabPID, 380, 'Td (s)');
            app.LimparKpButton.ButtonPushedFcn = createCallbackFcn(app, @LimparKpButtonPushed, true);
            app.LimparTiButton.ButtonPushedFcn = createCallbackFcn(app, @LimparTiButtonPushed, true);
            app.LimparTdButton.ButtonPushedFcn = createCallbackFcn(app, @LimparTdButtonPushed, true);

            app.SintonizarButton = uibutton(app.TabPID, 'push');
            app.SintonizarButton.Position = [20 340 300 30];
            app.SintonizarButton.Text = 'Sintonizar';
            app.SintonizarButton.FontWeight = 'bold';
            app.SintonizarButton.ButtonPushedFcn = createCallbackFcn(app, @SintonizarButtonPushed, true);

            app.ModeloPIDLabel = uilabel(app.TabPID);
            app.ModeloPIDLabel.Position = [20 305 300 22];
            app.ModeloPIDLabel.Text = tx('Modelo (da identifica&ccedil;&atilde;o):');
            app.ModeloPIDLabel.FontWeight = 'bold';

            [app.kPIDLabel, app.kPIDField]         = IHM_PID.campoLeitura(app.TabPID, 275, 'k (/%)');
            [app.tauPIDLabel, app.tauPIDField]     = IHM_PID.campoLeitura(app.TabPID, 245, tx('&tau; (s)'));
            [app.thetaPIDLabel, app.thetaPIDField] = IHM_PID.campoLeitura(app.TabPID, 215, tx('&theta; (s)'));

            app.SPLabel = uilabel(app.TabPID);
            app.SPLabel.Position = [20 170 100 22];
            app.SPLabel.Text = 'SetPoint';
            app.SPLabel.FontWeight = 'bold';

            app.SPField = uieditfield(app.TabPID, 'numeric');
            app.SPField.Position = [125 170 120 22];
            app.SPField.ValueDisplayFormat = '%.2f';
            app.SPField.ValueChangedFcn = createCallbackFcn(app, @SPFieldValueChanged, true);

            [app.trLabel, app.trField] = IHM_PID.campoLeitura(app.TabPID, 130, 'tr (subida)');
            [app.tsLabel, app.tsField] = IHM_PID.campoLeitura(app.TabPID, 100, tx('ts (acomoda&ccedil;&atilde;o 2%)'));
            [app.mpLabel, app.mpField] = IHM_PID.campoLeitura(app.TabPID, 70, 'Mp (overshoot)');

            app.ExportarButton = uibutton(app.TabPID, 'push');
            app.ExportarButton.Position = [20 20 300 30];
            app.ExportarButton.Text = 'Exportar';
            app.ExportarButton.ButtonPushedFcn = createCallbackFcn(app, @ExportarButtonPushed, true);

            app.PIDAxes = uiaxes(app.TabPID);
            app.PIDAxes.Position = [340 20 740 610];
            xlabel(app.PIDAxes, 'Tempo (s)');
            ylabel(app.PIDAxes, 'Temperatura');
            grid(app.PIDAxes, 'on');

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Static, Access = private)

        function [rotulo, campo] = campoLeitura(pai, y, texto)
            % Rotulo + campo de texto SOMENTE LEITURA.
            rotulo = uilabel(pai);
            rotulo.Position = [20 y 150 22];
            rotulo.Text = texto;
            campo = uieditfield(pai, 'text');
            campo.Position = [175 y 145 22];
            campo.Editable = 'off';
            campo.BackgroundColor = IHM_PID.COR_LEITURA;
            campo.FontColor = IHM_PID.COR_TEXTO;
            campo.HorizontalAlignment = 'right';
        end

        function [rotulo, campo, botao] = campoPID(pai, y, texto)
            % Rotulo + campo de Kp/Ti/Td + botao de limpar.
            rotulo = uilabel(pai);
            rotulo.Position = [20 y 75 22];
            rotulo.Text = texto;
            campo = uieditfield(pai, 'text');
            campo.Position = [100 y 170 22];
            campo.HorizontalAlignment = 'right';
            botao = uibutton(pai, 'push');
            botao.Position = [280 y 40 22];
            botao.Text = char(215);    % "x" de limpar
        end
    end

    %% Criacao e destruicao do app
    methods (Access = public)

        function app = IHM_PID
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @startupFcn)
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end
