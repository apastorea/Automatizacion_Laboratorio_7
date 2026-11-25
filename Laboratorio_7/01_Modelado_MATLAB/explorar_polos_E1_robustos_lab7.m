% EXPLORAR_POLOS_E1_ROBUSTOS_LAB7
% Explora alternativas de polos E1 SIN alterar modelo_lab7 ni firmware.
% Todas las parejas son adimensionales en el plano z.
% Requiere Control System Toolbox.
clear;clc;
p=modelo_lab7("nominal");d=disenar_lab7(p);
A=d.A;B=d.B;C=d.C;K=d.K;I=eye(2);
tau1=.00906915;tau2=.000774399;K5=1.002941;
a=-p.F(2,1);
F5=[-1/tau1 0;-a -1/tau2];
G5=[-K5/(a*tau1*tau2);0];
[Ap,Bp,Cp,~]=ssdata(c2d(ss(F5,G5,[0 1],0),p.Ts_s,'zoh'));
pares=[.40 .25; .35 .10; .30 .10; .25 .10; .20 .10];
n=size(pares,1);
etiqueta=strings(n,1);
rho_predictor=zeros(n,1);rho_actual=zeros(n,1);
for i=1:n
    pr=pares(i,1);pi=pares(i,2);
    polos=[complex(pr,pi),complex(pr,-pi)];
    Lp=place(A',C',polos).';
    La=place(A',(C*A)',polos).';
    MP=[Ap -Bp*K;Lp*Cp A-B*K-Lp*C];
    E=I-La*C;
    MA=[Ap-Bp*K*La*Cp -Bp*K*E;...
        (A-B*K)*La*Cp (A-B*K)*E];
    rho_predictor(i)=max(abs(eig(MP)));
    rho_actual(i)=max(abs(eig(MA)));
    etiqueta(i)=string(sprintf('%.2f+/-j%.2f',pr,pi));
end
estable_ambos=rho_predictor<1 & rho_actual<1;
T=table(etiqueta,rho_predictor,rho_actual,estable_ambos);
disp(T);
destino=fullfile(fileparts(mfilename('fullpath')),'..','05_Resultados');
if ~isfolder(destino),mkdir(destino);end
writetable(T,fullfile(destino,'exploracion_polos_E1_robustos.csv'));
fprintf(['Alternativa de estudio: polos 0.35 +/- j0.10; no se ha ',...
         'cambiado E1, el codigo PSoC ni las simulaciones oficiales.\n']);
fprintf(['Estabilidad lineal necesaria, no suficiente: verificar ',...
         'ruido, cuantizacion y limites antes de implementar.\n']);
