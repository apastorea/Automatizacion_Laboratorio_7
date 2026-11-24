% CAPTURAR_UART_MONITOR_LAB7
% Captura telemetria del firmware Lab7 por COM4 en MONITOR, ABIERTO, PREDICCION o ACTUAL.
% No modifica DAC, ADC, Timer ni ningun parametro del hardware.
% PASOS: abrir COM4, ejecutar este script, presionar una vez SW3 RESET
% en el KitProg DURANTE la ventana de captura (NO mantener presionado).
% MONITOR: fuente deshabilitada y J8-J5 aislado; ABIERTO: fuente bipolar encendida y puentes J8-J5 y J9-P0[2] restablecidos previamente con todo apagado.
% Si J9-P0[2] esta aislado, el ADC puede marcar F_ADC y finalizar antes.
%
% Guarda captura cruda con fecha en 04_Ensayos/Lab7_UART_...
clear puertoLab7;
puerto = "COM4";
baudios = 57600;
duracion_s = 20;
nombreEnsayo = "Lab7_UART_";
carpetaScript = fileparts(mfilename('fullpath'));
carpetaEnsayos = fullfile(carpetaScript, '..', '04_Ensayos');
if ~isfolder(carpetaEnsayos), mkdir(carpetaEnsayos); end
idFecha = char(datetime('now','Format','yyyyMMdd_HHmmss'));
carpetaSalida = fullfile(carpetaEnsayos, [char(nombreEnsayo) idFecha]);
mkdir(carpetaSalida);

fprintf('\nLAB7 UART: abriendo %s a %d 8N1 (MONITOR/ABIERTO/OBSERVADOR).\n',puerto,baudios);
fprintf('Este script SOLO LEE UART; prepara fuente y conexiones segun el modo compilado.\n');
fprintf('Al aparecer INICIADA, pulsa UNA VEZ el boton SW3 (RESET/BOOT) del KitProg.\n');
fprintf('No es SW1 (boton de usuario). No mantengas SW3 mientras reconectas USB.\n');
puertoLab7 = serialport(puerto, baudios, 'Timeout', 2);
configureTerminator(puertoLab7,'CR/LF');
flush(puertoLab7,'input');
recibido = uint8([]);
t = tic;
fin = false;
fprintf('CAPTURA INICIADA: presiona SW3 ahora.\n');
while toc(t) < duracion_s
    n = puertoLab7.NumBytesAvailable;
    if n > 0
        fragmento = read(puertoLab7, n, 'uint8');
        recibido = [recibido; fragmento(:)]; %#ok<AGROW>
        if numel(recibido)>250000
            warning('Se supera el limite de captura de 250 kB.');
            break
        end
        if contains(char(recibido.'),'# LAB7 END;')
            fin = true;
            break
        end
    end
    pause(0.04);
end
clear puertoLab7;
archivoRaw = fullfile(carpetaSalida,'uart_bruto.txt');
fid = fopen(archivoRaw,'wb');
assert(fid>0,'No se pudo abrir el archivo de telemetria.');
fwrite(fid,recibido,'uint8');
fclose(fid);
texto = char(recibido.');
lineas = string(regexp(texto,'\r\n|\n|\r','split'));
cabecera = find(startsWith(strtrim(lineas),'k,t_us,'),1,'first');
marcadorFin = find(startsWith(strtrim(lineas),'# LAB7 END;'),1,'first');
nFilas = numel(regexp(texto,'(?m)^\d+,','match'));
fprintf('Bytes recibidos: %d. Filas de datos detectadas: %d.\n',numel(recibido),nFilas);
fprintf('Marcador de fin: %d.\n',fin);
fprintf('Archivo crudo: %s\n',archivoRaw);
if ~isempty(cabecera) && ~isempty(marcadorFin) && marcadorFin>cabecera
    archivoCsv = fullfile(carpetaSalida,'monitor_lab7.csv');
    writelines(lineas(cabecera:marcadorFin-1),archivoCsv);
    fprintf('CSV completo: %s\n',archivoCsv);
else
    warning('Sin CSV completo. Revisar archivo crudo o reiniciar con SW3 en otra captura.');
end
if ~isempty(lineas)
    fprintf('\nPRIMERAS LINEAS RECIBIDAS:\n');
    disp(join(lineas(1:min(5,numel(lineas))),newline));
    fprintf('\nULTIMAS LINEAS RECIBIDAS:\n');
    disp(join(lineas(max(1,numel(lineas)-3):end),newline));
end
fprintf('\nInterpretacion: revise modo y flags; para ABIERTO use J9 ADC y J8-J5 conectados, con alimentacion correcta.\n');
