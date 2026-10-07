function indices = seleccionElitismo(valores)
% SELECCIONELITISMO  Selecciona la mitad de la poblacion con menor valor.
%   valores: vector con el valor a minimizar de cada individuo (fila i de
%            la matriz de poblacion <-> valores(i)).
%   indices: filas elegidas, ordenadas del mejor al peor.
%            Uso: padres = poblacion(indices, :);

    nSeleccionados = ceil(numel(valores) / 2);
    [~, orden] = sort(valores);
    indices = orden(1:nSeleccionados);
end
