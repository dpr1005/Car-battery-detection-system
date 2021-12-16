% Optional submission - Daniel Puente Ramirez
clear;clc;close all force;
video_file = './Video/vid01.mp4';
fondo_file = './fondo.mat';

jump = 45;

if isfile(fondo_file)
    disp('Se ha encontrado un fichero de fondo en el directorio local. Cargando...');
    load(fondo_file);
else
    disp('Calculando el fondo del video, este proceso puede tardar un rato no muy largo');
    fondo = calcular_fondo(video_file);
end


video = VideoReader(video_file);
disp('Analizando...');
fondoD = im2double(fondo);
fondoDGris = im2gray(fondoD);
fondoS=medfilt2(fondoDGris); %FILTRO MEDIANA
cont=0;
contFAnt=0;


n_frame = 0;
while hasFrame(video)
    n_frame = n_frame + 1;
    frame = readFrame(video);
    if mod(n_frame, jump) ~= 0
        %disp([n_frame, mod(n_frame, 240)]);
        continue
    end
    frameD = im2double(frame);
    frameGris = im2gray(frameD);
    prueba = abs(frameGris - fondoDGris);
    prueba = prueba(:,[250:750]);
    %f = figure;
    %imshow(prueba);
    %waitfor(f);
    
    lvl = graythresh(prueba);
    aAjustada = im2bw(prueba,lvl);
    se = strel('disk',15);
    aAjustadaEros= imerode(aAjustada,se);
    
    se = strel('square',100);
    aAjustadaFill = imfill(aAjustadaEros,'holes');
    aAjustadaDil=imdilate(aAjustadaFill,se);
    
    ImgFiltrada=medfilt2(aAjustadaDil);
    
    ImgArea=bwareaopen(ImgFiltrada,200000);
    if mod(n_frame, jump) == 0
   
        subplot(1,7,1); imshow(prueba);
        subplot(1,7,2); imshow(aAjustada);
        subplot(1,7,3); imshow(aAjustadaEros);
        subplot(1,7,4); imshow(aAjustadaFill);
        subplot(1,7,5); imshow(aAjustadaDil);
        subplot(1,7,6); imshow(ImgFiltrada);
        subplot(1,7,7); imshow(ImgArea);
        
    end
    [L,num] = bwlabel(ImgArea);
    rect= regionprops(L,'BoundingBox');
    rprop = regionprops(L, 'all');
    
    [alto,~,~]=size(frame);
    altura=floor(alto*2/3);
    
    limSup=altura+400;
    limInf=altura-8;
    contFAct=0;
    
    % Franja de detección
    x=[1080 0];
    line(x,[limSup limSup],'Color','g');
    line(x,[limInf limInf],'Color','g');
    if mod(n_frame, jump) == 0
        for k=1: length(rect)
            bb= rect(k).BoundingBox;
            rectangle('Position',[bb(1),bb(2),bb(3),bb(4)],'LineWidth',2,'EdgeColor','r');
            
            centro = rprop(k).Centroid;
            text(centro(1), centro(2),"*", 'FontSize',20,'Color','g');
            
            if centro(2)> limInf && centro(2)<limSup
                contFAct=contFAct+1;
            end
            
        end
    end
    if contFAnt > contFAct
        contFAnt=contFAct;
    end
    if contFAnt < contFAct
        cont=cont+1;
        contFAct=contFAct+1;
        contFAnt=contFAct;
    end
    if mod(n_frame, jump) == 0
        pause(0.2);
        disp(n_frame);
    end
end

waitfor(msgbox(['Se han encontrado ',num2str(cont),' baterias']))








function fondo = calcular_fondo(file)

video = VideoReader(file);

B0 = 0;
B1 = 0;
count = 0;
alpha = 0.05;
n_frames = 0;
while hasFrame(video)
    n_frames = n_frames + 1;
    frame = readFrame(video);
    if count ~= 0
        B_t = (1-alpha) * B_previo + alpha * frame_anterior;
    else
        B_t = frame;
        count = 1;
    end
    frame_anterior = frame;
    B_previo = B_t;
end
fondo = B_t;
f = figure;
imshow(fondo);
save('fondo.mat', 'fondo')
waitfor(f);
end


