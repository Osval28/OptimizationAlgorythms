% Datos de la Tabla II. Valores monetarios en miles de COP.
datos.D     = [12000 80000 150000 50000 100000];  % ventas anuales de cada item
datos.m     = [20 220 900 120 180];               % valor promedio de cada pedido de un cliente
datos.mu    = [300 4000 7000 2000 3500];          % media de la demanda durante la reposicion
datos.sigma = [100 1200 2500 700 1100];           % desviacion estandar de esa demanda
datos.I     = 8000;                               % inversion promedio en inventario (ec. 9)
datos.maxS  = [200 1200 2500 800 1500];           % S_i en [0, maxS_i]
datos.maxK  = [500 2000 5000 1500 3000];          % K_i en [0, maxK_i]
Q = [1000 2000 3000 1500 2500];
S = [100 600 1200 400 700];
K = [500 2000 5000 1500 3000];

calcularInventario(Q,S,K,datos)

function Z = calcularInventario(Q, S, K, datos)
% CALCULARINVENTARIO  Pedidos anuales no atendidos por falta de stock (ecuacion 8).
%   Q, S, K: vectores de 5 elementos: monto por pedido de reabastecimiento,
%            stock de seguridad y demanda definida por la empresa de cada item.
%   datos:   struct con los campos D, m, mu y sigma de la Tabla II.
%   La restriccion de la ecuacion 9 y los limites de S y K no se revisan
%   aqui: se deben garantizar al generar, cruzar y mutar los individuos.
    if any(Q <= 0)
        error('inventario:QNoPositivo', 'Todos los Q deben ser mayores que 0.');
    end

    Z = 0;
    
    for i = 1:numel(Q)
        Z = Z + datos.D(i)/Q(i) .* integral(@(x) f(x,S,K,i,datos) ,S(i)+K(i),inf);
    end

end

function resultado = f(x,S,K,i,datos)
    resultado = ((x-S(i)-K(i))/(datos.m(i).*sqrt(2*pi).*datos.sigma(i)).*exp(-0.5.*((x-datos.mu(i))/datos.sigma(i)).^2));
end


function [valido, motivo] = esValido(Q, S, K, datos, tolerancia)
% ESVALIDO  Verifica que un individuo del inventario cumpla las restricciones.
%   Q, S, K:    vectores de 5 elementos del individuo.
%   datos:      struct con I, maxS y maxK (y maxQ, si decides definirlo).
%   tolerancia: (opcional) diferencia maxima aceptada en la ecuacion 9.
%               Por defecto 1e-6.
%   valido:     true si cumple todo.
%   motivo:     texto con la primera restriccion que falla ('' si es valido).
    if nargin < 5
        tolerancia = 1e-6;
    end
    n = numel(datos.maxS);
    valido = false;
    Q = Q(:)'; S = S(:)'; K = K(:)';   % todos como fila, para comparar elemento a elemento

    if numel(Q) ~= n || numel(S) ~= n || numel(K) ~= n
        motivo = sprintf('Q, S y K deben tener %d elementos cada uno', n);
    elseif any(~isfinite([Q(:); S(:); K(:)]))
        motivo = 'contiene NaN o Inf';
    elseif any(Q <= 0)
        motivo = 'algun Q es menor o igual que 0';
    elseif isfield(datos, 'maxQ') && any(Q > datos.maxQ)
        motivo = 'algun Q supera maxQ';
    elseif any(S < 0 | S > datos.maxS)
        motivo = 'algun S esta fuera de [0, maxS]';
    elseif any(K < 0 | K > datos.maxK)
        motivo = 'algun K esta fuera de [0, maxK]';
    elseif abs(sum(Q/2 + S) - datos.I) > tolerancia
        motivo = sprintf('no cumple la ecuacion 9: sum(Q/2 + S) = %g y debe ser %g', ...
                         sum(Q/2 + S), datos.I);
    else
        valido = true;
        motivo = '';
    end
end
