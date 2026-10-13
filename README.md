# Projeto 1 — Identificação de Processos (Forno, Grupo 5)

Disciplina C13 — Sistemas Embarcados (Inatel).
Esta seção do repositório documenta a **identificação da planta** (Forno) a partir do Ensaio da Curva de Reação, usando os métodos de **Smith** e **Sundaresan**, com ajuste fino dos parâmetros.

> Integrantes: André Rocha de Mesquita, Antonio Feliciano da Silveira Neto e João Victor Batista Costa

---

## 1. Planta

Forno simples com:

- **Sensor** de temperatura com faixa de 0 a 100 °C (variável controlada / saída, PV).
- **Resistência de aquecimento** acionada por **módulo PWM**, de 0 a 100 % de potência (variável manipulada / entrada, SP).

A entrada (`Degrau`) está em **% de potência**; a saída (`Saida`) está em **°C**. Logo, o ganho estático `k` tem unidade **°C/%**.

## 2. Dataset

Arquivo: `Forno_G5.mat` (dataset original, apenas variáveis renomeadas).

| Variável | Tamanho | Descrição |
|---|---|---|
| `t` | 1000x1 | Tempo (s). Período de amostragem Ts = 0,1 s; ensaio de 100 s |
| `Saida` | 1000x1 | Temperatura medida (°C), com ruído |
| `Degrau` | 1000x1 | Entrada (% de potência), com ruído |
| `unidade_saida` | texto | `'°C'` |
| `descricao` | texto | Metadados do dataset |

## 3. Metodologia

Script: `tratamento.m`

1. **Instante do degrau (t0):** primeira amostra em que `Degrau >= 50` (limiar no meio do salto, longe do ruído dos dois patamares). Resultado: índice 51, **t0 = 5,0 s**.
2. **Patamares por média de trecho** (reduz o ruído):
   - `Vinicio`: média de `Degrau` antes do salto → −0,0210
   - `Vfinal`: média das últimas 5 % das amostras de `Degrau` → 59,9400
   - `du = Vfinal − Vinicio` = 59,9609
   - `yInicio`: média de `Saida` antes do salto → 31,9694 °C
   - `yFinal`: média das últimas 5 % das amostras de `Saida` → 74,1906 °C
   - `dy = yFinal − yInicio` = 42,2212 °C
3. **Ganho estático:** `k = dy / du` = **0,7041 °C/%**.
4. **Saída normalizada:** `yNormalizado = (Saida - yInicio) / dy`.
5. **Tempos de referência**, contados a partir de t0 (primeiro instante em que `yNormalizado >= p`):

| Método | p1 | t1 (s) | p2 | t2 (s) |
|---|---|---|---|---|
| Smith | 28,3 % | 12,0 | 63,2 % | 26,7 |
| Sundaresan | 35,3 % | 14,9 | 85,3 % | 44,4 |

6. **Parâmetros do modelo FOPDT** `H(s) = k / (τs + 1) · e^(−θs)`:
   - Smith: `τ = 1,5·(t2 − t1)`, `θ = t2 − τ`
   - Sundaresan: `τ = (2/3)·(t2 − t1)`, `θ = 1,3·t1 − 0,29·t2`
7. **Simulação:** entrada ideal `u = du·(t >= t0)`, `lsim` com `tf(k,[τ 1],'InputDelay',θ)` e soma de `yInicio` (o `lsim` parte de 0).
8. **Métrica:** EQM (RMSE) = `sqrt(mean((yModelo − Saida).^2))`.

## 4. Resultados

### Comparação dos métodos

| Método | τ (s) | θ (s) | θ/τ | EQM (°C) |
|---|---|---|---|---|
| Smith | 22,05 | 4,65 | 0,21 | **0,6950** |
| Sundaresan | 19,67 | 6,49 | 0,33 | 0,9585 |

Ruído medido no trecho parado (`std(Saida(1:indice-1))`): **0,4754 °C**.

**Método escolhido: Smith** (menor EQM).

### Ajuste fino (um parâmetro por vez)

| Modelo | τ (s) | θ (s) | EQM (°C) |
|---|---|---|---|
| Smith original | 22,05 | 4,65 | 0,6950 |
| θ − 0,3 (hipótese inicial, refutada) | 22,05 | 4,35 | 0,7762 |
| θ + 0,3 | 22,05 | 4,95 | 0,6588 |
| τ + 1 | 23,05 | 4,65 | 0,7707 |
| τ − 1 | 21,05 | 4,65 | 0,8876 |
| só θ ajustado | 22,05 | 5,05 | 0,6585 |
| **τ e θ ajustados** | **21,85** | **5,05** | **0,6538** |

