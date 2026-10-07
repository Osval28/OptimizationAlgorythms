% Funcion Ackley modificada: minimo 3 - e en x = 0.
% Representacion: cada individuo es una fila con d numeros reales en
% [limites(1), limites(2)]; la poblacion es una matriz n x d y sus valores
% un vector columna n x 1.
clear; clc;

%% Parametros de la funcion
a = 20;
b = 0.2;
c = 2*pi;
limites = [-10 10];
optimo = 3 - exp(1);

%% Parametros del algoritmo
cfg.tamanoPoblacion = 100;        % multiplo de 4 (torneos de 4 y parejas)
cfg.iteraciones     = 100;
cfg.dimensiones     = 10;
cfg.seleccion       = 'elitismo'; % 'elitismo' | 'torneo' | 'ruleta'
cfg.alfa            = 0.5;        % extension del intervalo en BLX-alfa
cfg.pm              = 0.2;        % probabilidad de que un hijo mute
cfg.sigma           = 0.5;        % desviacion estandar de la mutacion
cfg.semilla         = 2026;       % cada prueba usa cfg.semilla + numero de prueba
cfg.limites         = limites;
cfg.constantes      = [a b c];
nPruebas            = 5;
metodosEstudio      = {'elitismo', 'torneo', 'ruleta'};
iteracionesEstudio  = [10 20 30 50 100 150 200];
pmEstudio           = [0 0.05 0.1 0.2 0.5 0.8];
sigmaEstudio        = [0.1 0.5 1];
dimensionesEstudio  = [2 3 10 20 50 100];
carpetaResultados   = fullfile(fileparts(mfilename('fullpath')), 'resultados');

%% Pruebas rapidas de las funciones
assert(abs(calcularAckley(zeros(1, 3), a, b, c) - optimo) < 1e-12);
assert(esValido(generarPoblacion(1, 5, limites), limites, 5));
[h1, h2] = cruceBLX(-10*ones(1, 4), 10*ones(1, 4), 0.5, limites);
assert(esValido(h1, limites, 4) && esValido(h2, limites, 4));
x = [1 2 3];
assert(isequal(mutacionAckley(x, 0, 0.5, limites), x));     % pm = 0 no cambia
assert(sum(mutacionAckley(x, 1, 0.5, limites) ~= x) <= 1);  % cambia 1 gen
disp('Pruebas de funciones: OK');

%% Calentamiento: la primera llamada incluye la compilacion de MATLAB (JIT)
% y saldria mas lenta; se descarta para no ensuciar los tiempos medidos.
algoritmoGenetico(cfg);
if ~exist(carpetaResultados, 'dir'), mkdir(carpetaResultados); end

%% Estudio 1: metodo de seleccion
tablaSeleccion = table();
for k = 1:numel(metodosEstudio)
    cf = cfg;
    cf.seleccion = metodosEstudio{k};
    [valores, tiempos, individuos] = correrPruebas(cf, nPruebas);
    tablaSeleccion = [tablaSeleccion; ...
        resumirPruebas(metodosEstudio{k}, valores, tiempos, individuos, optimo)]; %#ok<AGROW>
end
disp(tablaSeleccion);
writetable(tablaSeleccion, fullfile(carpetaResultados, 'ackley_seleccion.csv'));
[~, k] = min(tablaSeleccion.RMSE);           % criterio: menor RMSE
cfg.seleccion = metodosEstudio{k};
fprintf('Seleccion elegida: %s\n', cfg.seleccion);

%% Estudio 2: numero de iteraciones (con la seleccion elegida)
tablaIteraciones = table();
for k = 1:numel(iteracionesEstudio)
    cf = cfg;
    cf.iteraciones = iteracionesEstudio(k);
    [valores, tiempos, individuos] = correrPruebas(cf, nPruebas);
    tablaIteraciones = [tablaIteraciones; ...
        resumirPruebas(sprintf('%d iteraciones', cf.iteraciones), ...
                       valores, tiempos, individuos, optimo)]; %#ok<AGROW>
end
disp(tablaIteraciones);
writetable(tablaIteraciones, fullfile(carpetaResultados, 'ackley_iteraciones.csv'));
% Criterio: menor RMSE; si hay empate, min() toma el primero, que es la
% menor cantidad de iteraciones (la lista esta en orden creciente).
[~, k] = min(tablaIteraciones.RMSE);
cfg.iteraciones = iteracionesEstudio(k);
fprintf('Iteraciones elegidas: %d\n', cfg.iteraciones);

%% Estudio 3: mutacion (probabilidad pm y magnitud sigma)
% Con pm = 0 la magnitud no importa, asi que se corre una sola vez.
tablaMutacion = table();
combinaciones = zeros(0, 2);
historiales = {};
for p = pmEstudio
    sigmas = sigmaEstudio;
    if p == 0, sigmas = 0; end
    for s = sigmas
        cf = cfg;
        cf.pm = p;
        cf.sigma = s;
        [valores, tiempos, individuos, historiales{end + 1}] = correrPruebas(cf, nPruebas); %#ok<SAGROW>
        tablaMutacion = [tablaMutacion; ...
            resumirPruebas(sprintf('Pm = %.2f, sigma = %.2f', p, s), ...
                           valores, tiempos, individuos, optimo)]; %#ok<AGROW>
        combinaciones(end + 1, :) = [p s]; %#ok<AGROW>
    end
