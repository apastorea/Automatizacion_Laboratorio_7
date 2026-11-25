% PREVALIDAR_E2_PARA_PSOC_LAB7
% Ensayos offline de las estructuras E2 con planta identificada Lab5.
% NO modifica PSoC Creator; NO usa COM4 ni VISA.
% Reproduce saturacion ABORTIVA del firmware, limites conservadores y
% conversion DAC nominal por codigos. Modelo simplificado (sin ISR/HAL real).
clear;clc;close all;
fprintf('\n==============================================\n');
fprintf('LAB7: PREVALIDACION E2 (SOLO SIMULACION)\n');
fprintf('==============================================\n');
p=modelo_lab7("nominal");
d=disenar_lab7(p);
Ts=p.Ts_s;N=256;
% Transferencia validada previamente en Lab5 (sin refit en Lab7)
K5=1.002941; tau1=.00906915; tau2=.000774399;
a=-p.F(2,1);
F5=[-1/tau1 0; -a -1/tau2];
G5=[-K5/(a*tau1*tau2);0];
[Ap,Bp,Cp,~]=ssdata(c2d(ss(F5,G5,[0 1],0),Ts,'zoh'));
% ADC: aproximadamente 5.42 mV en la salida relativa por cuenta
qADC=.00114/.210251951;
% Codigos DAC nominales en J5, segun Lab5
qPos=.004*3.842612; qNeg=.004*2.640105691;
uMin=-.115; uMax=.107; uFisico=.120;
Lpred=d.observadores(2).L_pred;
Lact=d.observadores(2).L_actual;
% Analisis del sistema lineal ampliado en la planta identificada
I=eye(2); rho=zeros(2,1);
Mp=[Ap -Bp*d.K; Lpred*Cp d.A-d.B*d.K-Lpred*d.C];
E=I-Lact*d.C;
Ma=[Ap-Bp*d.K*Lact*Cp -Bp*d.K*E; ...
    (d.A-d.B*d.K)*Lact*Cp (d.A-d.B*d.K)*E];
rho(1)=max(abs(eig(Mp)));rho(2)=max(abs(eig(Ma)));
fprintf('rho Predictor E2 = %.6f\n',rho(1));
fprintf('rho Actual E2    = %.6f\n',rho(2));
assert(all(rho<1),'E2 NO cumple estabilidad lineal; detener.');

fprintf('DAC cuantizado: max +%d = %.3f mV, max -%d = %.3f mV\n',...
    floor(uFisico/qPos),floor(uFisico/qPos)*qPos*1000,...
    floor(uFisico/qNeg),floor(uFisico/qNeg)*qNeg*1000);

