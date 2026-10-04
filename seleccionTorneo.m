function [seleccionados, indices] = seleccionTorneo(poblacion, valores, tamanoGrupo)
% SELECCIONTORNEO  Torneos entre grupos aleatorios; ganan los mejores de cada grupo.
%   Cada individuo participa en un solo grupo (los grupos no se repiten
%   individuos). De cada grupo pasa la mitad con menor valor: con grupos
%   de 4, pasan los 2 mejores.
%   poblacion:   arreglo de structs, un individuo por elemento.
%   valores:     valor a minimizar de cada individuo, mismo orden que poblacion.
%   tamanoGrupo: (opcional) individuos por grupo, numero par. Por defecto 4.
%   seleccionados: individuos ganadores.
%   indices:       posiciones de los ganadores dentro de poblacion.

    if nargin < 3
        tamanoGrupo = 4;
    end
    if numel(valores) ~= numel(poblacion)
        error('seleccion:tamanos', ...
            'valores y poblacion deben tener la misma cantidad de elementos.');
    end
    if mod(tamanoGrupo, 2) ~= 0
        error('seleccion:grupoImpar', 'tamanoGrupo debe ser un numero par.');
    end

    n = numel(poblacion);
    mezcla = randperm(n);
    indices = [];

    for inicio = 1:tamanoGrupo:n
        grupo = mezcla(inicio : min(inicio + tamanoGrupo - 1, n));
        [~, posicionEnGrupo] = sort(valores(grupo));
        nGanadores = ceil(numel(grupo) / 2);
        indices = [indices, grupo(posicionEnGrupo(1:nGanadores))]; %#ok<AGROW>
    end

    seleccionados = poblacion(indices);
end
