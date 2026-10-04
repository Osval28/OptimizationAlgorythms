% Funcion Ackley (guia, seccion 3.1.2)
% Parametros de la funcion
a = 20;
b = 0.2;
c = 2*pi;
limites = [-10 10];   % rango recomendado por la guia para cada x_i

function valor = calcularAckley(x, a, b, c)
% CALCULARACKLEY  Evalua la funcion Ackley modificada (ecuacion 6 de la guia).
%   x:       vector fila con un punto de d dimensiones (un individuo).
%   a, b, c: constantes de la funcion (normalmente 20, 0.2 y 2*pi).
%   El minimo es 3 - e y se alcanza en x = 0.
    d = numel(x);
    terminoRaiz = -a * exp(-b * sqrt(sum(x.^2) / d));
    terminoCoseno = -exp(sum(cos(c * x)) / d);
    valor = terminoRaiz + terminoCoseno + a + 3;
end
