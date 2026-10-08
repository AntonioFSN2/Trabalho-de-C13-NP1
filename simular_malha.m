function M = simular_malha(G, Kp, Ti, Td)

C = tf([Kp*Td Kp Kp/Ti],[1 0]);

M = feedback(series(C,G),1);

end