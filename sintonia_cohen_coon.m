function [Kp, Ti, Td] = sintonia_cohen_coon(k, tau, theta)

Kp = (tau/(k*theta))*((16*tau + 3*theta)/(12*tau));
Ti = theta*(32 + 6*(theta/tau))/(13 + 8*(theta/tau));
Td = 4*theta/(11 + 2*(theta/tau));

end