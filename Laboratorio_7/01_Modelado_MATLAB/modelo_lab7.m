function p = modelo_lab7(origen)
%MODELO_LAB7 Modelo de planta para diseño y comparación del Laboratorio 7.
%   p = modelo_lab7() usa por defecto el modelo identificado en Lab. 5,
%   contrastado en lazo abierto durante Lab. 7.
%   p = modelo_lab7("nominal") conserva el modelo del esquema solamente
%   como referencia de comparación.

arguments
    origen (1,1) string {mustBeMember(origen,["identificado","nominal"])} = ...
        "identificado"
end

p.R5_ohm = 150e3;
p.R6_ohm = 47e3;
p.R1_ohm = 15e3;
p.R2_ohm = 47e3;
p.C1_F = 100e-9;
p.C3_F = 100e-9;

if origen == "identificado"
    % Gp(s)=K/((tau1*s+1)(tau2*s+1)). La identificación no separa las
    % ganancias de cada etapa. Para conservar estados en voltios y y=x2,
    % se mantiene la ganancia nominal de la primera etapa y se asigna la
    % segunda de modo que el producto coincida exactamente con K.
    p.tau1_s = 9.06915e-3;
    p.tau2_s = 0.774399e-3;
    p.K_estatica = 1.002941;
    gananciaEtapa1 = p.R5_ohm/p.R6_ohm;
    gananciaEtapa2 = p.K_estatica/gananciaEtapa1;
    p.F = [-1/p.tau1_s, 0; ...
           -gananciaEtapa2/p.tau2_s, -1/p.tau2_s];
    p.G = [-gananciaEtapa1/p.tau1_s; 0];
    p.origen_modelo = "IDENTIFICADO_LAB5_J5_J7";
    p.revision_modelo = "K1.002941_TAU9.06915MS_0.774399MS";
    p.validado = true;
    p.validacion = "Identificacion Lab5 y contraste abierto Lab7 2026-11-24";
    p.polos_estimador = { ...
        [0.25+0.05i, 0.25-0.05i], ...
        [0.20+0.10i, 0.20-0.10i]};
else
    % Referencia nominal del esquema oficial.
    p.F = [-1/(p.R5_ohm*p.C1_F), 0; ...
           -1/(p.R2_ohm*p.C3_F), -1/(p.R1_ohm*p.C3_F)];
    p.G = [-1/(p.R6_ohm*p.C1_F); 0];
    p.tau1_s = p.R5_ohm*p.C1_F;
    p.tau2_s = p.R1_ohm*p.C3_F;
    p.K_estatica = (p.R5_ohm/p.R6_ohm)*(p.R1_ohm/p.R2_ohm);
    p.origen_modelo = "GUIA_OFICIAL_NOMINAL";
    p.revision_modelo = "R0_ESQUEMA_GUIA_2026-11-23";
    p.validado = false;
    p.validacion = "Referencia nominal sin identificacion experimental";
    p.polos_estimador = { ...
        [0.40+0.25i, 0.40-0.25i], ...
        [0.20+0.10i, 0.20-0.10i]};
end

p.H = [0 1];
p.J = 0;
p.simulacion_nominal = origen == "nominal";
p.Ts_s = 0.002;
p.reloj_timer_hz_antecedente = 100e3;
p.polos_control = [0.80+0.25i, 0.80-0.25i];
p.referencia_V = 0.05;
p.referencia_inicio_s = 0.064;
p.t_sim_s = 0.512;
p.x0 = [0;0];
p.xestimado0 = [0;0];
p.u_min_V = -0.115;
p.u_max_V = 0.107;

p.cuantizacion.adc_V = 0.001/0.210251951;
p.cuantizacion.dac_positivo_V = 0.004*3.842612;
p.cuantizacion.dac_negativo_V = 0.004*2.640105691;
end
