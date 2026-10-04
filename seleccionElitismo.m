function [seleccionados, indices] = seleccionElitismo(poblacion, valores)
% SELECCIONELITISMO  Selecciona la mitad de la poblacion con menor valor.
%   poblacion: arreglo de structs, un individuo por elemento.
%   valores:   valor a minimizar de cada individuo, en el mismo orden que
%              poblacion. Ejemplo de llamada: seleccionElitismo(p, [p.tiempo])
%   seleccionados: individuos elegidos, ordenados del mejor al peor.
%   indices:       posiciones de los elegidos dentro de poblacion.

    if numel(valores) ~= numel(poblacion)
        error('seleccion:tamanos', ...
            'valores y poblacion deben tener la misma cantidad de elementos.');
    end

    nSeleccionados = ceil(numel(poblacion) / 2);
    [~, orden] = sort(valores);
    indices = orden(1:nSeleccionados);
    seleccionados = poblacion(indices);
end
