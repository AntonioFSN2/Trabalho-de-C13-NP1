**PARTE TEÓRICA – QUESTÃO 2**



A variável controlada do sistema é a temperatura do forno, medida pelo sensor de temperatura.



A variável manipulada é a potência aplicada à resistência de aquecimento, controlada por meio do módulo PWM.



A principal perturbação considerada é a abertura do forno, que interfere na temperatura do processo.



As faixas de operação utilizadas no sistema são: - Temperatura: 0 a 100 °C. - PWM: 0% a 100%.



**Malha aberta:**



Tempo de subida: tr = 48,004846 s



Tempo de acomodação: ts = 90,528432 s



Overshoot: 0,000000 %



Erro: 0,295854



**Malha fechada:**



Tempo de subida: tr = 22,700887 s



Tempo de acomodação: ts = 45,325102 s



Overshoot: 0,000000 %



Erro: 0,586804



Análise:



A malha fechada apresentou uma resposta mais rápida que a malha aberta. O tempo de subida diminuiu de 48,004846 s para 22,700887 s e o tempo de acomodação diminuiu de 90,528432 s para 45,325102 s.



As duas respostas apresentaram 0% de overshoot.



Quanto ao erro obtido no código, a malha aberta apresentou 0,295854 e a malha fechada apresentou 0,586804.



Os métodos especificados são:



\-   IMC

\-   Cohen e Coon



O critério de desempenho escolhido para o nosso grupo é o menor índice de overshoot.



**PARÂMETROS DA PLANTA**



Os parâmetros finais utilizados foram:



k = 0,704146



tau = 21,850000 s



theta = 5,050000 s



**SINTONIA IMC**



O método IMC utiliza um parâmetro ajustável lambda (λ), que determina a velocidade da resposta do sistema.



ts = 4λ



Para a sintonia pelo método IMC, foram consideradas as opções de λ = 1,5θ e λ = 4θ. O parâmetro λ está relacionado à velocidade da resposta do sistema, sendo que valores menores de λ produzem uma resposta mais rápida. A escolha de λ = 4θ resulta em uma resposta mais lenta e menos agressiva. Como o critério de desempenho adotado é o menor overshoot, foi utilizada a opção λ = 4θ. Para a planta identificada, θ = 5,05 s, portanto:

λ = 4θ = 4 × 5,05 = 20,20 s.

Assim, foi utilizado λ = 20,20 s na sintonia IMC.



Com esse valor:



ts = 4 × 20,20 ts = 80,80 s



A escolha de λ = 20,20 s foi feita buscando uma resposta menos agressiva, coerente com o critério de priorizar o menor overshoot.



Os parâmetros obtidos pelo IMC foram:



Kp = 1,523274



Ti = 24,375000 s



Td = 2,263436 s



**SINTONIA COHEN E COON**



Os parâmetros obtidos pelo método de Cohen e Coon foram:



Kp = 8,547912



Ti = 11,354523 s



Td = 1,762308 s.



**ANÁLISE DO DESEMPENHO**



CONTROLADOR IMC



Tempo de subida:



tr = 43,714530 s



Tempo de acomodação:



ts = 81,219255 s



Overshoot:



0,000000 %



Erro:



0,000000



CONTROLADOR COHEN E COON



Tempo de subida:



tr = 1,612000 s



Tempo de acomodação:



ts = 45,243339 s



Overshoot:



90,019047 %



Erro:



0,000000



**COMPARAÇÃO ENTRE OS MÉTODOS**



O controlador Cohen e Coon apresentou uma resposta mais rápida que o IMC.



Cohen e Coon: tr = 1,612000 s ts = 45,243339 s Overshoot = 90,019047 %



IMC: tr = 43,714530 s ts = 81,219255 s Overshoot = 0,000000 %



Portanto, Cohen e Coon possui menor tempo de subida e menor tempo de acomodação.



Por outro lado, Cohen e Coon apresentou um índice de overshoot muito elevado, de 90,019047%, acompanhado de oscilações antes da estabilização.

Apesar de o controlador Cohen e Coon apresentar uma resposta mais rápida, seu grande overshoot e as oscilações observadas tornam sua resposta mais agressiva. O IMC apresenta uma resposta mais suave, sem overshoot, atendendo melhor ao critério adotado.

O IMC apresentou 0% de overshoot.



IMC: Overshoot = 0,000000 %



Cohen e Coon: Overshoot = 90,019047 %



Portanto, o IMC apresenta o menor índice de overshoot e é o método que melhor atende ao critério de desempenho especificado para o Grupo 5.



**CONCLUSÃO**



Foram comparados os controladores IMC e Cohen e Coon considerando os tempos de subida e acomodação e o índice de overshoot.



O método Cohen e Coon apresentou a resposta mais rápida, com tempo de subida de 1,612000 s e tempo de acomodação de 45,243339 s. Entretanto, apresentou overshoot de 90,019047%.



O método IMC apresentou tempo de subida de 43,714530 s e tempo de acomodação de 81,219255 s. Apesar de apresentar uma resposta mais lenta, não apresentou overshoot.



Como o desempenho especificado para o Grupo 5 é o menor índice de overshoot, o método IMC é o que melhor se adequa ao critério.



**RESULTADOS FINAIS**



Parâmetros da planta:



k = 0,704146 tau = 21,85 s theta = 5,05 s



IMC:



lambda = 20,20 s Kp = 1,523274 Ti = 24,375 s Td = 2,263436 s



Cohen e Coon:



Kp = 8,547912 Ti = 11,354523 s Td = 1,762308 s



Malha aberta:



tr = 48,004846 s ts = 90,528432 s Overshoot = 0% Erro = 0,295854



Malha fechada:



tr = 22,700887 s ts = 45,325102 s Overshoot = 0% Erro = 0,586804



IMC – desempenho:



tr = 43,714530 s ts = 81,219255 s Overshoot = 0% Erro = 0



Cohen e Coon – desempenho:



tr = 1,612000 s ts = 45,243339 s Overshoot = 90,019047% Erro = 0



**Método com menor overshoot: IMC**

