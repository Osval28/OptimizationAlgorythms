% Optimizacion de inventarios (guia, seccion 3.1.3)
% Datos de la Tabla II. Valores monetarios en miles de COP.
datos.D     = [12000 80000 150000 50000 100000];  % ventas anuales de cada item
datos.m     = [20 220 900 120 180];               % valor promedio de cada pedido de un cliente
datos.mu    = [300 4000 7000 2000 3500];          % media de la demanda durante la reposicion
datos.sigma = [100 1200 2500 700 1100];           % desviacion estandar de esa demanda
datos.I     = 8000;                               % inversion promedio en inventario (ec. 9)
datos.maxS  = [200 1200 2500 800 1500];           % S_i en [0, maxS_i]
datos.maxK  = [500 2000 5000 1500 3000];          % K_i en [0, maxK_i]

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
        R = S(i) + K(i);   % nivel de stock que dispara el reabastecimiento
        densidad = @(x) exp(-0.5 * ((x - datos.mu(i)) / datos.sigma(i)).^2) ...
                        / (sqrt(2*pi) * datos.sigma(i));
        faltante = integral(@(x) (x - R) .* densidad(x), R, Inf);
        Z = Z + datos.D(i) / Q(i) * faltante / datos.m(i);
    end
end
