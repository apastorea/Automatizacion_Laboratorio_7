function seleccion = seleccionar_polos_E1_identificado_lab7()
%SELECCIONAR_POLOS_E1_IDENTIFICADO_LAB7 Busca un E1 compatible con ADC/DAC.
%   Evalúa ubicaciones conjugadas sobre el modelo identificado. Primero
%   exige cero abortos con ruido medido; después prioriza tolerancia a un
%   impulso de dos cuentas ADC y, finalmente, rapidez de convergencia.

carpeta = fileparts(mfilename("fullpath"));
salidaDir = fullfile(carpeta,"..","05_Resultados", ...
    "Validacion_Integrada_20261124");
if ~isfolder(salidaDir)
    mkdir(salidaDir);
end

partesReales = 0.05:0.05:0.35;
partesImaginarias = 0.05:0.05:0.25;
n = numel(partesReales)*numel(partesImaginarias);
poloReal = zeros(n,1);
poloImag = zeros(n,1);
moduloPolo = zeros(n,1);
convergencia2pct_ms = zeros(n,1);
abortosOperativosE1 = zeros(n,1);
abortosEstresRuidoE1 = zeros(n,1);
uSolicitadaOperativaMax_mV = zeros(n,1);
uSolicitadaEstresMax_mV = zeros(n,1);
sensibilidadActual_mVPorADC = zeros(n,1);
fila = 0;
for realPolo = partesReales
    for imagPolo = partesImaginarias
        fila = fila+1;
        polos = [complex(realPolo,imagPolo),complex(realPolo,-imagPolo)];
        tabla = prevalidar_rediseno_identificado_lab7(PolosE1=polos, ...
            Guardar=false,ExigirOperativa=false,Mostrar=false);
        esE1 = ismember(tabla.caso,["Predictor E1","Actual E1"]);
        esOperativo = tabla.clase=="OPERATIVO" & esE1;
        esEstres = tabla.clase=="ESTRES_RUIDO" & esE1;
        abortosOperativosE1(fila) = nnz(tabla.aborto(esOperativo));
        abortosEstresRuidoE1(fila) = nnz(tabla.aborto(esEstres));
        uSolicitadaOperativaMax_mV(fila) = max( ...
            tabla.u_solicitada_max_mV(esOperativo),[],"omitmissing");
        uSolicitadaEstresMax_mV(fila) = max( ...
            tabla.u_solicitada_max_mV(esEstres),[],"omitmissing");

        p = modelo_lab7("identificado");
        p.polos_estimador{1} = polos;
        d = disenar_lab7(p,false);
        poloReal(fila) = realPolo;
        poloImag(fila) = imagPolo;
        moduloPolo(fila) = abs(polos(1));
        convergencia2pct_ms(fila) = 1000*p.Ts_s*ceil( ...
            log(0.02)/log(moduloPolo(fila)));
        sensibilidadActual_mVPorADC(fila) = 1000*abs( ...
            d.K*d.observadores(1).L_actual)*p.cuantizacion.adc_V;
    end
end

exploracion = table(poloReal,poloImag,moduloPolo,convergencia2pct_ms, ...
    abortosOperativosE1,abortosEstresRuidoE1, ...
    uSolicitadaOperativaMax_mV,uSolicitadaEstresMax_mV, ...
    sensibilidadActual_mVPorADC);
writetable(exploracion,fullfile(salidaDir, ...
    "seleccion_polos_E1_identificado.csv"));

% E1 debe conservar el papel de ubicación menos rápida que E2
% (|0.20+j0.10|), además de mantener margen respecto de +107 mV.
moduloE2 = abs(0.20+0.10i);
esSeguro = exploracion.abortosOperativosE1==0 & ...
    exploracion.uSolicitadaOperativaMax_mV<=100 & ...
    exploracion.moduloPolo>moduloE2;
candidatos = exploracion(esSeguro,:);
assert(~isempty(candidatos), ...
    "Ningún candidato E1 respetó el margen operativo de 100 mV.");
candidatos = sortrows(candidatos, ...
    ["abortosEstresRuidoE1" "convergencia2pct_ms" ...
    "uSolicitadaOperativaMax_mV"],"ascend");
seleccion = candidatos(1,:);
writetable(seleccion,fullfile(salidaDir, ...
    "polos_E1_identificados_seleccionados.csv"));

disp(exploracion);
fprintf("\nE1 seleccionado: %.2f +/- j%.2f; t_2%% = %.1f ms.\n", ...
    seleccion.poloReal,seleccion.poloImag,seleccion.convergencia2pct_ms);
fprintf("Abortos operativos E1: %d; abortos de estrés de ruido E1: %d.\n", ...
    seleccion.abortosOperativosE1,seleccion.abortosEstresRuidoE1);
end
