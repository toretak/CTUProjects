clear;
clc;
close;
fig = 0; %pocatecni index grafu, vzdy uvadet fig+1
%Reseni rozmisteni svitidel pomoci genetickeho algoritmu. Urceno pro
%konferenci EPE2015. Skript slouzi k navrhu rozmisteni svitidel v okoli
%komunikace. Hledanymi parametry jsou presah roztec, svetelneho bodu, vyska
%svitidla nad komunikaci a naklon svitidla.
% DNA: DX, DY, Z, alfa
%Krizeni: jednobodove (udat pravdepodobnost)
                pop.kriz = 0.8;
%Mutace (pomerna hodnota):
                pop.mut = 0.05;
%Pocet generac�:
                pop.gen = 200;
%Velikost populace:
                pop.N = 100;
%Meze parametru (dano pozadavky na komunikaci):
                mez.min.DX = 0.5;%m
                mez.max.DX = 80;%m
                mez.min.DY = -0.5;%m presah mimo silnici je zaporny
                mez.max.DY = 0.5;%m presah do silnice je kladny
                mez.min.Z = 5;%m
                mez.max.Z = 15;%m
                mez.min.alfa = 0*pi/180;%rad
                mez.max.alfa = 20*pi/180;%rad
%Pocatecni historie:
                historie.fitness = zeros(pop.gen,1);
                historie.dna = zeros(pop.gen, 4);
%--------------------------------------------------------------------------
%POZADOVANE VYSLEDKY
                norma.Emin = 1.25;%lx
                norma.Eavg.min = 6.25;%lx
                norma.Eavg.max = 9.375;%lx
%--------------------------------------------------------------------------
%PARAMETRY SVITIDLA
                svt.I = load('F reflektor 1 patice 1.txt', '-ascii');
                [svt.B.N, svt.beta.N] = size(svt.I);
%pocatky uhlu
                svt.beta.Nula = -pi/2;
                svt.B.Nula = -pi;
%krok uhlu
                svt.beta.krok = pi/(svt.beta.N-1);% -90� az 90�
                svt.B.krok = 2*pi/(svt.B.N-1);% -180� az 180�
%--------------------------------------------------------------------------
%PARAMETRY KOMUNIKACE
%delka komunikace
                kom.delka = 200;%m
%sirka komunikace
                kom.sirka = 3;%m
%delka sledovaneho prostoru v pruseciku os komunikce
                kom.delPr = 80;%m
%vzdalenost paty svitidel od krajnice
                kom.yPata = 0;%m
%y offset komunikace (aby vsechny souradnice byly kladne)
                kom.yOffset = kom.yPata - mez.min.DY;
%pocet kontrolnich bodu v ose x a y ve sledovanem prostoru
                kom.Nx = 160;
                kom.Ny = 8;
%Generovani souradnic:
kom.bx = (kom.delka - kom.delPr)/2+((1:kom.Nx).*kom.delPr - kom.delPr/2)./kom.Nx;
kom.by = kom.yOffset +((1:kom.Ny).*kom.sirka - kom.sirka/2)./kom.Ny;

%--------------------------------------------------------------------------
%Pocatecni populace je nahodna:
pop.dna.DX = mez.min.DX + (mez.max.DX-mez.min.DX).*rand(pop.N, 1);
pop.dna.DY = mez.min.DY + (mez.max.DY-mez.min.DY).*rand(pop.N, 1);
pop.dna.Z = mez.min.Z + (mez.max.Z-mez.min.Z).*rand(pop.N, 1);
pop.dna.alfa = mez.min.alfa + (mez.max.alfa-mez.min.alfa).*rand(pop.N, 1);
%Cela dna
pop.dna.vse = [pop.dna.DX, pop.dna.DY, pop.dna.Z, pop.dna.alfa];

