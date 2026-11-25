% COMPARAR_ABIERTO_RIGOL_MODELOS_LAB7
% Contrasta entrada CH1=J5 y salida CH2=J7 con modelos nominal y Lab5.
% Utiliza el ultimo ensayo ABIERTO marcado valido; no programa el PSoC.
clear;clc;
carpeta=fileparts(mfilename('fullpath'));
raiz=fullfile(carpeta,'..','04_Ensayos','Capturas_Sincronizadas');
assert(isfolder(raiz),'No existe carpeta de capturas sincronizadas.');
dirs=dir(raiz);dirs=dirs([dirs.isdir]);
dirs=dirs(~ismember({dirs.name},{'.','..'}));
[~,orden]=sort(string({dirs.name}),'descend');
fuente='';
for j=orden
    carpetaC=fullfile(dirs(j).folder,dirs(j).name);
    archivoMeta=fullfile(carpetaC,'metadatos.json');
    if ~isfile(archivoMeta)||~isfile(fullfile(carpetaC,'chan1.csv'))||...
       ~isfile(fullfile(carpetaC,'chan2.csv'))||...
       ~isfile(fullfile(carpetaC,'psoc_uart.csv')), continue;end
    met=jsondecode(fileread(archivoMeta));
    if isfield(met,'modo_detectado')&&strcmp(met.modo_detectado,'ABIERTO')&&...
       isfield(met,'ensayo_valido_preliminar')&&met.ensayo_valido_preliminar
        fuente=carpetaC;break;
    end
end
assert(~isempty(fuente),'No se encontro un ensayo ABIERTO valido.');
U=readtable(fullfile(fuente,'chan1.csv'));
Y=readtable(fullfile(fuente,'chan2.csv'));
Q=readtable(fullfile(fuente,'psoc_uart.csv'));
assert(height(U)==height(Y)&&height(U)>100,'CSV Rigol incompletos.');
assert(all(abs(U.time_s-Y.time_s)<1e-9),'Tiempos CH1/CH2 distintos.');
assert(height(Q)==256&&all(Q.flags==0),'UART incompleta o con fallos.');
assert(nnz(Q.u_solicitada_mV>0)==96,'Duracion del pulso diferente.');
t=U.time_s;u=U.voltage_v;y=Y.voltage_v;
dt=median(diff(t));
pre=t>=-.25&t<=-.10; meseta=t>=.07&t<=.16;
assert(nnz(pre)>30&&nnz(meseta)>30,'Ventanas temporales no validas.');
u0=mean(u(pre));y0=mean(y(pre));
du=mean(u(meseta))-u0;dy=mean(y(meseta))-y0;
assert(du>0.005,'No se detecto pulso fisico en CH1.');
p=modelo_lab7("nominal");
Gnom=ss(p.F,p.G,p.H,p.J);
G5=tf(1.002941,conv([0.00906915 1],[0.000774399 1]));
tt=t-t(1);uin=u-u0; yout=y-y0;
yNom=lsim(c2d(Gnom,dt,'zoh'),uin,tt);
yLab5=lsim(c2d(G5,dt,'zoh'),uin,tt);
Kexp=dy/du;
rmseNom=sqrt(mean((yout-yNom).^2));
rmseLab5=sqrt(mean((yout-yLab5).^2));
fprintf('Captura: %s\n',fuente);
fprintf('Delta J5=%.3f mV, Delta J7=%.3f mV, Kexp=%.5f V/V\n',du*1000,dy*1000,Kexp);
fprintf('Variacion respecto K nominal: %.2f %%\n',100*(Kexp/p.K_estatica-1));
fprintf('RMSE nominal=%.3f mV; RMSE Lab5=%.3f mV (incluyen ruido CH2).\n',...
    rmseNom*1000,rmseLab5*1000);
f=figure('Color','w','Name','Lab7 - Abierto fisico vs modelos');
tiledlayout(2,1,'TileSpacing','compact');
nexttile;plot(t*1000,uin*1000,'LineWidth',1.3);grid on;
ylabel('J5 (mV)');title('Entrada fisica sin offset');
nexttile;plot(t*1000,yout*1000,'Color',[.65 .65 .65],'LineWidth',.7);hold on;
plot(t*1000,yNom*1000,'LineWidth',1.5);
plot(t*1000,yLab5*1000,'LineWidth',1.5);
grid on;xlabel('Tiempo relativo al disparo (ms)');
ylabel('J7 (mV)');
legend('Salida real cruda','Modelo nominal','Modelo Lab5','Location','best');
title('Comparacion sobre el mismo pulso fisico; sin ajustar parametros');
salida=fullfile(carpeta,'..','05_Resultados','figuras');
if ~isfolder(salida),mkdir(salida);end
exportgraphics(f,fullfile(salida,'lab7_abierto_rigol_modelos.png'),'Resolution',220);
T=table(string(fuente),height(U),height(Q),dt,du,dy,Kexp,p.K_estatica,rmseNom,rmseLab5,...
'VariableNames',{'carpeta_fuente','muestras_rigol','filas_uart','dt_rigol_s',...
'delta_J5_V','delta_J7_V','Kexp','Knominal','RMSE_nom_V','RMSE_Lab5_V'});
writetable(T,fullfile(salida,'resumen_lab7_abierto_modelos.csv'));
disp(T);
fprintf('Este es un ensayo ABIERTO, NO una prueba con observador.\n');