end
disp(tablaMutacion);
writetable(tablaMutacion, fullfile(carpetaResultados, 'ackley_mutacion.csv'));
[~, k] = min(tablaMutacion.RMSE);
cfg.pm = combinaciones(k, 1);
cfg.sigma = combinaciones(k, 2);
fprintf('Mutacion elegida: Pm = %.2f, sigma = %.2f\n', cfg.pm, cfg.sigma);

figure('Name', 'Ackley: convergencia');
semilogy(1:cfg.iteraciones, mean(historiales{k}, 2) - optimo, 'LineWidth', 1.5);
xlabel('Generacion'); ylabel('Mejor valor encontrado - (3 - e)'); grid on;
title(sprintf('Ackley, d = %d: %s, Pm = %.2f, sigma = %.2f, promedio de %d pruebas', ...
              cfg.dimensiones, cfg.seleccion, cfg.pm, cfg.sigma, nPruebas));
saveas(gcf, fullfile(carpetaResultados, 'ackley_convergencia.png'));

%% Estudio 4: numero de dimensiones (configuracion elegida)
tablaDimensiones = table();
for k = 1:numel(dimensionesEstudio)
    cf = cfg;
    cf.dimensiones = dimensionesEstudio(k);
    [valores, tiempos, individuos] = correrPruebas(cf, nPruebas);
    tablaDimensiones = [tablaDimensiones; ...
        resumirPruebas(sprintf('d = %d', cf.dimensiones), ...
                       valores, tiempos, individuos, optimo)]; %#ok<AGROW>
end
disp(tablaDimensiones);
writetable(tablaDimensiones, fullfile(carpetaResultados, 'ackley_dimensiones.csv'));

figure('Name', 'Ackley: dimensiones');
plot(dimensionesEstudio, tablaDimensiones.RMSE, '-o', 'LineWidth', 1.5);
xlabel('Dimensiones d'); ylabel('RMSE'); grid on;
title(sprintf('Ackley: RMSE contra dimensiones (%d pruebas por punto)', nPruebas));
saveas(gcf, fullfile(carpetaResultados, 'ackley_dimensiones.png'));


%% ===================== FUNCIONES DEL PROBLEMA =====================

function resultado = algoritmoGenetico(cfg)
% ALGORITMOGENETICO  Una ejecucion completa del AG para la funcion Ackley.
%   cfg: parametros (tamanoPoblacion, iteraciones, dimensiones, seleccion,
%        alfa, pm, sigma, limites, constantes).
%   resultado.mejorValor:     mejor valor encontrado en toda la ejecucion.
%   resultado.mejorIndividuo: punto que lo produjo.
%   resultado.historial:      mejor valor acumulado al final de cada generacion.
    assert(mod(cfg.tamanoPoblacion, 4) == 0, 'tamanoPoblacion debe ser multiplo de 4.');

    poblacion = generarPoblacion(cfg.tamanoPoblacion, cfg.dimensiones, cfg.limites);
    valores = evaluarPoblacion(poblacion, cfg.constantes);
    [mejorValor, j] = min(valores);
    mejorIndividuo = poblacion(j, :);
    historial = zeros(cfg.iteraciones, 1);

    for iter = 1:cfg.iteraciones
        % 1. Seleccion: mitad de la poblacion como padres
        indices = seleccionar(valores, cfg.seleccion);
        indices = indices(randperm(numel(indices)));   % barajar las parejas
        padres = poblacion(indices, :);
        valoresPadres = valores(indices);

        % 2. Cruce BLX-alfa por parejas (1-2, 3-4, ...) y 3. mutacion de cada hijo
        hijos = zeros(size(padres));
        for k = 1:2:size(padres, 1)
            [h1, h2] = cruceBLX(padres(k, :), padres(k + 1, :), cfg.alfa, cfg.limites);
            hijos(k, :)     = mutacionAckley(h1, cfg.pm, cfg.sigma, cfg.limites);
            hijos(k + 1, :) = mutacionAckley(h2, cfg.pm, cfg.sigma, cfg.limites);
        end

        % 4. Nueva poblacion: padres + hijos. Solo se evaluan los hijos.
        poblacion = [padres; hijos];
        valores = [valoresPadres(:); evaluarPoblacion(hijos, cfg.constantes)];

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