Procedimento: varredura de θ (4,15 a 6,15 s, passo 0,1) com τ fixo, depois varredura de τ (21,55 a 23,55 s, passo 0,1) com o θ ajustado fixo. Nos dois casos o mínimo ficou no interior do intervalo.

### Modelo final adotado

```
k = 0,7041 °C/%     τ = 21,85 s     θ = 5,05 s     θ/τ ≈ 0,23

H(s) = 0,7041 / (21,85·s + 1) · e^(−5,05·s)
```

## 5. Discussão e limitações

- O ajuste fino reduziu o EQM em cerca de 6 % (0,6950 → 0,6538). O Smith original já estava próximo do melhor que o modelo FOPDT consegue.
- O EQM final continua acima do ruído (0,4754 °C). A parte restante é erro sistemático da estrutura do modelo (primeira ordem com atraso), e não de τ e θ. Reduzir o EQM abaixo do ruído seria ajustar o ruído (overfitting).
- A saída **ainda sobe lentamente em 100 s**, então `yFinal` pode estar subestimado. Isso afeta `dy`, `k` e principalmente o ponto de 85,3 % do Sundaresan, o que ajuda a explicar o pior desempenho dele neste dataset.
- τ e θ interagem: com θ maior, o melhor τ ficou um pouco menor.
- O limiar de detecção do degrau (50) foi escolhido a partir do gráfico; para outro dataset, convém derivá-lo dos dados (por exemplo, metade do patamar alto).
- `θ/τ ≈ 0,23` (modelo ajustado) fica abaixo de 0,3, faixa em que o método de Cohen e Coon é indicado (θ/τ > 0,3). Isso deve ser comentado na etapa de sintonia.

## 6. Como executar

### Requisitos

- MATLAB R2019a ou superior.
- Control System Toolbox.

**Observação:** algumas rotinas de exportação utilizam `exportgraphics`, disponível a partir do MATLAB R2020a. A compatibilidade da exportação depende da rotina executada.

### Identificação da planta

1. Coloque o arquivo `Forno_G5.mat` na raiz do repositório.
2. Abra o MATLAB na pasta raiz do projeto.
3. Execute:

```matlab
tratamento
```

O script realiza o tratamento dos dados, a identificação da planta e o ajuste fino dos parâmetros do modelo FOPDT. Os gráficos gerados são salvos como arquivos PNG.

### Análise de controle

Com o arquivo `parametros_forno.mat` disponível na raiz do projeto, execute:

```matlab
analise_controle
```

O script realiza as simulações e comparações de desempenho dos métodos de controle implementados.

### Interface gráfica

Para abrir a interface gráfica, execute:

```matlab
addpath interface
IHM_PID
```

A interface permite carregar o dataset, visualizar os resultados da identificação e configurar a sintonia do controlador PID.

### Testes

Para executar os testes da interface, utilize:

```matlab
testes_interface
```

Os testes que dependem do dataset exigem que `Forno_G5.mat` esteja na raiz do repositório.

## 7. Estrutura do repositório

```text
.
├── README.md
├── Forno_G5.mat
├── parametros_forno.mat
├── tratamento.m
├── analise_controle.m
├── calcular_metricas.m
├── simular_malha.m
├── sintonia_imc.m
├── sintonia_cohen_coon.m
├── Respostas.md
├── testes_interface.m
├── interface/
│   └── IHM_PID.m
├── stubs/
│   ├── ajuste_fino.m
│   ├── calcular_eqm.m
│   ├── carregar_dataset.m
│   ├── identificar_smith.m
│   ├── identificar_sundaresan.m
│   └── private/
│       ├── detectar_degrau.m
│       ├── resposta_fopdt.m
│       └── tempo_cruzamento.m
├── figuras/
    ├── dados_brutos.png
    ├── efeito_theta.png
    ├── eqm_vs_tau.png
    ├── eqm_vs_theta.png
    ├── erro_smith_vs_ajustado.png
    ├── erro_smith_vs_sundaresan.png
    ├── smith_vs_ajustado.png
    ├── smith_vs_sundaresan.png
    ├── Malha_Aberta_Malha_Fechada.png
    ├── Comparacao_IMC_Cohen_Coon.png
    └── Comparacao_Lambda.png
```
Os arquivos `.m` contêm os scripts de tratamento dos dados, identificação da planta, sintonia dos controladores e análise de desempenho. A pasta `interface/` contém a interface gráfica, enquanto `stubs/` reúne as implementações provisórias utilizadas pela interface. Os arquivos PNG apresentam os gráficos gerados durante as análises.

