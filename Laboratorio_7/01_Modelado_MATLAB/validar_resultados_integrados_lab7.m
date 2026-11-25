% VALIDAR_RESULTADOS_INTEGRADOS_LAB7
% Integra la campaña fisica identificada del 24-11-2026:
% 1) diseño calculado directamente con el modelo identificado;
% 2) simulacion ideal y no ideal con cuantizacion ADC/DAC;
% 3) comparacion con UART y tensiones fisicas J5/J7 del Rigol;
% 4) estados estimados, error observable y resolucion del actuador;
% 5) convergencia teorica, esfuerzo RMS, ruido estacionario y margen temporal.
clear; clc; close all;

carpeta = fileparts(mfilename("fullpath"));
raiz = fullfile(carpeta,"..");
capturasDir = fullfile(raiz,"04_Ensayos","Capturas_Sincronizadas");
salidaDir = fullfile(raiz,"05_Resultados","Validacion_Integrada_20261124");
figurasDir = fullfile(salidaDir,"figuras");
if ~isfolder(figurasDir), mkdir(figurasDir); end

casos = ["Predictor E1";"Actual E1";"Predictor E2";"Actual E2"];
modos = ["prediccion";"actual";"prediccion";"actual"];
indices = [1;1;2;2];
carpetas = [ ...
    "20261124_221144_972_pred_E1_identificado"; ...
    "20261124_221418_036_actual_E1_identificado"; ...
    "20261124_221547_931_pred_E2_identificado"; ...
    "20261124_221705_548_actual_E2_identificado"];

pId = modelo_lab7("identificado");
dId = disenar_lab7(pId,false);

experimental = cell(4,1);
calculado = cell(4,1);
simulado = cell(4,1);
rigol = repmat(struct(deltaJ5_V=0,deltaJ7_V=0,J5_inicial_V=0, ...
    J5_final_V=0,J7_inicial_V=0,J7_final_V=0),4,1);
for k = 1:4
    carpetaCaso = fullfile(capturasDir,carpetas(k));
    archivo = fullfile(carpetaCaso,"psoc_uart.csv");
    assert(isfile(archivo),"Falta la captura identificada: %s",archivo);
    D = readtable(archivo);
    assert(height(D)==256,"%s no contiene 256 muestras.",casos(k));
    assert(all(D.flags==0),"%s contiene banderas de fallo.",casos(k));
    experimental{k} = D;
    % La referencia calculada usa directamente los estados verdaderos. No
    % interviene ningun observador y representa la dinamica ideal de A-BK.
    calculado{k} = simularEstadosConocidos(dId,pId,height(D));
    simulado{k} = simularNoIdeal(dId,pId,indices(k),modos(k),height(D));
    rigol(k) = leerRigol(carpetaCaso);
end

%% Comparacion calculada, simulada y experimental
n = numel(casos);
rhoAumentada = zeros(n,1);
rhoObservador = zeros(n,1);
convTeorica2pct_ms = zeros(n,1);
picoCalc_mV = zeros(n,1); picoSim_mV = zeros(n,1); picoExp_mV = zeros(n,1);
tpCalc_ms = zeros(n,1); tpSim_ms = zeros(n,1); tpExp_ms = zeros(n,1);
finalCalc_mV = zeros(n,1); finalSim_mV = zeros(n,1); finalExp_mV = zeros(n,1);
rmseSimExp_mV = zeros(n,1);
rmsErrorObservable_mV = zeros(n,1); picoErrorObservable_mV = zeros(n,1);
rmsErrorObservableFinal_mV = zeros(n,1);
stdErrorObservableFinal_mV = zeros(n,1);
uMaxCalc_mV = zeros(n,1); uMaxSim_mV = zeros(n,1);
uMaxSolicExp_mV = zeros(n,1); uMaxAplicExp_mV = zeros(n,1);
uRMSAplicExp_mV = zeros(n,1);
cpuMax_us = zeros(n,1); TsMediana_us = zeros(n,1);
usoCPU_pct = zeros(n,1); margenTemporal_pct = zeros(n,1);

