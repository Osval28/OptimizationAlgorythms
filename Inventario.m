% Optimizacion de inventarios: minimizar Z, los pedidos anuales no
% atendidos por falta de stock, para 5 articulos.
% Representacion: cada individuo es una fila de 14 variables independientes
%   x = [Q1 Q2 Q3 Q4 | S1 S2 S3 S4 S5 | K1 K2 K3 K4 K5]
% y Q5 se calcula con la restriccion de presupuesto sum(Q/2 + S) = I.
% La poblacion es una matriz n x 14 y sus valores un vector columna n x 1.
% Valores monetarios en miles de COP.
clear; clc;

%% Datos del problema
datos.D     = [12000 80000 150000 50000 100000];  % ventas anuales de cada item
datos.m     = [20 220 900 120 180];               % valor promedio de cada pedido de un cliente
datos.mu    = [300 4000 7000 2000 3500];          % media de la demanda durante la reposicion
datos.sigma = [100 1200 2500 700 1100];           % desviacion estandar de esa demanda
datos.I     = 8000;                               % inversion promedio en inventario
datos.maxS  = [200 1200 2500 800 1500];           % S_i en [0, maxS_i]
datos.maxK  = [500 2000 5000 1500 3000];          % K_i en [0, maxK_i]
datos.minQ  = 1;                                  % Q_i > 0: piso numerico
datos.maxQ  = 2 * datos.I;                        % Q_i/2 no puede superar I

%% Parametros del algoritmo
cfg.tamanoPoblacion = 100;        % multiplo de 4 (torneos de 4 y parejas)
cfg.iteraciones     = 100;
cfg.seleccion       = 'elitismo'; % 'elitismo' | 'torneo' | 'ruleta'
cfg.pm              = 0.2;        % probabilidad de que un hijo mute
cfg.magnitud        = 0.1;        % desviacion de la mutacion como fraccion del rango
cfg.semilla         = 2026;       % cada prueba usa cfg.semilla + numero de prueba
nPruebas            = 5;
metodosEstudio      = {'elitismo', 'torneo', 'ruleta'};
iteracionesEstudio  = [10 20 30 50 100 150 200];
pmEstudio           = [0 0.05 0.1 0.2 0.5 0.8];
magnitudEstudio     = [0.01 0.05 0.1 0.2];
carpetaResultados   = fullfile(fileparts(mfilename('fullpath')), 'resultados');

%% Pruebas rapidas de las funciones
Q = [1000 2000 3000 1500 2500];
S = [100 600 1200 400 700];
K = [500 2000 5000 1500 3000];
assert(abs(calcularInventario(Q, S, K, datos) - 517.269) < 1e-3);
x = [Q(1:4), S, K];
[Qd, Sd, Kd] = decodificar(x, datos);
assert(abs(Qd(5) - 2500) < 1e-9 && isequal(Sd, S) && isequal(Kd, K));
P = generarPoblacion(50, datos);
for i = 1:size(P, 1)
    [Qd, Sd, Kd] = decodificar(P(i, :), datos);
    assert(esValido(Qd, Sd, Kd, datos));
end
for i = 1:2:size(P, 1)
    [h1, h2] = cruceAritmetico(P(i, :), P(i + 1, :));
    m1 = mutacionInventario(h1, 1, 0.5, datos);
    [Qd, Sd, Kd] = decodificar(h1, datos); assert(esValido(Qd, Sd, Kd, datos));
    [Qd, Sd, Kd] = decodificar(h2, datos); assert(esValido(Qd, Sd, Kd, datos));
    [Qd, Sd, Kd] = decodificar(m1, datos); assert(esValido(Qd, Sd, Kd, datos));
end
disp('Pruebas de funciones: OK');

%% Calentamiento: la primera llamada incluye la compilacion de MATLAB (JIT)
% y saldria mas lenta; se descarta para no ensuciar los tiempos medidos.
cfgCalentamiento = cfg;
cfgCalentamiento.iteraciones = 5;
algoritmoGenetico(cfgCalentamiento, datos);
if ~exist(carpetaResultados, 'dir'), mkdir(carpetaResultados); end

