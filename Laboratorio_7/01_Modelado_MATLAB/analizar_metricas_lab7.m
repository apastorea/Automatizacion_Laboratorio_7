% ANALIZAR_METRICAS_LAB7 - Comparacion reproducible de los cuatro casos.
% NOTA: Simulaciones NOMINALES solamente. NO son mediciones del PSoC.
% Requiere Control System Toolbox y las funciones de esta carpeta.
% Ejecutar desde MATLAB: analizar_metricas_lab7
clear; clc;
p = modelo_lab7();
d = disenar_lab7(p);

n = 2*numel(d.observadores);
caso = strings(n,1);
tiempo_escalon_ms = zeros(n,1);
salida_max_mV = zeros(n,1);
sobrepasamiento_pct = zeros(n,1);
tiempo_pico_ms = zeros(n,1);
establecimiento_2pct_ms = zeros(n,1);
convergencia_error_1e4_ms = zeros(n,1);
error_inicial_norma_V = zeros(n,1);
salida_pre_escalon_max_mV = zeros(n,1);
control_inicial_mV = zeros(n,1);
control_max_mV = zeros(n,1);
control_min_mV = zeros(n,1);
control_final_mV = zeros(n,1);
saturaciones = zeros(n,1);

fila = 0;
for i = 1:numel(d.observadores)
    for modo = {'prediccion','actual'}
        fila = fila + 1;
        s = simular_lab7(d,p,i,modo{1});
        caso(fila) = string([modo{1}, '_', d.observadores(i).nombre]);
        idx_escalon = find(abs(s.r_V) > 0, 1, 'first');
        assert(~isempty(idx_escalon), 'No se encontro el escalon.');
        referencia = s.r_V(idx_escalon);
        tramo = s.y_V(idx_escalon:end);
        [ymax, j] = max(tramo);

        tiempo_escalon_ms(fila) = 1000*s.t_s(idx_escalon);
        salida_max_mV(fila) = 1000*ymax;
        sobrepasamiento_pct(fila) = 100*(ymax/referencia-1);
        tiempo_pico_ms(fila) = 1000*(s.t_s(idx_escalon+j-1)-s.t_s(idx_escalon));

        % Tiempo de establecimiento: primera muestra tras la ULTIMA
        % salida fuera de la banda +/-2%, contado desde el escalon.
        fuera = find(abs(tramo-referencia) > 0.02*abs(referencia));
        if isempty(fuera)
            establecimiento_2pct_ms(fila) = 0;
        elseif fuera(end) == numel(tramo)
            establecimiento_2pct_ms(fila) = NaN; % No establecio en ventana
        else
            establecimiento_2pct_ms(fila) = 1000*p.Ts_s*fuera(end);
        end

        % La norma de error en estimador ACTUAL se mide DESPUES de
        % corregir con y[k]; en predictor, ANTES de la correccion.
        fuera_error = find(s.norma_error >= 1e-4);
        if isempty(fuera_error)
            convergencia_error_1e4_ms(fila) = 0;
        elseif fuera_error(end) == numel(s.norma_error)
            convergencia_error_1e4_ms(fila) = NaN;
        else
            convergencia_error_1e4_ms(fila) = 1000*p.Ts_s*fuera_error(end);
        end

        error_inicial_norma_V(fila) = s.norma_error(1);
        salida_pre_escalon_max_mV(fila) = 1000*max(abs(s.y_V(1:idx_escalon-1)));
        control_inicial_mV(fila) = 1000*s.u_V(1);
        control_max_mV(fila) = 1000*max(s.u_V);
        control_min_mV(fila) = 1000*min(s.u_V);
        control_final_mV(fila) = 1000*s.u_V(end);
        saturaciones(fila) = nnz(s.saturado);
    end
end

T = table(caso, tiempo_escalon_ms, salida_max_mV, ...
    sobrepasamiento_pct, tiempo_pico_ms, establecimiento_2pct_ms, ...
    convergencia_error_1e4_ms, error_inicial_norma_V, ...
    salida_pre_escalon_max_mV, control_inicial_mV, control_max_mV, ...
    control_min_mV, control_final_mV, saturaciones);
disp(T);

carpeta = fileparts(mfilename('fullpath'));
destino = fullfile(carpeta, '..', '05_Resultados');
if ~isfolder(destino), mkdir(destino); end
archivo = fullfile(destino, 'metricas_nominales_lab7.csv');
writetable(T, archivo);
fprintf('\nCSV generado: %s\n', archivo);
fprintf('Escalon real: %.0f ms (primer k con referencia positiva: %d, t=(k-1)*Ts).\n', ...
    tiempo_escalon_ms(1), round(tiempo_escalon_ms(1)/(1000*p.Ts_s))+1);
fprintf('ATENCION: Datos de SIMULACION NOMINAL, no experimentales.\n');
