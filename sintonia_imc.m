function [Kp, Ti, Td] = sintonia_imc(k, tau, theta, lambda)

Kp = (2*tau + theta)/(k*(2*lambda + theta));
Ti = tau + theta/2;
Td = (tau*theta)/(2*tau + theta);

end