for k = 1:n
    D = experimental{k}; C = calculado{k}; S = simulado{k};
    o = dId.observadores(indices(k));
    M = matrizAumentada(dId,o.L_pred,o.L_actual,modos(k));
    rhoAumentada(k) = max(abs(eig(M)));
    rhoObservador(k) = max(abs(o.polos));
    convTeorica2pct_ms(k) = tiempoTeorico2pct(o.polos,pId.Ts_s);

    jExp = find(D.r_mV>0,1,"first");
    jCalc = find(C.r_V>0,1,"first");
    jSim = find(S.r_V>0,1,"first");
    % El pico se evalua en los primeros 100 ms del transitorio. Asi no se
    % confunde un ciclo limite tardio de cuantizacion con el sobreimpulso.
    finExp = min(height(D),jExp+round(0.100/pId.Ts_s));
    finCalc = min(numel(C.t_s),jCalc+round(0.100/pId.Ts_s));
    finSim = min(numel(S.t_s),jSim+round(0.100/pId.Ts_s));
    [picoExp_mV(k),iExp] = max(D.y_rel_mV(jExp:finExp));
    [picoCalc,iCalc] = max(C.y_V(jCalc:finCalc));
    [picoSim,iSim] = max(S.y_V(jSim:finSim));
    picoCalc_mV(k) = 1000*picoCalc;
    picoSim_mV(k) = 1000*picoSim;
    iExp = iExp+jExp-1; iCalc = iCalc+jCalc-1; iSim = iSim+jSim-1;
    tpExp_ms(k) = (D.t_us(iExp)-D.t_us(jExp))/1000;
    tpCalc_ms(k) = 1000*(C.t_s(iCalc)-C.t_s(jCalc));
    tpSim_ms(k) = 1000*(S.t_s(iSim)-S.t_s(jSim));
    finalExp_mV(k) = mean(D.y_rel_mV(end-49:end),"omitmissing");
    finalCalc_mV(k) = 1000*mean(C.y_V(end-49:end),"omitmissing");
    finalSim_mV(k) = 1000*mean(S.y_V(end-49:end),"omitmissing");
    rmseSimExp_mV(k) = sqrt(mean((1000*S.y_V(jExp:end)- ...
        D.y_rel_mV(jExp:end)).^2,"omitmissing"));
    eObs = D.y_rel_mV-D.xhat2_mV;
    rmsErrorObservable_mV(k) = sqrt(mean(eObs(jExp:end).^2,"omitmissing"));
    picoErrorObservable_mV(k) = max(abs(eObs(jExp:end)),[],"omitmissing");
    ventanaFinal = max(1,height(D)-49):height(D);
    rmsErrorObservableFinal_mV(k) = sqrt(mean( ...
        eObs(ventanaFinal).^2,"omitmissing"));
    stdErrorObservableFinal_mV(k) = std( ...
        eObs(ventanaFinal),0,"omitmissing");
    uMaxCalc_mV(k) = 1000*max(abs(C.u_V),[],"omitmissing");
    uMaxSim_mV(k) = 1000*max(abs(S.u_V),[],"omitmissing");
    uMaxSolicExp_mV(k) = max(abs(D.u_solicitada_mV),[],"omitmissing");
    uMaxAplicExp_mV(k) = max(abs(D.u_nominal_mV),[],"omitmissing");
    uRMSAplicExp_mV(k) = sqrt(mean( ...
        D.u_nominal_mV(jExp:end).^2,"omitmissing"));
    cpuMax_us(k) = max(D.cpu_us,[],"omitmissing");
    TsMediana_us(k) = median(D.intervalo_us(D.k>0),"omitmissing");
    usoCPU_pct(k) = 100*cpuMax_us(k)/TsMediana_us(k);
    margenTemporal_pct(k) = 100-usoCPU_pct(k);
end

comparacion = table(casos,rhoAumentada,rhoObservador,convTeorica2pct_ms, ...
    picoCalc_mV,picoSim_mV,picoExp_mV,tpCalc_ms,tpSim_ms,tpExp_ms, ...
    finalCalc_mV,finalSim_mV,finalExp_mV,rmseSimExp_mV, ...
    rmsErrorObservable_mV,picoErrorObservable_mV, ...
    rmsErrorObservableFinal_mV,stdErrorObservableFinal_mV, ...
    uMaxCalc_mV,uMaxSim_mV,uMaxSolicExp_mV,uMaxAplicExp_mV, ...
    uRMSAplicExp_mV,cpuMax_us,TsMediana_us,usoCPU_pct,margenTemporal_pct);
writetable(comparacion,fullfile(salidaDir, ...
    "comparacion_calculado_simulado_experimental.csv"));

