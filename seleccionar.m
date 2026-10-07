function indices = seleccionar(valores, metodo)
% SELECCIONAR  Llama al metodo de seleccion indicado por nombre.
%   metodo: 'elitismo' | 'torneo' | 'ruleta'. Comun a los 3 problemas.
%   indices: filas elegidas como padres. Uso: padres = poblacion(indices, :);
    switch lower(metodo)
        case 'elitismo'
            indices = seleccionElitismo(valores);
        case 'torneo'
            indices = seleccionTorneo(valores, 4);
        case 'ruleta'
            indices = seleccionRuleta(valores);
        otherwise
            error('seleccion:desconocida', 'Metodo de seleccion desconocido: %s', metodo);
    end
end
