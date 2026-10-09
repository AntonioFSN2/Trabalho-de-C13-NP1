function [t, u, y, unidade] = carregar_dataset(arquivo)
%CARREGAR_DATASET Carrega e valida o dataset do ensaio de curva de reacao.
%   [t, u, y, unidade] = carregar_dataset(arquivo)
%
%   VERSAO PROVISORIA (stub): sera substituida pela implementacao oficial.
%   Espera um .mat com as variaveis t, Degrau e Saida (vetores de mesmo
%   tamanho) e, opcionalmente, unidade_saida. Devolve vetores coluna.
%   Gera erro com mensagem legivel se o arquivo for invalido ou se nao
%   houver degrau na entrada.

if ~(ischar(arquivo) || isstring(arquivo)) || exist(char(arquivo), 'file') ~= 2
    error('carregar_dataset:arquivo', 'Arquivo nao encontrado.');
end
arquivo = char(arquivo);

try
    S = load(arquivo);
catch ME
    error('carregar_dataset:leitura', 'Nao foi possivel ler o arquivo .mat (%s).', ME.message);
end

% Variaveis obrigatorias
obrigatorias = {'t', 'Degrau', 'Saida'};
faltando = obrigatorias(~isfield(S, obrigatorias));
if ~isempty(faltando)
    error('carregar_dataset:variaveis', ...
        'Variaveis ausentes no dataset: %s.', strjoin(faltando, ', '));
end

t = S.t;
u = S.Degrau;
y = S.Saida;
if ~all(cellfun(@(v) isnumeric(v) && isreal(v) && isvector(v), {t, u, y}))
    error('carregar_dataset:formato', 't, Degrau e Saida devem ser vetores numericos reais.');
end
t = double(t(:));
u = double(u(:));
y = double(y(:));

% Tamanhos e conteudo
if numel(t) ~= numel(u) || numel(t) ~= numel(y)
    error('carregar_dataset:tamanho', ...
        'Os vetores tem tamanhos diferentes (t: %d, Degrau: %d, Saida: %d).', ...
        numel(t), numel(u), numel(y));
end
if numel(t) < 20
    error('carregar_dataset:tamanho', 'O dataset tem poucas amostras (%d).', numel(t));
end
if any(~isfinite([t; u; y]))
    error('carregar_dataset:valores', 'O dataset contem valores NaN ou Inf.');
end

% Tempo crescente e com amostragem uniforme (exigencia do lsim)
dt = diff(t);
if any(dt <= 0)
    error('carregar_dataset:tempo', 'O vetor de tempo t deve ser estritamente crescente.');
end
if max(abs(dt - mean(dt))) > 1e-3*mean(dt)
    error('carregar_dataset:tempo', 'O vetor de tempo t deve ter amostragem uniforme.');
end

% Presenca do degrau (gera erro se nao houver)
detectar_degrau(t, u, y);

% Unidade da saida
unidade = '';
if isfield(S, 'unidade_saida')
    unidade = char(S.unidade_saida);
    unidade = strtrim(unidade(1, :));
end
if isempty(unidade)
    unidade = [char(176) 'C'];
end
end
