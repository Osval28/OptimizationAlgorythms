function indices = seleccionTorneo(valores, tamanoGrupo)
% SELECCIONTORNEO  Torneos entre grupos aleatorios; ganan los mejores de cada grupo.
%   Cada individuo participa en un solo grupo (los grupos no repiten
%   individuos). De cada grupo pasa la mitad con menor valor: con grupos
%   de 4, pasan los 2 mejores.
%   valores:     vector con el valor a minimizar de cada individuo
%                (fila i de la matriz de poblacion <-> valores(i)).
%   tamanoGrupo: (opcional) individuos por grupo, numero par. Por defecto 4.
%   indices:     filas ganadoras. Uso: padres = poblacion(indices, :);

    if nargin < 2
        tamanoGrupo = 4;
    end
    if mod(tamanoGrupo, 2) ~= 0
        error('seleccion:grupoImpar', 'tamanoGrupo debe ser un numero par.');
    end

    n = numel(valores);
    mezcla = randperm(n);
    indices = [];

    for inicio = 1:tamanoGrupo:n
        grupo = mezcla(inicio : min(inicio + tamanoGrupo - 1, n));
        [~, posicionEnGrupo] = sort(valores(grupo));
        nGanadores = ceil(numel(grupo) / 2);
        indices = [indices, grupo(posicionEnGrupo(1:nGanadores))]; %#ok<AGROW>
    end
end