## 8. Controle e análise de desempenho

Nesta etapa, foram analisadas as respostas do forno em malha aberta e em malha fechada, além do desempenho dos controladores PID sintonizados pelos métodos IMC e Cohen e Coon.

### 8.1. Comparação entre malha aberta e malha fechada

A comparação entre as respostas permite observar o comportamento dinâmico do processo com e sem realimentação.

| Configuração | Tempo de subida | Tempo de acomodação | Overshoot |
|---|---:|---:|---:|
| Malha aberta | 48,00 s | 90,53 s | 0% |
| Malha fechada, sem controlador PID | 22,70 s | 45,33 s | 0% |

Os resultados mostram que, nas simulações realizadas, a malha fechada apresentou menores tempos de subida e acomodação em relação à malha aberta.

### 8.2. Sintonia dos controladores PID

Foram utilizados dois métodos de sintonia: IMC (*Internal Model Control*) e Cohen e Coon.

Para o método IMC, adotou-se a relação lambda = 4theta. Como o atraso de transporte ajustado foi de 5,05 s, obteve-se lambda = 20,20 s.

O método Cohen e Coon também foi aplicado para permitir a comparação entre as respostas dos controladores.

### 8.3. Resultados dos controladores

As respostas foram avaliadas pelo tempo de subida, tempo de acomodação e overshoot.

| Método | Tempo de subida | Tempo de acomodação | Overshoot |
|---|---:|---:|---:|
| IMC | 43,71 s | 81,22 s | 0% |
| Cohen e Coon | 1,61 s | 45,24 s | 90,02% |

O controlador Cohen e Coon apresentou uma resposta inicial mais rápida, mas com overshoot elevado. Já o IMC apresentou resposta sem overshoot, embora com tempos de subida e acomodação maiores.

### 8.4. Escolha do método

Considerando a prioridade de evitar sobrevalor na temperatura do forno, o método IMC foi considerado o mais adequado entre os dois métodos avaliados. O resultado indica um compromisso entre rapidez de resposta e redução do overshoot.

A escolha é baseada nas métricas obtidas nas simulações, sem afirmar que o IMC é superior em todos os critérios de desempenho.

### 8.5. Aspectos teóricos do processo

A variável controlada é a temperatura do forno, medida pelo sensor. A variável manipulada é a potência fornecida à resistência de aquecimento, regulada pelo módulo PWM.

A abertura da porta do forno e a entrada de ar externo podem atuar como perturbações térmicas. As faixas de operação consideradas são de 0 a 100 °C para a temperatura e de 0% a 100% para a potência do PWM.## 9. Interface gráfica (IHM)

Item 7 da parte prática (Figuras 11 e 12 do enunciado). Arquivo: `interface/IHM_PID.m`.

### Como abrir

Requisitos: MATLAB R2019a ou superior, com Control System Toolbox.

```matlab
% na pasta raiz do repositório
addpath interface
IHM_PID
```

A interface só chama as funções de cálculo do grupo:

| Função | Onde está | Uso |
|---|---|---|
| `sintonia_imc(k, tau, theta, lambda)`, `sintonia_cohen_coon(k, tau, theta)` | raiz (oficial) | Sintonia do PID |
| `M = simular_malha(G, Kp, Ti, Td)` | raiz (oficial) | Malha fechada com PID |
| `[tr, ts, overshoot] = calcular_metricas(M)` | raiz (oficial) | tr, ts e Mp via `stepinfo` |
| `carregar_dataset` | `stubs/` (provisória) | Lê o arquivo `.mat` e valida o dataset |
| `identificar_smith`, `identificar_sundaresan`, `ajuste_fino` | `stubs/` (provisória) | Identificação |
| `calcular_eqm` | `stubs/` (provisória) | Erro quadrático médio |

Ao abrir, a interface adiciona a raiz do repositório ao path e a pasta `stubs/` **no fim** dele. Assim, as versões oficiais sempre têm prioridade. Quando as funções de identificação oficiais forem criadas na raiz com as mesmas assinaturas, os stubs deixam de ser usados e podem ser apagados.

