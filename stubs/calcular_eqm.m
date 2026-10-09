function eqm = calcular_eqm(y, y_modelo)
%CALCULAR_EQM Erro quadratico medio (raiz) entre dados e modelo.
%   eqm = calcular_eqm(y, y_modelo) = sqrt(mean((y_modelo - y).^2))
%
%   VERSAO PROVISORIA (stub): sera substituida pela implementacao oficial.

eqm = sqrt(mean((y_modelo(:) - y(:)).^2));
end