function [valores, tiempos, individuos, historiales] = correrPruebas(cfg, nPruebas)
% CORRERPRUEBAS  Ejecuta el AG nPruebas veces con la misma configuracion.
%   Cada prueba usa la semilla cfg.semilla + prueba: todas las configuraciones
%   con la misma dimension arrancan con las mismas poblaciones iniciales.
    valores = zeros(nPruebas, 1);
    tiempos = zeros(nPruebas, 1);
    individuos = zeros(nPruebas, cfg.dimensiones);
    historiales = zeros(cfg.iteraciones, nPruebas);
    for prueba = 1:nPruebas
        rng(cfg.semilla + prueba);
        reloj = tic;
        resultado = algoritmoGenetico(cfg);
        tiempos(prueba) = toc(reloj);
        valores(prueba) = resultado.mejorValor;
        individuos(prueba, :) = resultado.mejorIndividuo;
        historiales(:, prueba) = resultado.historial;
    end
end

function poblacion = generarPoblacion(n, d, limites)
% GENERARPOBLACION  Matriz n x d con valores uniformes en [limites(1), limites(2)].
%   rand(n, d) da numeros en [0, 1]; se escalan al ancho del intervalo y se
%   desplazan al limite inferior.
    poblacion = limites(1) + (limites(2) - limites(1)) * rand(n, d);
end

function valores = evaluarPoblacion(poblacion, constantes)
% EVALUARPOBLACION  Valor de Ackley de cada fila de la poblacion (vector columna).
    valores = zeros(size(poblacion, 1), 1);
    for i = 1:size(poblacion, 1)
        valores(i) = calcularAckley(poblacion(i, :), ...
                                    constantes(1), constantes(2), constantes(3));
    end
end

function valor = calcularAckley(x, a, b, c)
% CALCULARACKLEY  Evalua la funcion Ackley modificada.
%   x:       vector fila con un punto de d dimensiones (un individuo).
%   a, b, c: constantes de la funcion (normalmente 20, 0.2 y 2*pi).
%   El minimo es 3 - e y se alcanza en x = 0.
    d = numel(x);
    terminoRaiz = -a * exp(-b * sqrt(sum(x.^2) / d));
    terminoCoseno = -exp(sum(cos(c * x)) / d);
    valor = terminoRaiz + terminoCoseno + a + 3;
end

function [valido, motivo] = esValido(x, limites, d)
% ESVALIDO  Verifica que un individuo de Ackley cumpla las restricciones.
%   x:       individuo (vector de numeros reales).
%   limites: [minimo maximo] permitido para cada x_i.
%   d:       (opcional) numero de dimensiones esperado.
%   valido:  true si cumple todo.
%   motivo:  texto con la primera restriccion que falla ('' si es valido).
    valido = false;
    if ~isnumeric(x) || ~isreal(x) || ~isvector(x)
        motivo = 'no es un vector de numeros reales';
    elseif nargin >= 3 && numel(x) ~= d
        motivo = sprintf('tiene %d dimensiones y se esperaban %d', numel(x), d);
    elseif any(~isfinite(x))
        motivo = 'contiene NaN o Inf';
    elseif any(x < limites(1) | x > limites(2))
        motivo = sprintf('tiene valores fuera de [%g, %g]', limites(1), limites(2));
    else
        valido = true;
        motivo = '';
    end
end

function [hijo1, hijo2] = cruceBLX(padre1, padre2, alfa, limites)
% CRUCEBLX  Cruce BLX-alfa (blend crossover) para individuos reales.
%   Para cada gen i se toma el intervalo entre los dos padres,
%   [min(p1_i, p2_i), max(p1_i, p2_i)], de ancho I_i; se extiende alfa*I_i
%   hacia cada lado y cada hijo toma un valor uniforme dentro de ese
%   intervalo extendido. Cada gen se sortea por separado.
%   Los valores que se salen del dominio se recortan a los limites.
%
%   Referencia: L. J. Eshelman y J. D. Schaffer, "Real-coded genetic
%   algorithms and interval-schemata", Foundations of Genetic Algorithms 2,
%   1993, pp. 187-202.
    minimo = min(padre1, padre2);         % min gen por gen
    ancho = abs(padre1 - padre2);         % I_i de cada gen
    inferior = minimo - alfa * ancho;
    rango = (1 + 2 * alfa) * ancho;       % ancho del intervalo extendido

    hijo1 = inferior + rango .* rand(size(padre1));
    hijo2 = inferior + rango .* rand(size(padre1));

    hijo1 = min(max(hijo1, limites(1)), limites(2));
    hijo2 = min(max(hijo2, limites(1)), limites(2));
end

function x = mutacionAckley(x, pm, sigma, limites)
% MUTACIONACKLEY  Con probabilidad pm suma ruido normal a un gen al azar.
%   x_j' = x_j + r,  r ~ N(0, sigma^2). randn da N(0, 1); al multiplicarlo
%   por sigma queda con desviacion estandar sigma. El resultado se recorta
%   a los limites del dominio.
    if rand() < pm
        j = randi(numel(x));
        x(j) = x(j) + sigma * randn();
        x(j) = min(max(x(j), limites(1)), limites(2));
    end
end
