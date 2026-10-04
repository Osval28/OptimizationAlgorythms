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

function [valido, motivo] = esValido(x, limites, d)
% ESVALIDO  Verifica que un individuo de Ackley cumpla las restricciones.
%   x:       individuo (vector de numeros reales).
%   limites: [minimo maximo] permitido para cada x_i.
%   d:       (opcional) numero de dimensiones esperado.
%   valido:  true si cumple todo.
%   motivo:  texto con la primera restriccion que falla ('' si es valido).
    valido = false;
    if ~isnumeric(x) || ~isreal(x) || ~isvector(x)
        motivo = 'no es un vector de numeros reales';
    elseif nargin >= 3 && numel(x) ~= d
        motivo = sprintf('tiene %d dimensiones y se esperaban %d', numel(x), d);
    elseif any(~isfinite(x))
        motivo = 'contiene NaN o Inf';
    elseif any(x < limites(1) | x > limites(2))
        motivo = sprintf('tiene valores fuera de [%g, %g]', limites(1), limites(2));
    else
        valido = true;
        motivo = '';
    end
end