%% Estudio 1: metodo de seleccion
tablaSeleccion = table();
for k = 1:numel(metodosEstudio)
    cf = cfg;
    cf.seleccion = metodosEstudio{k};
    [valores, tiempos, individuos] = correrPruebas(cf, datos, nPruebas);
    tablaSeleccion = [tablaSeleccion; ...
        resumirPruebas(metodosEstudio{k}, valores, tiempos, individuos)]; %#ok<AGROW>
end
disp(tablaSeleccion);
writetable(tablaSeleccion, fullfile(carpetaResultados, 'inventario_seleccion.csv'));
[~, k] = min(tablaSeleccion.Media);          % criterio: menor promedio
cfg.seleccion = metodosEstudio{k};
fprintf('Seleccion elegida: %s\n', cfg.seleccion);

%% Estudio 2: numero de iteraciones (con la seleccion elegida)
tablaIteraciones = table();
for k = 1:numel(iteracionesEstudio)
    cf = cfg;
    cf.iteraciones = iteracionesEstudio(k);
    [valores, tiempos, individuos] = correrPruebas(cf, datos, nPruebas);
    tablaIteraciones = [tablaIteraciones; ...
        resumirPruebas(sprintf('%d iteraciones', cf.iteraciones), ...
                       valores, tiempos, individuos)]; %#ok<AGROW>
end
disp(tablaIteraciones);
writetable(tablaIteraciones, fullfile(carpetaResultados, 'inventario_iteraciones.csv'));
% Criterio: menor promedio; si hay empate, min() toma el primero, que es
% la menor cantidad de iteraciones (la lista esta en orden creciente).
[~, k] = min(tablaIteraciones.Media);
cfg.iteraciones = iteracionesEstudio(k);
fprintf('Iteraciones elegidas: %d\n', cfg.iteraciones);

%% Estudio 3: mutacion (probabilidad pm y magnitud)
% Con pm = 0 la magnitud no importa, asi que se corre una sola vez.
tablaMutacion = table();
combinaciones = zeros(0, 2);
historiales = {};
individuosMutacion = {};
valoresMutacion = {};
for p = pmEstudio
    magnitudes = magnitudEstudio;
    if p == 0, magnitudes = 0; end
    for mg = magnitudes
        cf = cfg;
        cf.pm = p;
        cf.magnitud = mg;
        [valores, tiempos, individuos, historiales{end + 1}] = correrPruebas(cf, datos, nPruebas); %#ok<SAGROW>
        valoresMutacion{end + 1} = valores; %#ok<SAGROW>
        individuosMutacion{end + 1} = individuos; %#ok<SAGROW>
        tablaMutacion = [tablaMutacion; ...
            resumirPruebas(sprintf('Pm = %.2f, magnitud = %.2f', p, mg), ...
                           valores, tiempos, individuos)]; %#ok<AGROW>
        combinaciones(end + 1, :) = [p mg]; %#ok<AGROW>
    end
end
disp(tablaMutacion);
writetable(tablaMutacion, fullfile(carpetaResultados, 'inventario_mutacion.csv'));
[~, k] = min(tablaMutacion.Media);
cfg.pm = combinaciones(k, 1);
cfg.magnitud = combinaciones(k, 2);
fprintf('Mutacion elegida: Pm = %.2f, magnitud = %.2f\n', cfg.pm, cfg.magnitud);

%% Mejor solucion y grafica de convergencia de la configuracion final
[~, mejorPrueba] = min(valoresMutacion{k});
[Qf, Sf, Kf] = decodificar(individuosMutacion{k}(mejorPrueba, :), datos);
fprintf('\nMejor solucion de la configuracion final (miles de COP):\n');
disp(array2table([Qf; Sf; Kf], 'RowNames', {'Q', 'S', 'K'}, ...
     'VariableNames', {'Item1', 'Item2', 'Item3', 'Item4', 'Item5'}));
fprintf('Presupuesto sum(Q/2 + S) = %.6f\n', sum(Qf/2 + Sf));

figure('Name', 'Inventario: convergencia');
plot(1:cfg.iteraciones, mean(historiales{k}, 2), 'LineWidth', 1.5);
xlabel('Generacion'); ylabel('Mejor Z encontrado'); grid on;
title(sprintf('Inventario: %s, Pm = %.2f, magnitud = %.2f, promedio de %d pruebas', ...
              cfg.seleccion, cfg.pm, cfg.magnitud, nPruebas));
