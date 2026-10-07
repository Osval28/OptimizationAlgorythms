function indices = seleccionRuleta(valores)
% SELECCIONRULETA  Ruleta con probabilidad inversamente proporcional al valor.
%   Se gira la ruleta tantas veces como la mitad de la poblacion. Un mismo
%   individuo puede salir mas de una vez (seleccion con reemplazo).
%   valores: vector con el valor a minimizar de cada individuo
%            (fila i de la matriz de poblacion <-> valores(i)).
%            Todos deben ser finitos y mayores que 0.
%   indices: filas elegidas. Uso: padres = poblacion(indices, :);

    if any(~isfinite(valores) | valores <= 0)
        error('seleccion:valoresNoPositivos', ...
            'La ruleta usa 1/valor: todos los valores deben ser finitos y mayores que 0.');
    end

    nSeleccionados = ceil(numel(valores) / 2);
    probabilidades = (1 ./ valores) / sum(1 ./ valores);
    acumulada = cumsum(probabilidades);
    acumulada(end) = 1;

    indices = zeros(1, nSeleccionados);
    for k = 1:nSeleccionados
        indices(k) = find(acumulada >= rand(), 1, 'first');
    end
end
