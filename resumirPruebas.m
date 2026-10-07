function fila = resumirPruebas(etiqueta, valores, tiempos, individuos, optimo)
% RESUMIRPRUEBAS  Una fila de tabla con las estadisticas de nPruebas corridas.
%   etiqueta:   texto que identifica la configuracion (p. ej. 'torneo').
%   valores:    mejor valor de cada prueba (nPruebas x 1).
%   tiempos:    tiempo de cada prueba en segundos (nPruebas x 1).
%   individuos: mejor individuo de cada prueba, uno por fila.
    valores = valores(:);
    tiempos = tiempos(:);
    [mejor, j] = min(valores);
    fila = table(string(etiqueta), mean(tiempos), mejor, mean(valores), ...
                 std(valores), string(mat2str(individuos(j, :), 8)), ...
                 'VariableNames', {'Configuracion', 'TiempoMedio_s', ...
                 'MejorValor', 'Media', 'DesviacionEstandar', 'MejorIndividuo'});
    if nargin >= 5 && ~isempty(optimo)
        fila.RMSE = sqrt(mean((valores - optimo).^2));
    end
end