saveas(gcf, fullfile(carpetaResultados, 'inventario_convergencia.png'));


%% ===================== FUNCIONES DEL PROBLEMA =====================

function resultado = algoritmoGenetico(cfg, datos)
% ALGORITMOGENETICO  Una ejecucion completa del AG para el inventario.
%   cfg: parametros (tamanoPoblacion, iteraciones, seleccion, pm, magnitud).
%   resultado.mejorValor:     menor Z encontrado en toda la ejecucion.
%   resultado.mejorIndividuo: vector de 14 variables que lo produjo.
%   resultado.historial:      mejor Z acumulado al final de cada generacion.
    assert(mod(cfg.tamanoPoblacion, 4) == 0, 'tamanoPoblacion debe ser multiplo de 4.');

    poblacion = generarPoblacion(cfg.tamanoPoblacion, datos);
    valores = evaluarPoblacion(poblacion, datos);
    [mejorValor, j] = min(valores);
    mejorIndividuo = poblacion(j, :);
    historial = zeros(cfg.iteraciones, 1);

    for iter = 1:cfg.iteraciones
        % 1. Seleccion: mitad de la poblacion como padres
        indices = seleccionar(valores, cfg.seleccion);
        indices = indices(randperm(numel(indices)));   % barajar las parejas
        padres = poblacion(indices, :);
        valoresPadres = valores(indices);

        % 2. Cruce aritmetico por parejas (1-2, 3-4, ...) y 3. mutacion
        hijos = zeros(size(padres));
        for k = 1:2:size(padres, 1)
            [h1, h2] = cruceAritmetico(padres(k, :), padres(k + 1, :));
            hijos(k, :)     = mutacionInventario(h1, cfg.pm, cfg.magnitud, datos);
            hijos(k + 1, :) = mutacionInventario(h2, cfg.pm, cfg.magnitud, datos);
        end

        % 4. Nueva poblacion: padres + hijos. Solo se evaluan los hijos.
        poblacion = [padres; hijos];
        valores = [valoresPadres(:); evaluarPoblacion(hijos, datos)];

        % 5. Mejor historico (con ruleta el mejor puede no ser elegido)
        [mejorGeneracion, j] = min(valores);
        if mejorGeneracion < mejorValor
            mejorValor = mejorGeneracion;
            mejorIndividuo = poblacion(j, :);
        end
        historial(iter) = mejorValor;
    end

    resultado.mejorValor = mejorValor;
    resultado.mejorIndividuo = mejorIndividuo;
    resultado.historial = historial;
end

function [valores, tiempos, individuos, historiales] = correrPruebas(cfg, datos, nPruebas)
% CORRERPRUEBAS  Ejecuta el AG nPruebas veces con la misma configuracion.
%   Cada prueba usa la semilla cfg.semilla + prueba: todas las configuraciones
%   arrancan con las mismas poblaciones iniciales y la comparacion es justa.
    valores = zeros(nPruebas, 1);
    tiempos = zeros(nPruebas, 1);
    individuos = zeros(nPruebas, 14);
    historiales = zeros(cfg.iteraciones, nPruebas);
    for prueba = 1:nPruebas
        rng(cfg.semilla + prueba);
        reloj = tic;
        resultado = algoritmoGenetico(cfg, datos);
        tiempos(prueba) = toc(reloj);
        valores(prueba) = resultado.mejorValor;
        individuos(prueba, :) = resultado.mejorIndividuo;
        historiales(:, prueba) = resultado.historial;
    end
end

function poblacion = generarPoblacion(n, datos)
% GENERARPOBLACION  n individuos factibles de 14 variables, uno por fila.
%   S y K se sortean uniformes dentro de sus limites. El presupuesto que
%   queda para los Q es sum(Q) = 2*(I - sum(S)); se reparte entre los 5
%   articulos con pesos aleatorios, de modo que Q5 queda positivo.
    poblacion = zeros(n, 14);
    for i = 1:n
        S = rand(1, 5) .* datos.maxS;
        K = rand(1, 5) .* datos.maxK;
        disponible = 2 * (datos.I - sum(S));
        pesos = rand(1, 5);
        Q = datos.minQ + (disponible - 5 * datos.minQ) * pesos / sum(pesos);
        poblacion(i, :) = [Q(1:4), S, K];
    end
