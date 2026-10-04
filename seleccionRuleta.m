function [seleccionados, indices] = seleccionRuleta(poblacion, valores)
% SELECCIONRULETA  Ruleta con probabilidad inversamente proporcional al valor.
%   P(i) = (1/valores(i)) / sum(1./valores)   (ecuacion 12 de la guia)
%   Se gira la ruleta tantas veces como la mitad de la poblacion. Un mismo
%   individuo puede salir mas de una vez (seleccion con reemplazo).
%   poblacion: arreglo de structs, un individuo por elemento.
%   valores:   valor a minimizar de cada individuo, mismo orden que poblacion.
%              Todos deben ser mayores que 0.
%   seleccionados: individuos elegidos.
%   indices:       posiciones de los elegidos dentro de poblacion.

    if numel(valores) ~= numel(poblacion)
        error('seleccion:tamanos', ...
            'valores y poblacion deben tener la misma cantidad de elementos.');
    end
    if any(valores <= 0)
        error('seleccion:valoresNoPositivos', ...
            'La ruleta usa 1/valor: todos los valores deben ser mayores que 0.');
    end

    nSeleccionados = ceil(numel(poblacion) / 2);
    probabilidades = (1 ./ valores) / sum(1 ./ valores);
    acumulada = cumsum(probabilidades);
    acumulada(end) = 1;

    indices = zeros(1, nSeleccionados);
    for k = 1:nSeleccionados
        indices(k) = find(acumulada >= rand(), 1, 'first');
    end

    seleccionados = poblacion(indices);
end