Para conferir os valores de referência, execute `testes_interface.m` na raiz. Os testes de identificação e da própria interface só rodam se o `Forno_G5.mat` estiver na raiz.

### Fluxo de uso

1. **Início:** título, grupo, integrantes e instruções. Para preencher grupo e integrantes de forma permanente, edite as constantes `GRUPO` e `INTEGRANTES` no topo de `IHM_PID.m`.
2. **Identificação:**
   - Clique em **Escolher Arquivo** e selecione o `.mat`. O dataset é validado: existência das variáveis `t`, `Degrau` e `Saida`, tamanhos iguais, amostragem uniforme e presença de degrau.
   - Se o dataset for inválido, aparece um alerta e nada é liberado.
   - Com um dataset válido, são calculados Smith, Sundaresan e Smith ajustado. A lista vem com o método de **menor EQM** selecionado, e o gráfico mostra os dados e o modelo escolhido.
3. **Controle PID:**
   - **Método:** escolha IMC ou Cohen e Coon. Kp, Ti e Td são calculados e o gráfico é atualizado automaticamente a cada troca de método ou de λ. O λ padrão é 4θ.
   - **Manual:** digite Kp, Ti e Td (vírgula ou ponto decimal) e clique em **Sintonizar**. A estabilidade é verificada antes de simular, com `isstable(simular_malha(pade(G,3), Kp, Ti, Td))`. Se a malha for instável, aparece um alerta e nada é plotado.
   - O **SetPoint** começa no valor final da saída do dataset. A simulação é incremental: em desvio a partir da temperatura inicial y0, com o gráfico em valores absolutos.
   - tr, ts (critério de 2%) e Mp aparecem nos campos e marcados no gráfico.
   - **Exportar** salva o gráfico em PNG. No R2019a, a figura é copiada para uma `figure` invisível, porque `exportgraphics` só existe a partir do R2020a.

### Regras de bloqueio dos campos

| Campo | Situação |
|---|---|
| Aba Controle PID | Bloqueada até um dataset válido ser carregado |
| k, τ, θ, EQM (Identificação) | Sempre somente leitura |
| k, τ, θ (Controle PID) | Sempre somente leitura; vêm da identificação selecionada |
| tr, ts, Mp | Sempre somente leitura |
| Lista de métodos | Habilitada só no modo **Método** |
| λ | Habilitado só no modo **Método** com **IMC**; aviso se λ/θ ≤ 0,8 |
| Kp, Ti, Td e botões de limpar (×) | Editáveis só no modo **Manual**; no modo Método mostram os valores calculados, bloqueados |
| Sintonizar | Habilitado só no modo **Manual**; exige Kp > 0, Ti > 0 e Td ≥ 0 |

### Testes e limitações

- Os testes automatizados podem ser executados pelo arquivo `testes_interface.m`, localizado na raiz do repositório.
- Os testes que dependem do dataset exigem que o arquivo `Forno_G5.mat` esteja disponível na raiz.
- As funções de identificação e cálculo do EQM localizadas em `stubs/` são implementações provisórias e devem ser substituídas pelas versões oficiais quando estas estiverem disponíveis.

### Observações

- **Novo método de sintonia** (por exemplo, CHR sem sobrevalor): basta adicionar uma linha em `metodosDisponiveis` dentro de `IHM_PID.m`, com o nome, se usa λ e a função que devolve `[Kp, Ti, Td]`.
- **Arquivos `.m` só com caracteres ASCII:** o R2019a no Windows não lê arquivos `.m` em UTF-8. Por isso, os textos com acento na interface são escritos como entidades (`&ccedil;`, `&theta;`, ...) e convertidos por `IHM_PID.tx`.
- **PID na forma ideal:** o `simular_malha` usa a forma ideal `Kp(1 + 1/(Ti·s) + Td·s)`. As métricas vêm do `stepinfo` do sistema; a curva do gráfico vem de `step` com o degrau escalado pelo SP em desvio.

## Referências

- C. L. Smith. *Process Control and Instrumentation Technology*. Addison-Wesley, 1972.
- K. R. Sundaresan e P. R. Krishnaswamy. Estimation of time delay, time constant and transfer function model from process step response. *Ind. Eng. Chem. Process Des. Dev.* 17(2), 1978, pp. 236–241.
