function resultados = prevalidar_rediseno_identificado_lab7(opciones)
%PREVALIDAR_REDISENO_IDENTIFICADO_LAB7 Evalúa el firmware identificado antes del banco.
%   Reproduce el pretrigger, la cuantización ADC/DAC y la parada abortiva
%   del firmware. Los escenarios operativos usan el ruido previo al escalón
%   medido en las cuatro campañas. Los escenarios de estrés no constituyen
%   condiciones autorizadas de operación ni sustituyen el ensayo físico.

arguments
    opciones.PolosE1 (1,2) double = [0.25+0.05i,0.25-0.05i]
    opciones.Guardar (1,1) logical = true
    opciones.ExigirOperativa (1,1) logical = true
    opciones.Mostrar (1,1) logical = true
end

carpeta = fileparts(mfilename("fullpath"));
raiz = fullfile(carpeta,"..");
datosDir = fullfile(raiz,"05_Resultados", ...
    "Lab7_Comparacion_Final_4_Observadores_20261124","datos_originales");
salidaDir = fullfile(raiz,"05_Resultados","Validacion_Integrada_20261124");
if ~isfolder(salidaDir)
    mkdir(salidaDir);
end

p = modelo_lab7("identificado");
p.polos_estimador{1} = opciones.PolosE1;
d = disenar_lab7(p,opciones.Mostrar);
[ruidosOperativos,resumenRuido] = cargarRuidoMedido(datosDir,p);
if opciones.Guardar
    writetable(resumenRuido,fullfile(salidaDir,"ruido_pretrigger_medido.csv"));
end

qAdc = p.cuantizacion.adc_V;
nMuestras = round(p.t_sim_s/p.Ts_s);
ruidosEstres = struct( ...
    nombre={"estres_impulso_mas_2_ADC","estres_impulso_menos_2_ADC"}, ...
    valores={crearImpulso(nMuestras,2*qAdc),crearImpulso(nMuestras,-2*qAdc)});

operativa = ejecutarEscenarios(d,p,ruidosOperativos,"OPERATIVO",[0;0]);
estresRuido = ejecutarEscenarios(d,p,ruidosEstres,"ESTRES_RUIDO",[0;0]);
estresEstado = ejecutarEscenarios(d,p, ...
    struct(nombre="estres_xhat_inicial",valores=zeros(nMuestras,1)), ...
    "ESTRES_ESTADO",[0.02;-0.01]);
resultados = [operativa;estresRuido;estresEstado];
if opciones.Guardar
    writetable(resultados,fullfile(salidaDir, ...
        "prevalidacion_rediseno_identificado.csv"));
end

esOperativo = resultados.clase=="OPERATIVO";
resumenCaso = groupsummary(resultados(esOperativo,:),"caso", ...
    ["sum" "max"],["aborto" "u_solicitada_max_mV" "u_aplicada_max_mV"]);
if opciones.Guardar
    writetable(resumenCaso,fullfile(salidaDir, ...
        "resumen_prevalidacion_operativa.csv"));
end

if opciones.Mostrar
    disp(resumenRuido);
    disp(resultados);
    disp(resumenCaso);
end
if opciones.ExigirOperativa && any(resultados.aborto(esOperativo))
    error("LAB7:PrevalidacionOperativa", ...
        "Al menos un escenario operativo abortó. No trasladar los coeficientes al firmware.");
end
if ~any(resultados.aborto(esOperativo)) && opciones.Mostrar
    fprintf("%s\n","Prevalidación operativa superada con el modelo " + ...
        "identificado. Los ensayos de estrés se informan por separado " + ...
        "y no autorizan el hardware.");
end
end
function [escenarios,resumen] = cargarRuidoMedido(datosDir,p)
claves = ["Pred_E1","Act_E1","Pred_E2","Act_E2"];
n = numel(claves);
escenarios = repmat(struct(nombre="",valores=[]),n+1,1);
captura = strings(n,1);
nPretrigger = zeros(n,1);
mediaCuentas = zeros(n,1);
minCuentas = zeros(n,1);
maxCuentas = zeros(n,1);
desvioCuentas = zeros(n,1);
maxDesviacion_mV = zeros(n,1);
nMuestras = round(p.t_sim_s/p.Ts_s);
for k = 1:n
    archivo = fullfile(datosDir,claves(k) + "_UART.csv");
    datos = readtable(archivo);
    pre = datos(datos.k<32,:);
    cuentas = double(pre.adc_counts);
    centradas = cuentas-mean(cuentas,"omitmissing");
    ruido = centradas*p.cuantizacion.adc_V;
    ruido = repmat(ruido,ceil(nMuestras/numel(ruido)),1);
    escenarios(k) = struct(nombre="medido_" + claves(k), ...
        valores=ruido(1:nMuestras));
    captura(k) = claves(k);
    nPretrigger(k) = height(pre);
    mediaCuentas(k) = mean(cuentas,"omitmissing");
    minCuentas(k) = min(cuentas,[],"omitmissing");
    maxCuentas(k) = max(cuentas,[],"omitmissing");
    desvioCuentas(k) = std(cuentas,0,"omitmissing");
    maxDesviacion_mV(k) = 1000*max(abs(centradas))*p.cuantizacion.adc_V;
end
alternante = p.cuantizacion.adc_V*repmat([-1;1],ceil(nMuestras/2),1);
escenarios(end) = struct(nombre="alternante_mas_menos_1_ADC", ...
    valores=alternante(1:nMuestras));