%--------------------------------------------------------------------------
%SMYCKA GENETICKEHO ALGORITMU
%--------------------------------------------------------------------------
for generace = 1:1:pop.gen
    %----------------------------------------------------------------------
    %pocatecni osvetlenost je nulova
    bod.E = zeros(pop.N,kom.Nx*kom.Ny);

    %Osvetlenost jednotlivych bodu srovnavaci roviny
    for i= 1:1:pop.N
        %1) Pozice svitidel v teto populaci
        %pocet svitidel na danem useku
        E.Ns = floor(kom.delka/pop.dna.DX(i));
        E.xs = (kom.delka - E.Ns * pop.dna.DX(i))/2 + (0:E.Ns)*pop.dna.DX(i);
        %souradnice svitidel se opakuji ve sloupcich matice
        E.mat.xs = E.xs' * ones(1, kom.Nx*kom.Ny);
        E.mat.ys = kom.yOffset - kom.yPata + pop.dna.DY(i) * ones(E.Ns+1, kom.Nx*kom.Ny);
        E.mat.zs = pop.dna.Z(i) * ones(E.Ns+1, kom.Nx*kom.Ny);
        E.mat.alfas = pop.dna.alfa(i) * ones(E.Ns+1, kom.Nx*kom.Ny);
        
        %2) Pozice bodu pro tuto populaci
        E.mat.xb = zeros(E.Ns+1, kom.Nx*kom.Ny);
        E.mat.yb = zeros(E.Ns+1, kom.Nx*kom.Ny);
        for j= 1:1:kom.Ny
            E.mat.xb(:, (((j-1)*kom.Nx)+1):((j*kom.Nx))) = ones(E.Ns+1, 1)*kom.bx;
            E.mat.yb(:, (((j-1)*kom.Nx)+1):((j*kom.Nx))) = kom.by(j) .* ones(E.Ns+1, kom.Nx);
        end
        
        %3) Charakteristiky potrebne pro urceni osvetlenosti (+eps kvuli deleni nulou!!!)
        E.mat.l = (((E.mat.xs-E.mat.xb).^2 + (E.mat.ys-E.mat.yb).^2 + E.mat.zs.^2)).^0.5 +eps;
        E.mat.sinB = (E.mat.yb - E.mat.ys)./ E.mat.l;
        E.mat.sinBeta = (E.mat.xs - E.mat.xb)./ E.mat.l; %Tady je to obracene
        %odklon paprsku plosky od normaly bodu dopadu je Theta
        E.mat.cosTheta = E.mat.zs./ E.mat.l;
        
        E.mat.B = asin(E.mat.sinB) - E.mat.alfas;%Tady ma byt myslim minus
        E.mat.beta = asin(E.mat.sinBeta);
        
        %4) Zjisteni svitivosti v danych uhlech
        E.mat.I = zeros(E.Ns+1, kom.Nx*kom.Ny);
        E.mat.indexIB = 1 + floor((E.mat.B - svt.B.Nula)/svt.B.krok);
        E.mat.indexIbeta = 1 + floor((E.mat.beta - svt.beta.Nula)/svt.beta.krok);
        for j = 1:1:E.Ns+1
            for k = 1:1:kom.Nx*kom.Ny
                E.mat.I(j,k) = svt.I(E.mat.indexIB(j,k), E.mat.indexIbeta(j,k));
            end
        end
        
        %5) Urceni vysledne osvetlenosti z prispevku vsech svitidel
        pop.E(i, :) = sum(E.mat.I .* E.mat.cosTheta./ (E.mat.l.^2));
    end
    
    %----------------------------------------------------------------------
    %Vypocet Fitness
    %Pocet bodu mezi dvema svitidly
    kom.Ns = floor(kom.Nx * pop.dna.DX/ kom.delPr);
    
    %Prumerna hodnota osvetlenosti v dane populaci
    pop.Eavg = zeros(pop.N, 1);
    for j= 1:1:pop.N
        kom.ME = vec2mat(pop.E(j,:),kom.Nx);
        pop.Eavg(j)= sum(sum(kom.ME(:, 1:kom.Ns(j))));
        pop.Eavg(j) = pop.Eavg(j)/ kom.Ny/ kom.Ns(j);
    end

