# Projeto 1 — Identificação de Processos (Forno, Grupo 5)

Disciplina C13 — Sistemas Embarcados (Inatel).
Esta seção do repositório documenta a **identificação da planta** (Forno) a partir do Ensaio da Curva de Reação, usando os métodos de **Smith** e **Sundaresan**, com ajuste fino dos parâmetros.

> Integrantes: _preencher nomes_

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

Requisitos: MATLAB R2019a ou superior com Control System Toolbox (`tf`, `lsim`). `exportgraphics` exige R2020a ou superior; em versões anteriores use `saveas`.

1. Coloque `Forno_G5.mat` na mesma pasta de `tratamento.m`.
2. Execute `tratamento.m`.
3. As variáveis finais (`k`, `tauAjust`, `thetaAjust`, `eqmAjust`) ficam no workspace e os gráficos são salvos como PNG.

## 7. Estrutura sugerida do repositório

```
.
├── README.md
├── Forno_G5.mat
├── tratamento.m
└── figuras/
    ├── modelos_vs_dados.png
    └── erro_modelos.png
```

## 8. Próximas etapas

- [ ] Respostas em malha aberta e fechada (`feedback`, Padé se necessário) e comparação de tempos de subida, acomodação e erro
- [ ] Sintonia do PID por **IMC** e **Cohen e Coon** (justificar o λ do IMC)
- [ ] Análise do método com menor overshoot (critério do Grupo 5)
- [ ] Interface gráfica (Figuras 11 e 12 do enunciado)
- [ ] Parte teórica: descrição da planta, sensores/atuadores, perturbações e faixas de operação

## Referências

- C. L. Smith. *Process Control and Instrumentation Technology*. Addison-Wesley, 1972.
- K. R. Sundaresan e P. R. Krishnaswamy. Estimation of time delay, time constant and transfer function model from process step response. *Ind. Eng. Chem. Process Des. Dev.* 17(2), 1978, pp. 236–241.