%% Coeficientes calculados con el modelo identificado
coeficientes = tablaCoeficientes(dId);
writetable(coeficientes,fullfile(salidaDir, ...
    "coeficientes_rediseno_identificado.csv"));

%% Convergencia del error completo en simulacion
pPerturbado = pId;
pPerturbado.xestimado0 = [0.02;-0.01];
simConvergencia = cell(4,1);
convError1e4_ms = zeros(4,1); errorInicial_mV = zeros(4,1);
errorMax_mV = zeros(4,1); controlMaxPert_mV = zeros(4,1);
for k = 1:4
    S = simular_lab7(dId,pPerturbado,indices(k),char(modos(k)));
    simConvergencia{k} = S;
    convError1e4_ms(k) = tiempoPersistente(S.t_s,S.norma_error,1e-4);
    errorInicial_mV(k) = 1000*S.norma_error(1);
    errorMax_mV(k) = 1000*max(S.norma_error,[],"omitmissing");
    controlMaxPert_mV(k) = 1000*max(abs(S.u_V),[],"omitmissing");
end
metricasConvergencia = table(casos,convError1e4_ms,errorInicial_mV, ...
    errorMax_mV,controlMaxPert_mV);
writetable(metricasConvergencia,fullfile(salidaDir, ...
    "metricas_convergencia_identificada.csv"));

% Comparacion compacta entre la tasa asintotica asignada y el resultado de
% la perturbacion concreta. El criterio teorico es 2 %; el simulado es el
% primer instante desde el cual ||e||_2 permanece por debajo de 1e-4 V.
familia = ["E1";"E2"];
poloReal = zeros(2,1); poloImagAbs = zeros(2,1);
rhoFamilia = zeros(2,1); muestrasTeoricas2pct = zeros(2,1);
tiempoTeoricoFamilia2pct_ms = zeros(2,1);
convPredictor1e4_ms = convError1e4_ms([1 3]);
convActual1e4_ms = convError1e4_ms([2 4]);
for j = 1:2
    polos = dId.observadores(j).polos;
    poloReal(j) = real(polos(1));
    poloImagAbs(j) = abs(imag(polos(1)));
    rhoFamilia(j) = max(abs(polos));
    muestrasTeoricas2pct(j) = ceil(log(0.02)/log(rhoFamilia(j)));
    tiempoTeoricoFamilia2pct_ms(j) = ...
        1000*pId.Ts_s*muestrasTeoricas2pct(j);
end
convergenciaTeorica = table(familia,poloReal,poloImagAbs,rhoFamilia, ...
    muestrasTeoricas2pct,tiempoTeoricoFamilia2pct_ms, ...
    convPredictor1e4_ms,convActual1e4_ms);
writetable(convergenciaTeorica,fullfile(salidaDir, ...
    "comparacion_convergencia_teorica_simulada.csv"));

%% Cuantizacion: diferencias calculadas que colapsan al mismo codigo
par = ["E1";"E2"];
porcentajeMismoNivel = zeros(2,1);
porcentajeSolicitudDistintaMismoDAC = zeros(2,1);
compresionSolicitudesDistintas = zeros(2,1);
mediaDiferenciaSolicitada_mV = zeros(2,1);
mediaDiferenciaAplicada_mV = zeros(2,1);
pasoPositivo_mV = 1000*pId.cuantizacion.dac_positivo_V*ones(2,1);
pasoNegativo_mV = 1000*pId.cuantizacion.dac_negativo_V*ones(2,1);
for j = 1:2
    P = experimental{2*j-1}; A = experimental{2*j};
    mismo = P.u_nominal_mV==A.u_nominal_mV;
    diferenteSolicitud = abs(P.u_solicitada_mV-A.u_solicitada_mV)>=1;
    porcentajeMismoNivel(j) = 100*mean(mismo);
    porcentajeSolicitudDistintaMismoDAC(j) = 100*mean(mismo & diferenteSolicitud);
    compresionSolicitudesDistintas(j) = 100*sum(mismo & diferenteSolicitud)/ ...
        max(1,sum(diferenteSolicitud));
    mediaDiferenciaSolicitada_mV(j) = mean(abs( ...
        P.u_solicitada_mV-A.u_solicitada_mV),"omitmissing");
    mediaDiferenciaAplicada_mV(j) = mean(abs( ...
        P.u_nominal_mV-A.u_nominal_mV),"omitmissing");