% Escenarios de estres: ruido HIPOTETICO a entrada ADC, no medido.
% 20 repeticiones para cada nivel; no prueba robustez para todo ruido.
niveles=[0 .003 .010]; repeticiones=20;
filas={}; idx=0; ejemplo=struct();
for modo=["PREDICCION","ACTUAL"]
    if modo=="PREDICCION",L=Lpred;else,L=Lact;end
    for sigma=niveles
        for rep=1:repeticiones
            rng(700+rep);
            ruido=sigma*randn(N,1);
            x=zeros(2,1);mem=zeros(2,1);pre=zeros(32,1);
            ylog=nan(N,1); ulog=nan(N,1); el_log=nan(N,1);
            fallo="NINGUNO";kFallo=NaN; muestras=0;
            for j=1:N
                y=Cp*x;
                yADC=round((y+ruido(j))/qADC)*qADC;
                if j<=32
                    pre(j)=yADC;
                    mem=zeros(2,1);
                    uDAC=0;
                else
                    yRel=yADC-mean(pre);
                    innov=yRel-d.C*mem;
                    if modo=="ACTUAL"
                        xe=mem+L*innov;
                    else
                        xe=mem;
                    end
                    uIdeal=d.Nr*p.referencia_V-d.K*xe;
                    if ~isfinite(uIdeal) || ~isfinite(yRel)
                        fallo="NO_FINITO";
                    elseif abs(yRel)>.500
                        fallo="SALIDA_FUERA_RANGO";
                    elseif uIdeal<uMin || uIdeal>uMax
                        % Firmware registra F_LIMITE y ordena salida cero;
                        % NO sigue limitado como una simulacion de saturador.
                        fallo="SATURACION_SOLICITADA";
                    end
                    if fallo~="NINGUNO"
                        kFallo=j-1;
                        ulog(j)=0; ylog(j)=y; muestras=j;
                        break;
                    end
                    if uIdeal>=0
                        codigo=round(uIdeal/qPos);
                        uDAC=codigo*qPos;
                    else
                        codigo=round(-uIdeal/qNeg);
                        uDAC=-codigo*qNeg;
                    end
                    if abs(uDAC)>uFisico+1e-12
                        fallo="DAC_FUERA_RANGO";
                        kFallo=j-1;
                        ulog(j)=0; ylog(j)=y; muestras=j;
                        break;
                    end
                    if modo=="ACTUAL"
                        mem=d.A*xe+d.B*uDAC;
                    else
                        mem=d.A*xe+d.B*uDAC+L*innov;
                    end
                    el_log(j)=yRel-d.C*xe;
                end
                ylog(j)=y;
                ulog(j)=uDAC;
                x=Ap*x+Bp*uDAC;
                muestras=j;
            end
            if fallo=="NINGUNO"
                maxY=max(ylog)*1000;
                cola=mean(ylog(end-49:end))*1000;
            else
                maxY=max(ylog(1:muestras))*1000;
                cola=NaN;
            end
            maxU=max(abs(ulog(1:muestras)))*1000;
            idx=idx+1;
            filas(idx,:)={modo,sigma*1000,rep,fallo,kFallo,muestras,...
                maxY,cola,maxU};
            if rep==1
                key=sprintf('%s_%dmV',char(modo),round(sigma*1000));
                ejemplo.(key)=struct('t',((0:N-1)*Ts)*1000, ...
                    'y',ylog*1000,'u',ulog*1000,'fallo',fallo);
            end
        end
    end
end
T=cell2table(filas,'VariableNames',{'modo','ruido_RMS_hipotetico_mV',...
    'repeticion','resultado','k_primera_falla','muestras','y_max_mV',...
    'y_cola_media_mV','DAC_max_abs_mV'});
T.modo=string(T.modo);T.resultado=string(T.resultado);
salida=fullfile(fileparts(mfilename('fullpath')),'..','05_Resultados');
if ~isfolder(salida),mkdir(salida);end
writetable(T,fullfile(salida,'prevalidacion_E2_no_ideal_lab7.csv'));
resumen=strings(6,1);i=0;
for modo=["PREDICCION","ACTUAL"]
    for sigma=niveles
        i=i+1;
        sel=T.modo==modo & T.ruido_RMS_hipotetico_mV==sigma*1000;
        grupo=T(sel,:);
        nFallas=nnz(grupo.resultado~="NINGUNO");
        resumen(i)=sprintf('%s: ruido supuesto %.0f mV, fallos %d/%d', ...
            modo,sigma*1000,nFallas,height(grupo));
        disp(resumen(i));
    end
end
destinoFig=fullfile(salida,'figuras');
if ~isfolder(destinoFig),mkdir(destinoFig);end
for modo=["PREDICCION","ACTUAL"]
    key=sprintf('%s_0mV',char(modo));
    s=ejemplo.(key);
    f=figure('Color','w','Name',['E2 ' char(modo)]);
    tiledlayout(2,1);
    nexttile; stairs(s.t,s.y,'LineWidth',1.3);hold on;
    yline(p.referencia_V*1000,'--','Referencia');
    ylabel('y simulada (mV)');title(['E2 ' char(modo) ' - planta identificada Lab5']);grid on;
    nexttile;stairs(s.t,s.u,'LineWidth',1.3);
    ylabel('u DAC nominal (mV)');xlabel('Tiempo (ms)');grid on;
    exportgraphics(f,fullfile(destinoFig,...
        ['prevalidacion_E2_' lower(char(modo)) '.png']),'Resolution',220);
end
disp(' ');
disp('Tabla guardada: Laboratorio_7/05_Resultados/prevalidacion_E2_no_ideal_lab7.csv');
fprintf('ESTO NO AUTORIZA PROGRAMAR: falta ensayo C/ISR y revision fisica.\n');
fprintf('FALLO = el modelo espera que el firmware ordene parada inmediata.\n');
