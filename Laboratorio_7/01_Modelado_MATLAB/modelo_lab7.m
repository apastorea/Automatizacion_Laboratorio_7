function p = modelo_lab7()
% Modelo NOMINAL del esquema oficial (pagina 2), SOLO SIMULACION.
% x1 = salida de primera etapa inversora; x2 = segunda; y=x2.
% u [V] se aplica fisicamente a R6, no es el valor crudo del DAC.
p.R5_ohm=150e3; p.R6_ohm=47e3;
p.R1_ohm=15e3;  p.R2_ohm=47e3;
p.C1_F=100e-9;  p.C3_F=100e-9;

% C1 dx1/dt + x1/R5 = -u/R6
% C3 dx2/dt + x2/R1 = -x1/R2
p.F=[-1/(p.R5_ohm*p.C1_F), 0; ...
     -1/(p.R2_ohm*p.C3_F), -1/(p.R1_ohm*p.C3_F)];
p.G=[-1/(p.R6_ohm*p.C1_F); 0];
p.H=[0 1]; p.J=0;
p.tau1_s=p.R5_ohm*p.C1_F;
p.tau2_s=p.R1_ohm*p.C3_F;
p.K_estatica=(p.R5_ohm/p.R6_ohm)*(p.R1_ohm/p.R2_ohm);
p.origen_modelo='GUIA_OFICIAL_NOMINAL';
p.revision_modelo='R0_ESQUEMA_GUIA_2026-11-23';
p.validado=false;          % NO cambiar sin validar planta/ADC/DAC.
p.simulacion_nominal=true; % Autoriza analisis matematico, NO hardware.

p.Ts_s=0.002;
p.reloj_timer_hz_antecedente=100e3; % Lab5; verificar en Lab7.
p.polos_control=[0.80+0.25i,0.80-0.25i];
p.polos_estimador={ [0.40+0.25i,0.40-0.25i], ...
                    [0.20+0.10i,0.20-0.10i] };
p.referencia_V=0.05; p.t_sim_s=0.20;
p.x0=[0;0]; p.xestimado0=[0.02;-0.01];
p.u_min_V=-1.0; p.u_max_V=1.0; % limite historico provisional.
end