end
cuantizacion = table(par,pasoPositivo_mV,pasoNegativo_mV, ...
    porcentajeMismoNivel,porcentajeSolicitudDistintaMismoDAC, ...
    compresionSolicitudesDistintas,mediaDiferenciaSolicitada_mV, ...
    mediaDiferenciaAplicada_mV);
writetable(cuantizacion,fullfile(salidaDir,"analisis_cuantizacion_DAC.csv"));

%% Evidencia fisica del Rigol
deltaJ5_mV = 1000*[rigol.deltaJ5_V].';
deltaJ7_mV = 1000*[rigol.deltaJ7_V].';
gananciaFisica = deltaJ7_mV./deltaJ5_mV;
rigolFisico = table(casos,deltaJ5_mV,deltaJ7_mV,gananciaFisica);
writetable(rigolFisico,fullfile(salidaDir,"amplitudes_fisicas_Rigol.csv"));

%% Figuras para el informe
crearFiguraComparacion(experimental,calculado,simulado,casos, ...
    fullfile(figurasDir,"comparacion_calculada_simulada_experimental_4_casos.png"));
crearFiguraEstados(experimental,casos, ...
    fullfile(figurasDir,"estados_estimados_experimentales_4_casos.png"));
crearFiguraErrores(experimental,casos, ...
    fullfile(figurasDir,"errores_estimacion_experimentales_4_casos.png"));
crearFiguraConvergencia(simConvergencia,casos, ...
    fullfile(figurasDir,"convergencia_rediseno_identificado_4_casos.png"));
crearFiguraRigol(capturasDir,carpetas,casos, ...
    fullfile(figurasDir,"mediciones_fisicas_Rigol_4_casos.png"));

disp(comparacion);
disp(metricasConvergencia);
disp(convergenciaTeorica);
disp(cuantizacion);
disp(rigolFisico);
fprintf("Resultados de la campaña identificada: %s\n",salidaDir);

function S = simularEstadosConocidos(d,p,N)
t = (0:N-1).'*p.Ts_s;
x = zeros(2,N); y = zeros(N,1); u = zeros(N,1);
r = p.referencia_V*(t>=p.referencia_inicio_s);
for k = 1:N
    y(k) = d.C*x(:,k);
    u(k) = -d.K*x(:,k)+d.Nr*r(k);
    if k<N
        x(:,k+1) = d.A*x(:,k)+d.B*u(k);
    end