end

function [Q, S, K] = decodificar(x, datos)
% DECODIFICAR  Separa el individuo en Q, S y K y calcula Q5.
%   x: [Q1 Q2 Q3 Q4 S1..S5 K1..K5].
%   Q5 sale de sum(Q/2 + S) = I  =>  Q5 = 2*(I - sum(S)) - (Q1+Q2+Q3+Q4).
    S = x(5:9);
    K = x(10:14);
    Q = [x(1:4), calcularQ5(x, datos)];
end

function q5 = calcularQ5(x, datos)
    q5 = 2 * (datos.I - sum(x(5:9))) - sum(x(1:4));
end

function valores = evaluarPoblacion(poblacion, datos)
% EVALUARPOBLACION  Z de cada fila de la poblacion (vector columna).
    valores = zeros(size(poblacion, 1), 1);
    for i = 1:size(poblacion, 1)
        [Q, S, K] = decodificar(poblacion(i, :), datos);
        valores(i) = calcularInventario(Q, S, K, datos);
    end
end

function Z = calcularInventario(Q, S, K, datos)
% CALCULARINVENTARIO  Pedidos anuales no atendidos por falta de stock.
%   Q, S, K: vectores de 5 elementos: monto por pedido de reabastecimiento,
%            stock de seguridad y demanda definida por la empresa de cada item.
%   datos:   struct con los campos D, m, mu y sigma.
%   La restriccion de presupuesto y los limites de S y K no se revisan
%   aqui: se garantizan al generar, cruzar y mutar los individuos.
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
%   datos:      struct con I, maxS, maxK y maxQ.
%   tolerancia: (opcional) diferencia maxima aceptada en el presupuesto.
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
        motivo = sprintf('no cumple el presupuesto: sum(Q/2 + S) = %g y debe ser %g', ...
                         sum(Q/2 + S), datos.I);
    else
        valido = true;
        motivo = '';
    end
end

function [hijo1, hijo2] = cruceAritmetico(padre1, padre2)
% CRUCEARITMETICO  Combinacion convexa de los dos padres.
%   hijo1 = a*padre1 + (1-a)*padre2,  hijo2 = (1-a)*padre1 + a*padre2,
%   con a ~ U(0, 1) igual para todos los genes. Los hijos quedan en el
%   segmento que une a los padres: si ambos cumplen el presupuesto y los
%   limites, los hijos tambien, porque Q5 y el presupuesto son lineales.
%
%   Referencia: Z. Michalewicz, Genetic Algorithms + Data Structures =
%   Evolution Programs, 3.a ed. Berlin: Springer, 1996.
    a = rand();
    hijo1 = a * padre1 + (1 - a) * padre2;
    hijo2 = (1 - a) * padre1 + a * padre2;
end

function x = mutacionInventario(x, pm, magnitud, datos)
% MUTACIONINVENTARIO  Con probabilidad pm suma ruido normal a una variable.
%   La desviacion es magnitud*(rango de esa variable), porque Q, S y K
%   tienen escalas distintas. Luego:
%   1. Se recorta la variable a sus limites [inferior, superior].
%   2. Se recalcula Q5. Si quedo por debajo de minQ, la variable mutada se
%      devuelve lo justo para que Q5 = minQ: subir Q_j en 1 baja Q5 en 1,
%      y subir S_j en 1 baja Q5 en 2. K no aparece en el presupuesto.
    if rand() < pm
        inferior = [repmat(datos.minQ, 1, 4), zeros(1, 5), zeros(1, 5)];
        superior = [repmat(datos.maxQ, 1, 4), datos.maxS, datos.maxK];
        j = randi(14);
        x(j) = x(j) + magnitud * (superior(j) - inferior(j)) * randn();
        x(j) = min(max(x(j), inferior(j)), superior(j));

        deficit = datos.minQ - calcularQ5(x, datos);
        if deficit > 0
            if j <= 4
                x(j) = x(j) - deficit;
            elseif j <= 9
                x(j) = x(j) - deficit / 2;
            end
        end
    end
end
