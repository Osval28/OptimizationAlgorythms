function [hijo1, hijo2] = cruceOX(padre1, padre2, cortes)
% CRUCEOX  Cruce de orden (Order Crossover, OX) para individuos que son permutaciones.
%   [hijo1, hijo2] = cruceOX(padre1, padre2) elige dos puntos de corte al azar.
%   [hijo1, hijo2] = cruceOX(padre1, padre2, [a b]) usa el tramo a:b (util para probar).
%
%   hijo1: conserva el tramo a:b del padre 1; los huecos se llenan, de izquierda
%          a derecha, con las ciudades que faltan en el orden en que aparecen en
%          el padre 2.
%   hijo2: lo mismo con los papeles invertidos (tramo del padre 2, orden del padre 1).
%
%   Variante: los huecos se llenan de izquierda a derecha. En la version original
%   de Davis (1985) el llenado empieza justo despues del tramo y da la vuelta.
%
%   Referencia: L. Davis, "Applying adaptive algorithms to epistatic domains",
%   Proc. IJCAI, 1985, pp. 162-164.

    padre1 = padre1(:)';
    padre2 = padre2(:)';
    n = numel(padre1);

    if nargin < 3
        cortes = sort(randperm(n, 2));
    end
    a = cortes(1);
    b = cortes(2);

    hijo1 = construirHijo(padre1, padre2, a, b);
    hijo2 = construirHijo(padre2, padre1, a, b);
end

function hijo = construirHijo(base, otro, a, b)
    n = numel(base);
    hijo = zeros(1, n);
    tramo = base(a:b);
    hijo(a:b) = tramo;

    restantes = otro(~ismember(otro, tramo));
    huecos = [1:a-1, b+1:n];
    hijo(huecos) = restantes;
end