resumen = table(captura,nPretrigger,mediaCuentas,minCuentas,maxCuentas, ...
    desvioCuentas,maxDesviacion_mV);
end

function ruido = crearImpulso(nMuestras,amplitud)
ruido = zeros(nMuestras,1);
ruido(33) = amplitud;
end

function tabla = ejecutarEscenarios(d,p,escenarios,clase,xhatInicial)
casos = ["Predictor E1","Actual E1","Predictor E2","Actual E2"];
modos = ["prediccion","actual","prediccion","actual"];
indices = [1 1 2 2];
nFilas = numel(casos)*numel(escenarios);
claseCol = repmat(string(clase),nFilas,1);
caso = strings(nFilas,1);
escenario = strings(nFilas,1);
aborto = false(nFilas,1);
motivo = strings(nFilas,1);
muestraAborto = nan(nFilas,1);
uSolicitadaMax_mV = zeros(nFilas,1);
uAplicadaMax_mV = zeros(nFilas,1);
yMax_mV = zeros(nFilas,1);
errorFinal_mV = nan(nFilas,1);
fila = 0;
for i = 1:numel(casos)
    for j = 1:numel(escenarios)
        fila = fila+1;
        resultado = simularFirmware(d,p,indices(i),modos(i), ...
            escenarios(j).valores,xhatInicial);
        caso(fila) = casos(i);
        escenario(fila) = escenarios(j).nombre;
        aborto(fila) = resultado.aborto;
        motivo(fila) = resultado.motivo;
        muestraAborto(fila) = resultado.muestraAborto;
        uSolicitadaMax_mV(fila) = 1000*resultado.uSolicitadaMax;
        uAplicadaMax_mV(fila) = 1000*resultado.uAplicadaMax;
        yMax_mV(fila) = 1000*resultado.yMax;
        errorFinal_mV(fila) = 1000*resultado.errorFinal;
    end
end
tabla = table(claseCol,caso,escenario,aborto,motivo,muestraAborto, ...
    uSolicitadaMax_mV,uAplicadaMax_mV,yMax_mV,errorFinal_mV, ...
    VariableNames=["clase" "caso" "escenario" "aborto" "motivo" ...
    "muestra_aborto" "u_solicitada_max_mV" "u_aplicada_max_mV" ...
    "y_max_mV" "error_final_mV"]);
end

function resultado = simularFirmware(d,p,idx,modo,ruido,xhatInicial)
nMuestras = numel(ruido);
x = zeros(2,1);
xMem = xhatInicial(:);
pretrigger = zeros(32,1);
uSolicitadaMax = 0;
uAplicadaMax = 0;
yMax = 0;
errorFinal = NaN;
aborto = false;
motivo = "NINGUNO";
muestraAborto = NaN;
o = d.observadores(idx);
for k = 1:nMuestras
    y = d.C*x;
    yAdc = p.cuantizacion.adc_V*round( ...
        (y+ruido(k))/p.cuantizacion.adc_V);
    if k<=numel(pretrigger)
        pretrigger(k) = yAdc;
        xMem = xhatInicial(:);
        uAplicada = 0;
    else
        yRel = yAdc-mean(pretrigger,"omitmissing");
        innovacion = yRel-d.C*xMem;
        if modo=="actual"
            xUtilizado = xMem+o.L_actual*innovacion;
        else
            xUtilizado = xMem;
        end
        uSolicitada = d.Nr*p.referencia_V-d.K*xUtilizado;
        uSolicitadaMax = max(uSolicitadaMax,abs(uSolicitada));
        if ~isfinite(uSolicitada)
            aborto = true;
            motivo = "NO_FINITO";
        elseif abs(yRel)>0.5
            aborto = true;
            motivo = "SALIDA_FUERA_RANGO";
        elseif uSolicitada<p.u_min_V || uSolicitada>p.u_max_V
            aborto = true;
            motivo = "SATURACION_SOLICITADA";
        end
        if aborto
            muestraAborto = k-1;
            break;
        end
        uAplicada = cuantizarDAC(uSolicitada,p);
        uAplicadaMax = max(uAplicadaMax,abs(uAplicada));
        if modo=="actual"
            xMem = d.A*xUtilizado+d.B*uAplicada;
        else
            xMem = d.A*xUtilizado+d.B*uAplicada+o.L_pred*innovacion;
        end
        errorFinal = y-d.C*xUtilizado;
    end
    x = d.A*x+d.B*uAplicada;
    yMax = max(yMax,abs(y));
end
resultado = struct(aborto=aborto,motivo=motivo, ...
    muestraAborto=muestraAborto,uSolicitadaMax=uSolicitadaMax, ...
    uAplicadaMax=uAplicadaMax,yMax=yMax,errorFinal=errorFinal);
end

function u = cuantizarDAC(pedido,p)
if pedido>=0
    codigo = round(pedido/p.cuantizacion.dac_positivo_V);
    codigo = min(codigo,floor(p.u_max_V/p.cuantizacion.dac_positivo_V));
    u = codigo*p.cuantizacion.dac_positivo_V;
else
    codigo = round(-pedido/p.cuantizacion.dac_negativo_V);
    codigo = min(codigo,floor(-p.u_min_V/p.cuantizacion.dac_negativo_V));
    u = -codigo*p.cuantizacion.dac_negativo_V;
end
end