%    pop.Eavg = sum(pop.E,2)/ kom.Nx/ kom.Ny;
    
    %Minimalni svitivost v danych populacich
    pop.Emin = min(pop.E,[],2);
    
    %Transformace (vahovani) prumerne a minimalni osvetlenosti
    pop.weight.Eavg = zeros(pop.N, 1);
    pop.weight.Emin = zeros(pop.N, 1);
    pop.weight.DX = (pop.dna.DX/mez.max.DX).^2;
    for j= 1:1:pop.N
        if pop.Eavg(j) > (norma.Eavg.min + norma.Eavg.max)/2
            pop.weight.Eavg(j) = exp(-(pop.Eavg(j) - (norma.Eavg.min + norma.Eavg.max)/2));
        else
            pop.weight.Eavg(j) = exp(pop.Eavg(j) - (norma.Eavg.min + norma.Eavg.max)/2);
        end;
        
        if pop.Emin(j) > 1.25
            pop.weight.Emin(j) = exp(-(pop.Emin(j) - norma.Emin)/10);
        else
            pop.weight.Emin(j) = exp((pop.Emin(j) - norma.Emin)*10);
        end;
    end
    pop.fitness = pop.weight.Eavg .* pop.weight.DX .* pop.weight.Emin + eps;
   
    %Pravdepodobnosti vyberu rodice
    pop.prVyb = pop.fitness ./ sum(pop.fitness);
    
    %======================================================================
    %MEZIVYSEDKY - zobrazeni
    %======================================================================
    %nejlepsi vysledek generace - fitness
    [PRAV, IDX]= max(pop.prVyb);
    fig= fig+1;
    figure(fig)
    subplot(2,2,1)
    %historie.fitness = [historie.fitness(2:pop.gen); pop.fitness(IDX)];
    historie.fitness(generace) = pop.fitness(IDX);
    plot(historie.fitness);
    title('Fitness nejlepsich jedincu');
    xlabel('historie (n)');
    ylabel('Fitness');
    grid on;
    
    %Zobrazeni nejlepsiho vysledku teto generace
    subplot(2,2,2)
    E.Ns = floor(kom.delka/pop.dna.DX(IDX));
    E.xs = (kom.delka - E.Ns * pop.dna.DX(IDX))/2 + (0:E.Ns)*pop.dna.DX(IDX);
    E.ys = (kom.yOffset - kom.yPata + pop.dna.DY(IDX))*ones(1,E.Ns+1);
    
    E.mat.xb = zeros(1, kom.Nx*kom.Ny);
    E.mat.yb = zeros(1, kom.Nx*kom.Ny);
    for j= 1:1:kom.Ny
        E.mat.xb((((j-1)*kom.Nx)+1):((j*kom.Nx))) = kom.bx;
        E.mat.yb((((j-1)*kom.Nx)+1):((j*kom.Nx))) = kom.by(j) .* ones(1, kom.Nx);
    end
    
    y = [kom.yOffset, kom.yOffset, kom.yOffset+kom.sirka, kom.yOffset+kom.sirka];
    x = [0, kom.delka, kom.delka, 0];
    fill(x,y,[0.8,0.8,0.8]);
    hold on;
    plot(E.mat.xb, E.mat.yb, '.');
    plot(E.xs, E.ys, 'o', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'y');
    title(sprintf('Nejlepsi jedinec, generace = %i, P_{vyberu}= %3.2f %%', generace, pop.prVyb(IDX)*100));
    grid on;
    axis([0 kom.delka 0 (2*kom.yOffset+ kom.sirka)]);
    xlabel('x (m)');
    ylabel('y (m)');
    hold off;
    clear x;
    clear y
    
    subplot(2,2,3)
    kom.ME = vec2mat(pop.E(IDX,:),kom.Nx);
    surf(kom.bx,kom.by,kom.ME);
    xlabel('x (m)');
    ylabel('y (m)');
    zlabel('E (lx)');
    
    subplot(2,2,4)
    plot(E.xs, E.ys, 'o', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'y');
    hold on;
    %plot(E.mat.xb, E.mat.yb, '.')
    pcolor(kom.bx,kom.by,kom.ME);
    hold off
    xlabel('x (m)');
    ylabel('y (m)');
    axis([(kom.delka/2 - kom.delPr/2) (kom.delka/2 + kom.delPr/2) 0 (2*kom.yOffset+ kom.sirka)]);
    
    fig = 0;
    %======================================================================
    
    historie.dna(generace, :)= pop.dna.vse(IDX, :);
    %----------------------------------------------------------------------
    %Vyber potomku, krizeni a mutace
    %Pokud se nejedna o posledni generaci, tak najit potomky
    if generace < pop.gen
        pop.dnaP = zeros(pop.N, 4);
        %------------------------------------------------------------------
        %ELITISMUS - vyber nejlepsiho clena populace na prvni misto
        %------------------------------------------------------------------
        pop.dnaP(1,:) = pop.dna.vse(IDX,:); %tento clen nebude mutovat
        pop.dnaP(2,:) = pop.dna.vse(IDX,:); %tento clen muze mutovat
        %------------------------------------------------------------------
        %KRIZENI - vyber rodicu a vytvareni potomku
        %------------------------------------------------------------------
        %opakovat hledani dokud nebude vytvorena nova populace velikosti N
        for clen = 3:2:pop.N %musi byt sudy pocet clenu
            %nahodne: vyber rodice1, vyber rodice2, index krizeni
            pravdepodobnost = rand(1,3);
            %Index prvniho rodice
            for i= 1:1:pop.N
                if pravdepodobnost(1) > 0
                    pop.i(1) = i;
                end
                pravdepodobnost(1)= pravdepodobnost(1)- pop.prVyb(i);
            end

            %Index druheho rodice
            for i= 1:1:pop.N
                if i~= pop.i(1)
                    if pravdepodobnost(2) > 0
                        pop.i(2) = i;
                    end
                    pravdepodobnost(2)= pravdepodobnost(2)- pop.prVyb(i);
                end
            end

            %Krizeni - podle indexu a dle pravdepodobnosti krizeni
            pop.i(3)= ceil(3*pravdepodobnost(3)/pop.kriz);
            if pop.i(3) >= 4 %zde nekrizit
                pop.dnaP(clen, :) = pop.dna.vse(pop.i(1), :);
                pop.dnaP(clen+1, :) = pop.dna.vse(pop.i(2), :);
            else %zde krizit
                pop.dnaP(clen, :) = [pop.dna.vse(pop.i(1), (1:pop.i(3))), pop.dna.vse(pop.i(2), (pop.i(3)+1):4)];
                pop.dnaP(clen+1, :) = [pop.dna.vse(pop.i(2), (1:pop.i(3))), pop.dna.vse(pop.i(1), (pop.i(3)+1):4)];
            end
        end

        %------------------------------------------------------------------
        %MUTACE potomku
        %------------------------------------------------------------------
        %generovani pravdepodobnosti mutaci pro kazdeho clena a jeho cast
        %DNA
        pravdepodobnost= rand(pop.N,4);
        for clen= 2:1:pop.N
            if pravdepodobnost(clen, 1) <= pop.mut
                pop.dnaP(clen, 1)= mez.min.DX + (mez.max.DX-mez.min.DX).*rand(1,1);
            end

            if pravdepodobnost(clen, 2) <= pop.mut
                pop.dnaP(clen, 2)= mez.min.DY + (mez.max.DY-mez.min.DY).*rand(1,1);
            end
            
            if pravdepodobnost(clen, 3) <= pop.mut
                pop.dnaP(clen, 3)= mez.min.Z + (mez.max.Z-mez.min.Z).*rand(1,1);
            end

            if pravdepodobnost(clen, 4) <= pop.mut
                pop.dnaP(clen, 4)= mez.min.alfa + (mez.max.alfa-mez.min.alfa).*rand(1,1);
            end
        end
        %------------------------------------------------------------------
        %NOVA GENERACE
        %------------------------------------------------------------------
        pop.dna.vse = pop.dnaP;
        pop.dna.DX = pop.dna.vse(:,1);
        pop.dna.DY = pop.dna.vse(:,2);
        pop.dna.Z = pop.dna.vse(:,3);
        pop.dna.alfa = pop.dna.vse(:,4);
    end
end;

disp(pop.dna.vse(IDX,:));
disp(pop.Eavg(IDX));
disp(pop.Emin(IDX));

clear i;
clear j;
clear k;
clear fig;
clear clen;
clear pravdepodobnost;