end
S = struct(t_s=t,y_V=y,r_V=r,u_V=u,x_V=x.');
end

function S = simularNoIdeal(d,p,idx,modo,N)
t = (0:N-1).'*p.Ts_s;
x = zeros(2,N); xhMem = p.xestimado0(:);
y = zeros(N,1); yMedida = zeros(N,1); xh = zeros(2,N);
u = zeros(N,1); uSolic = zeros(N,1);
r = p.referencia_V*(t>=p.referencia_inicio_s);
o = d.observadores(idx);
for k = 1:N
    y(k) = d.C*x(:,k);
    yMedida(k) = round(y(k)/p.cuantizacion.adc_V)*p.cuantizacion.adc_V;
    innovacion = yMedida(k)-d.C*xhMem;
    if modo == "actual"
        xh(:,k) = xhMem+o.L_actual*innovacion;
    else
        xh(:,k) = xhMem;
    end
    uSolic(k) = -d.K*xh(:,k)+d.Nr*r(k);
    u(k) = cuantizarDAC(uSolic(k),p);
    if k<N
        x(:,k+1) = d.A*x(:,k)+d.B*u(k);
        if modo == "actual"
            xhMem = d.A*xh(:,k)+d.B*u(k);
        else
            xhMem = d.A*xh(:,k)+d.B*u(k)+o.L_pred*innovacion;
        end
    end
end
S = struct(t_s=t,y_V=y,yMedida_V=yMedida,r_V=r,u_V=u, ...
    uSolic_V=uSolic,xhat1_V=xh(1,:).',xhat2_V=xh(2,:).');
end

function u = cuantizarDAC(pedido,p)
pedido = min(p.u_max_V,max(p.u_min_V,pedido));
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

function M = matrizAumentada(d,Lp,La,modo)
A=d.A; B=d.B; C=d.C; K=d.K;
if modo=="prediccion"
    M=[A,-B*K; Lp*C,A-B*K-Lp*C];
else
    E=eye(2)-La*C;
    M=[A-B*K*La*C,-B*K*E; (A-B*K)*La*C,(A-B*K)*E];
end
end

function tms = tiempoTeorico2pct(polos,Ts)
rho=max(abs(polos));
tms=1000*Ts*ceil(log(0.02)/log(rho));
end

function tms = tiempoPersistente(t,e,umbral)
fuera = find(e>=umbral);
if isempty(fuera)
    tms = 0;
elseif fuera(end)==numel(e)
    tms = NaN;
else
    tms = 1000*t(fuera(end)+1);
end
end

function T = tablaCoeficientes(d)
n=numel(d.observadores); caso=("E"+(1:n)).';
A11=repmat(d.A(1,1),n,1); A12=repmat(d.A(1,2),n,1);
A21=repmat(d.A(2,1),n,1); A22=repmat(d.A(2,2),n,1);
B1=repmat(d.B(1),n,1); B2=repmat(d.B(2),n,1);
K1=repmat(d.K(1),n,1); K2=repmat(d.K(2),n,1);
Nr=repmat(d.Nr,n,1); Lpred1=zeros(n,1); Lpred2=zeros(n,1);
Lactual1=zeros(n,1); Lactual2=zeros(n,1);
for k=1:n
    Lpred1(k)=d.observadores(k).L_pred(1);
    Lpred2(k)=d.observadores(k).L_pred(2);
    Lactual1(k)=d.observadores(k).L_actual(1);
    Lactual2(k)=d.observadores(k).L_actual(2);
end
T=table(caso,A11,A12,A21,A22,B1,B2,K1,K2,Nr, ...
    Lpred1,Lpred2,Lactual1,Lactual2);
end

function R = leerRigol(carpetaCaso)
C1=readtable(fullfile(carpetaCaso,"chan1.csv"));
C2=readtable(fullfile(carpetaCaso,"chan2.csv"));
n1=height(C1); n2=height(C2);
m1=max(10,round(0.20*n1)); m2=max(10,round(0.20*n2));
c1a=median(C1.voltage_v(1:m1),"omitmissing");
c1b=median(C1.voltage_v(end-m1+1:end),"omitmissing");
c2a=median(C2.voltage_v(1:m2),"omitmissing");
c2b=median(C2.voltage_v(end-m2+1:end),"omitmissing");
R=struct(deltaJ5_V=abs(c1a-c1b),deltaJ7_V=abs(c2a-c2b), ...
    J5_inicial_V=c1a,J5_final_V=c1b,J7_inicial_V=c2a,J7_final_V=c2b);
end

function crearFiguraComparacion(D,C,S,casos,archivo)
fig=figure(Color="w",Visible="off",Position=[100 100 1300 850]);
tl=tiledlayout(fig,2,2,TileSpacing="compact",Padding="compact");
for k=1:4
    ax=nexttile(tl); hold(ax,"on");
    stairs(ax,1000*C{k}.t_s,1000*C{k}.y_V,LineWidth=1.4, ...
        DisplayName="Ideal con estados conocidos");
    stairs(ax,1000*S{k}.t_s,1000*S{k}.y_V,"--",LineWidth=1.3, ...
        DisplayName="Simulación ADC/DAC");
    stairs(ax,D{k}.t_us/1000,D{k}.y_rel_mV,LineWidth=1.0, ...
        DisplayName="Experimento UART");
    yline(ax,50,":",DisplayName="Referencia");
    hold(ax,"off"); grid(ax,"on"); xlim(ax,[55 180]);
    title(ax,casos(k)); xlabel(ax,"Tiempo (ms)"); ylabel(ax,"Salida (mV)");
    legend(ax,Location="best",Box="off"); ax.FontSize=9;
end
title(tl,"Modelo identificado: referencia ideal, simulación y experimento");
exportgraphics(fig,archivo,Resolution=300); close(fig);
end

function crearFiguraEstados(D,casos,archivo)
fig=figure(Color="w",Visible="off",Position=[100 50 1450 1150]);
tl=tiledlayout(fig,4,2,TileSpacing="compact",Padding="compact");
for k=1:4
    t=D{k}.t_us/1000;
    ax1=nexttile(tl); stairs(ax1,t,D{k}.xhat1_mV,LineWidth=1.2);
    grid(ax1,"on"); xlim(ax1,[55 180]); ylabel(ax1,"xhat1 (mV)");
    title(ax1,casos(k)); ax1.FontSize=9;
    ax2=nexttile(tl); hold(ax2,"on");
    stairs(ax2,t,D{k}.y_rel_mV,LineWidth=1.0,DisplayName="y");
    stairs(ax2,t,D{k}.xhat2_mV,"--",LineWidth=1.2,DisplayName="xhat2");
    hold(ax2,"off"); grid(ax2,"on"); xlim(ax2,[55 180]); ylabel(ax2,"mV");
    legend(ax2,Location="best",Box="off"); ax2.FontSize=9;
    if k==4, xlabel(ax1,"Tiempo (ms)"); xlabel(ax2,"Tiempo (ms)"); end
end
title(tl,"Evolución experimental de los estados estimados");
exportgraphics(fig,archivo,Resolution=300); close(fig);
end

function crearFiguraErrores(D,casos,archivo)
fig=figure(Color="w",Visible="off",Position=[100 100 1300 850]);
tl=tiledlayout(fig,2,2,TileSpacing="compact",Padding="compact");
for k=1:4
    ax=nexttile(tl); t=D{k}.t_us/1000;
    e=D{k}.y_rel_mV-D{k}.xhat2_mV;
    j=find(D{k}.r_mV>0,1,"first");
    stairs(ax,t,e,LineWidth=1.2); grid(ax,"on"); xlim(ax,[55 180]);
    yline(ax,0,"--"); yline(ax,4.76,":"); yline(ax,-4.76,":");
    title(ax,casos(k)); xlabel(ax,"Tiempo (ms)"); ylabel(ax,"e_y (mV)");
    text(ax,0.03,0.92,sprintf("RMS = %.2f mV", ...
        sqrt(mean(e(j:end).^2,"omitmissing"))),Units="normalized", ...
        VerticalAlignment="top",BackgroundColor="w");
    ax.FontSize=9;
end
title(tl,"Error observable experimental y resolución equivalente del ADC");
exportgraphics(fig,archivo,Resolution=300); close(fig);
end

function crearFiguraConvergencia(S,casos,archivo)
fig=figure(Color="w",Visible="off",Position=[100 100 1300 850]);
tl=tiledlayout(fig,2,2,TileSpacing="compact",Padding="compact");
for k=1:4
    ax=nexttile(tl);
    semilogy(ax,1000*S{k}.t_s,S{k}.norma_error,LineWidth=1.4);
    grid(ax,"on"); yline(ax,1e-4,"--",DisplayName="Umbral");
    xlim(ax,[0 40]); ylim(ax,[1e-15 1]); title(ax,casos(k));
    xlabel(ax,"Tiempo (ms)"); ylabel(ax,"norma del error"); ax.FontSize=9;
end
title(tl,"Convergencia calculada con perturbación inicial de estimación");
exportgraphics(fig,archivo,Resolution=300); close(fig);
end

function crearFiguraRigol(base,carpetas,casos,archivo)
fig=figure(Color="w",Visible="off",Position=[100 100 1300 850]);
tl=tiledlayout(fig,2,2,TileSpacing="compact",Padding="compact");
for k=1:4
    C1=readtable(fullfile(base,carpetas(k),"chan1.csv"));
    C2=readtable(fullfile(base,carpetas(k),"chan2.csv"));
    ax=nexttile(tl); hold(ax,"on");
    t1=1000*C1.time_s; v1=1000*C1.voltage_v;
    t2=1000*C2.time_s; v2=1000*C2.voltage_v;
    plot(ax,t1,v1,Color=[0.80 0.88 0.96],LineWidth=0.5, ...
        HandleVisibility="off");
    plot(ax,t2,v2,Color=[0.98 0.86 0.75],LineWidth=0.5, ...
        HandleVisibility="off");
    plot(ax,t1,movmean(v1,11),Color=[0 0.4470 0.7410], ...
        LineWidth=1.3,DisplayName="J5");
    plot(ax,t2,movmean(v2,11),Color=[0.8500 0.3250 0.0980], ...
        LineWidth=1.3,DisplayName="J7");
    hold(ax,"off"); grid(ax,"on"); title(ax,casos(k));
    xlabel(ax,"Tiempo Rigol (ms)"); ylabel(ax,"Tensión (mV)");
    legend(ax,Location="best",Box="off"); ax.FontSize=9;
end
title(tl,"Medición física simultánea J5/J7 (media móvil de 5,5 ms)");
exportgraphics(fig,archivo,Resolution=300); close(fig);
end
