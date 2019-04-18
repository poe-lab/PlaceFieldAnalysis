function [] = PFAnalysis_LAST_RIGHT_freqnorm_debug()
PFAnalysisGUI();
end

function [] = PFAnalysisGUI()
% -------------------------------------------------------------------------

% GLOBAL VARIABLES

% -------------------------------------------------------------------------
UI.CurrCell = []; % structure, user input
UI.Sets = [];
G.nRadius = 1; % G = structure, general info, stays constant, nRadius is coherence radius
MT = []; % structure, mt data
% -------------------------------------------------------------------------

% FIGURE WINDOW

% -------------------------------------------------------------------------
ScreenSize = get(0,'ScreenSize');
window = figure(...
    'units','pixels',...
    'position',[(ScreenSize(3)-570)/2 (ScreenSize(4)-700)/2 570 700],...
    'menubar','none',...
    'name','Place Field Analysis',...
    'numbertitle','off',...
    'resize','off',...
    'WindowButtonUpFcn',@StopDrag);
SizeWindow = get(window,'Position');
wh = SizeWindow(4);
% -------------------------------------------------------------------------

% OPEN MT FILE MENU

% -------------------------------------------------------------------------
OpenMTFile = uimenu(...
    'Parent',window,...
    'Label','Open MT File(s)',...
    'Callback',@OpenMTFileCall);
% ------------------------------------
    function [] = OpenMTFileCall(varargin)
        % open standard open dialog box
        [Name,Path] = uigetfile('*.xls','Select lap file(s)','Multiselect','on');
        % if user selects a file
        if ~isnumeric(Name)
            % if user selects only one file, put name string into cell
            if ischar(Name), Name = {Name}; end
            
            % enter "Name" into UI structure
            UI.Name = Name;
            UI.Path = Path;
            G.numFiles = length(Name);
            G.LapStr = cell(G.numFiles,1);
            
            % get lap numbers from file names
            noLap = 100;
            for n = 1:G.numFiles
                ind = strfind(UI.Name{n},'Lap');
                if isempty(ind), ind = strfind(UI.Name{n},'lap'); end
                if ~isempty(ind)
                    G.LapNums(n,1) = str2double(UI.Name{n}(ind+3:ind+4));
                    if isnan(G.LapNums(n,1))
                        G.LapNums(n,1) = str2double(UI.Name{n}(ind+3));
                    end
                else
                    % if can't find "Lap" in filename, numbers from 100
                    noLap = noLap+1;
                    G.LapNums(n,1) = noLap;
                end                    
            end
            
            % sort file names by lap number
            G.LapNums(:,2) = 1:G.numFiles;
            G.LapNums = sortrows(G.LapNums,1);
            UI.Name = UI.Name(G.LapNums(:,2));
            G.LapNums(:,2) = [];
            
            for n = 1:G.numFiles
                G.LapStr(n,1) = {num2str(G.LapNums(n))};
            end
                     
            % import data
            [MT,G] = ImportPFAData(UI,G,MT);
            
            G.numCells = length(G.CellName);
            G.BinW = G.Bins(2);
            G.xTickInc = floor(length(G.Bins)/7)*G.BinW;
            G.sumTime = sum(G.Time,2);
            
            % set lap num list entries to lap strings
            set(LS.ListLaps,'String',G.LapStr);
            
            % set cell list entries to cell names
            set(CL.List,'String',G.CellName);
            UI.CellSel = 1:G.numCells;
        end
    end
% -------------------------------------------------------------------------

% AXES PANEL

% -------------------------------------------------------------------------
AP.Panel = uipanel(...
    'Parent',window,...
    'Units','pixels',...
    'BackgroundColor',[.8 .8 .8],...
    'BorderType','beveledout',...
    'Position',[10 wh-10-274 550 274]);
% -------------------------------------------------------------------------
% AXES
% ------------------------------------
% Display cell frequency data
% -------------------------------------------------------------------------
AP.Axes = axes(...
    'Parent',AP.Panel,...
    'Units','pixels',...
    'Position',[40 274-10-202 496 202],...
    'FontUnits','pixels',...
    'FontSize',10,...
    'XTick',[],'YTick',[],...
    'Box','off');
    function [] = FixAxes(varargin)
        % if the user has imported lap data
        if ~isempty(G);
            % set format
            freq = sprintf('%2.2g',AP.MaxFreq);
            freq = str2double(freq);
            % get threshold value
            thresh = get(AP.Threshold,'YData');
            thresh = str2double(sprintf('%2.2g',thresh(1)));
            yTick = unique(sortrows([1;thresh;freq]))';
            % set x- and y-tick vectors
            set(AP.Axes,...
                'XTick',[0,G.xTickInc:G.xTickInc:G.Bins(end)-G.xTickInc,G.Bins(end)],...
                'YTick',yTick,...
                'TickDir','out',...
                'TickLength',[0.005,0.005],...
                'Box','off',...
                'XLim',[G.Bins(1)-G.BinW/2,G.Bins(end)+G.BinW/2],...
                'YLim',[0,1.2*AP.MaxFreq]);
        end
    end
% -------------------------------------------------------------------------
% FREQUENCY PLOT
% ------------------------------------
% Plot frequency
% -------------------------------------------------------------------------
hold on;
% ------------------------------------
AP.Freq = bar(...
    1,1,1,...
    'Parent',AP.Axes,...
    'Visible','off');
% ------------------------------------
AP.Below = bar(...
    1,1,1,...
    'Parent',AP.Axes,...
    'Visible','off',...
    'EdgeColor',[0 0 0],...
    'FaceColor',[1 1/2 0]);
% ------------------------------------
AP.OneHz = line(...
    [1 1],[1 1],...
    'LineWidth',1,...
    'Color',[0 1 0],...
    'Visible','off');
% ------------------------------------
AP.Threshold = line(...
    [1 1],zeros(1,2)/0,...
    'LineWidth',1,...
    'Color',[1 1/2 0],...
    'Visible','off',...
    'ButtonDownFcn',@StartThreshDrag);
% ------------------------------------
    function [] = StartThreshDrag(varargin)
        set(window,'WindowButtonMotionFcn',@ThreshDrag);
    end
% ------------------------------------
    function [] = ThreshDrag(varargin)
        pt = get(AP.Axes,'CurrentPoint');
        pt = round(pt(3)*100/AP.MaxFreq);
        if pt < 0,pt = 0;end
        if pt > 100,pt = 100;end
        UI.Threshold = pt/100;
        
        pt = pt*AP.MaxFreq/100;
        set(AP.Threshold,'YData',pt*[1 1]);
        
        FreqBelow = get(AP.Freq,'YData');
        FreqBelow(FreqBelow > UI.Threshold*AP.MaxFreq) = 0;
        set(AP.Below,'YData',FreqBelow);
        Op.Data = get(Op.Table,'Data');
        Op.Data(5,2:end) = {str2double(sprintf('%1.0f',UI.Threshold*100))};
        set(Op.Table,'Data',Op.Data);
        FixAxes;
        % set table values
    end
% ------------------------------------
    function [] = StopDrag(varargin)
        set(window,'WindowButtonMotionFcn','');
    end
% ------------------------------------
AP.Occu = plot(...
    1,1,...
    'Parent',AP.Axes,...
    'Visible','off',...
    'Color',[1 0 0]);
% ------------------------------------
hold off;
set(AP.Axes,'XTick',[],'YTick',[]);
% -------------------------------------------------------------------------
% CYCLE LEFT PB
% ------------------------------------
% Cycles left through cell list
% -------------------------------------------------------------------------
AP.PBl = uicontrol(...
    'Parent',AP.Panel,...
    'Style','pushbutton',...
    'Units','pixels',...
    'position',[10 274-10-202-20-5-2-5-20 30 20],...
    'BackgroundColor',[.8 .8 .8],...
    'FontUnits','pixels',...
    'FontSize',10,...
    'FontWeight','bold',...
    'String','<<',...
    'Callback',@APBlCall);
% ------------------------------------
    function [] = APBlCall(varargin)
        % if a cell is selected
        if ~isempty(UI.CurrCell)
            % Curr cell = G.CellName index of current cell
            check = find(UI.CellSel == UI.CurrCell);
            if ~isempty(check)
                if check ~= 1
                    check = check-1;
                    UI.CurrCell = UI.CellSel(check);
                end
            else
                check = 1;
                UI.CurrCell = UI.CellSel(check);
            end
            % average frequancy = sum(spike count)/sum(time)
            RealFreq = sum(MT{UI.CurrCell}.SCReal,2)./G.sumTime;
            FreqSmooth = sum(MT{UI.CurrCell}.SC,2)./G.sumTime;
            %Freq = normalize_var(FreqSmooth, min(RealFreq), max(RealFreq));
     % Normalize to [0, 1]:
     m = min(FreqSmooth);
     range = max(FreqSmooth) - m;
     array = (FreqSmooth - m) / range;
     % Then scale to [x,y]:
     range2 = max(RealFreq) - min(RealFreq);
     Freq = (array*range2) + min(RealFreq);
          
     
            Occu = mean(G.Time,2);
            Label = [MT{UI.CurrCell}.CellName ' Aggregate Data'];
            [AP] = UpdateAxes(Freq,Occu,Label,AP,G,Op);
            set(CL.List,'Val',check);
            FixAxes;
        end
    end
% -------------------------------------------------------------------------
% CYCLE RIGHT PB
% ------------------------------------
% Cycles right through cell list
% -------------------------------------------------------------------------
AP.PBr = uicontrol(...
    'Parent',AP.Panel,...
    'Style','pushbutton',...
    'Units','pixels',...
    'position',[10+30+5 274-10-202-20-5-2-5-20 30 20],...
    'BackgroundColor',[.8 .8 .8],...
    'FontUnits','pixels',...
    'FontSize',10,...
    'FontWeight','bold',...
    'String','>>',...
    'Callback',@APBrCall);
% ------------------------------------
    function [] = APBrCall(varargin)
        if ~isempty(UI.CurrCell)
            % Curr cell = G.CellName index of current cell
            check = find(UI.CellSel == UI.CurrCell);
            if ~isempty(check)
                if check ~= length(UI.CellSel)
                    check = check+1;
                    UI.CurrCell = UI.CellSel(check);
                end
            else
                check = 1;
                UI.CurrCell = UI.CellSel(check);
            end
            
            RealFreq = sum(MT{UI.CurrCell}.SCReal,2)./G.sumTime;
            FreqSmooth = sum(MT{UI.CurrCell}.SC,2)./G.sumTime;
            %Freq = normalize_var(FreqSmooth, min(RealFreq), max(RealFreq));
            % Normalize to [0, 1]:
     m = min(FreqSmooth);
     range = max(FreqSmooth) - m;
     array = (FreqSmooth - m) / range;
     % Then scale to [x,y]:
     range2 = max(RealFreq) - min(RealFreq);
     Freq = (array*range2) + min(RealFreq);
            Occu = mean(G.Time,2);
            Label = [MT{UI.CurrCell}.CellName ' Aggregate Data'];
            [AP] = UpdateAxes(Freq,Occu,Label,AP,G,Op);
            set(CL.List,'Val',check);
            FixAxes;
        end
    end
% -------------------------------------------------------------------------
% AXES LABEL
% ------------------------------------
% Makes selected laps a set
% -------------------------------------------------------------------------
AP.Label = uicontrol(...
    'Parent',AP.Panel,...
    'Style','text',...
    'Units','pixels',...
    'position',[10+30+5+30+5 274-10-202-20-5-2-5-20 320 18],...
    'BackgroundColor',[.8 .8 .8],...
    'FontUnits','pixels',...
    'FontSize',12,...
    'HorizontalAlignment','left',...
    'FontWeight','bold',...
    'String','Empty Axes');
% ------------------------------------
AP.Line{1} = uipanel(...
    'Parent',AP.Panel,...
    'Units','pixels',...
    'position',[10 274-10-202-20-5-2 530 2],...
    'BackgroundColor',[.8 .8 .8],...
    'BorderType','beveledout');
% -------------------------------------------------------------------------

% CELL LIST (CL) PANEL

% -------------------------------------------------------------------------
CL.Panel = uipanel(...
    'Parent',window,...
    'Units','pixels',...
    'FontUnits','pixels',...
    'FontSize',12,...
    'FontWeight','bold',...
    'TitlePosition','lefttop',...
    'BackgroundColor',[.8 .8 .8],...
    'BorderType','beveledout',...
    'Position',[10 wh-10-274-10-175 190 175]);
% -------------------------------------------------------------------------
% CELL LIST
% ------------------------------------
% Displays cells
% -------------------------------------------------------------------------
CL.CellsContext = uicontextmenu(...
    'Parent',window);
% ------------------------------------
% Option to reset cell list
CL.CellsReset = uimenu(...
    'Parent',CL.CellsContext,...
    'Label','Reset',...
    'Callback',@CellsResetCall);
% ------------------------------------
    function [] = CellsResetCall(varargin)
        if ~isempty(G)
            set(CL.List,'String',G.CellName);
            UI.CellSel = 1:G.numCells;
        end
    end
% ------------------------------------
% Option to narrow list to specific cells
CL.CellsConfirm = uimenu(...
    'Parent',CL.CellsContext,...
    'Label','Confirm',...
    'Callback',@CellsConfirmCall);
% ------------------------------------
    function [] = CellsConfirmCall(varargin)
        if ~isempty(G)
            Choice = get(CL.List,{'String','Val'});
            if ~isempty(Choice{1})
                Choice{1} = Choice{1}(Choice{2});
                set(CL.List,'String',Choice{1},'Val',1:length(Choice{1}));
                
                % re-calculating UI.CellSel
                % UI.CellSel = G.CellName index of user selected cells
                numCellsSel = length(Choice{1});
                match = zeros(numCellsSel,1);
                for n = 1:numCellsSel
                    match(n) = find(strcmp(Choice{1}{n},G.CellName),1);
                end
                UI.CellSel = match;
            end
        end
    end
% ------------------------------------
% Option to delete specific cells
CL.CellsDelete = uimenu(...
    'Parent',CL.CellsContext,...
    'Label','Delete',...
    'Callback',@CellsDeleteCall);
% ------------------------------------
    function [] = CellsDeleteCall(varargin)
        if ~isempty(G)
            Choice = get(CL.List,{'String','Val'});
            if ~isempty(Choice{1})
                Choice{1}(Choice{2}) = [];
                if Choice{2}(1) ~= length(Choice{1})+1;
                    NewVal = Choice{2}(1);
                else
                    NewVal = length(Choice{1});
                end
                set(CL.List,'String',Choice{1},'Val',NewVal);
                
                % re-calculating UI.CellSel
                % UI.CellSel = G.CellName index of user selected cells
                numCellsSel = length(Choice{1});
                match = zeros(numCellsSel,1);
                for n = 1:numCellsSel
                    match(n) = find(strcmp(Choice{1}{n},G.CellName),1);
                end
                UI.CellSel = match;
            end
        end
    end
% ------------------------------------
CL.List = uicontrol(...
    'parent',CL.Panel,...
    'style','list',...
    'unit','pix',...
    'position',[10 10 190-20 175-20],...
    'BackgroundColor','white',...
    'FontUnits','pixels',...
    'String',{'Cell Names'},...
    'Min',0,'Max',100,...
    'fontsize',10,...
    'uicontextmenu',CL.CellsContext,...
    'Callback',@CLCellsCall);
% ------------------------------------
    function [] = CLCellsCall(varargin)
        if ~isempty(G)
            SelType = get(window,'SelectionType');
            if strcmp(SelType,'open') == 1
                Choice = get(CL.List,{'String','Val'});
                % Curr cell = G.CellName index of current cell
                CurrCell = Choice{1}(Choice{2});
                CurrCell = find(strcmp(G.CellName,CurrCell),1);
%                 Freq = mean(MT{CurrCell}.Freq,2);
                 %Freq = sum(MT{CurrCell}.SC,2)./G.sumTime;
                
                
            RealFreq = sum(MT{CurrCell}.SCReal,2)./G.sumTime;
            FreqSmooth = sum(MT{CurrCell}.SC,2)./G.sumTime;
            
%             %Freq = normalize_var(FreqSmooth, min(RealFreq), max(RealFreq));
     % Normalize to [0, 1]:
     m = min(FreqSmooth);
     range = max(FreqSmooth) - m;
     array = (FreqSmooth - m) / range;
     % Then scale to [x,y]:
     range2 = max(RealFreq) - min(RealFreq);
     Freq = (array*range2) + min(RealFreq);

                Occu = mean(G.Time,2);
                Label = [MT{CurrCell}.CellName ' Aggregate Data'];
                [AP] = UpdateAxes(Freq,Occu,Label,AP,G,Op);
                FixAxes;
                UI.CurrCell = CurrCell;
            end
        end
    end
% -------------------------------------------------------------------------

% LAP SET PANEL

% -------------------------------------------------------------------------
LS.Panel = uipanel(...
    'Parent',window,...
    'Units','pixels',...
    'FontUnits','pixels',...
    'FontSize',12,...
    'FontWeight','bold',...
    'TitlePosition','lefttop',...
    'BackgroundColor',[.8 .8 .8],...
    'BorderType','beveledout',...
    'Position',[10+190+10 wh-10-274-10-175 150 175]);
% -------------------------------------------------------------------------
% LAP NUMBER LIST
% ------------------------------------
% Displays lap numbers
% -------------------------------------------------------------------------
LS.ListLaps = uicontrol(...
    'parent',LS.Panel,...
    'style','list',...
    'unit','pix',...
    'position',[10 10 60 175-20],...
    'BackgroundColor','white',...
    'FontUnits','pixels',...
    'String',{'Laps'},...
    'Min',0,'Max',100,...
    'fontsize',10,...
    'Callback',@PlotLapCall);
% ------------------------------------
    function [] = PlotLapCall(varargin)
        if ~isempty(G)
            SelType = get(window,'SelectionType');
            if strcmp(SelType,'open') == 1
                if ~isempty(UI.CurrCell)
                    CurrLap = get(LS.ListLaps,'Val');
                    % Curr cell = G.CellName index of current cell
                    Freq = MT{UI.CurrCell}.Freq(:,CurrLap);
                    Occu = G.Time(:,CurrLap);
                    Label = [MT{UI.CurrCell}.CellName ' Lap ' G.LapStr{CurrLap}];
                    [AP] = UpdateAxes(Freq,Occu,Label,AP,G,Op);
                    FixAxes;
                end
            end
        end
    end
% -------------------------------------------------------------------------
% LAP SET (LS) LIST
% ------------------------------------
% Displays lap sets
% -------------------------------------------------------------------------
LS.SetsContext = uicontextmenu(...
    'Parent',window);
% ------------------------------------
LS.SetsReset = uimenu(...
    'Parent',LS.SetsContext,...
    'Label','Reset',...
    'Callback',@SetsResetCall);
% ------------------------------------
    function [] = SetsResetCall(varargin)
        UI.Sets = [];
        set(LS.ListSets,'String',{'Sets'});
    end
% ------------------------------------
LS.ListSets = uicontrol(...
    'parent',LS.Panel,...
    'style','list',...
    'unit','pix',...
    'position',[150-10-60 10 60 175-20-20-10],...
    'BackgroundColor','white',...
    'FontUnits','pixels',...
    'String',{'Sets'},...
    'Min',0,'Max',100,...
    'fontsize',10,...
    'uicontextmenu',LS.SetsContext,...
    'Callback',@PlotSetCall);
% ------------------------------------
    function [] = PlotSetCall(varargin)
        if ~isempty(UI.Sets)
            SelType = get(window,'SelectionType');
            if strcmp(SelType,'open') == 1
                if ~isempty(UI.CurrCell)
                    CurrSet = get(LS.ListSets,'Val');
                    SetStr = LS.SetStr{CurrSet};
                    Set = UI.Sets{CurrSet};
                    %Freq = mean(MT{UI.CurrCell}.Freq,2);
           
            RealFreq = sum(MT{UI.CurrCell}.SCReal,2)./G.sumTime;
            FreqSmooth = sum(MT{UI.CurrCell}.SC,2)./G.sumTime;
            %Freq = normalize_var(FreqSmooth, min(RealFreq), max(RealFreq));
     % Normalize to [0, 1]:
     m = min(FreqSmooth);
     range = max(FreqSmooth) - m;
     array = (FreqSmooth - m) / range;
     % Then scale to [x,y]:
     range2 = max(RealFreq) - min(RealFreq);
     Freq = (array*range2) + min(RealFreq);
     
%             RealFreq = sum(MT{UI.CurrCell}.SCReal,2)./G.sumTime;
%             FreqSmooth = sum(MT{UI.CurrCell}.SC,2)./G.sumTime;
%             Freq = normalize_var(FreqSmooth, min(RealFreq), max(RealFreq));
                    
                    Occu = mean(G.Time(:,Set),2);
                    Label = [MT{UI.CurrCell}.CellName ' Laps ' SetStr];
                    [AP] = UpdateAxes(Freq,Occu,Label,AP,G,Op);
                    FixAxes;
                end
            end
        end
    end
% -------------------------------------------------------------------------
% LAP SET PUSH BUTTON
% ------------------------------------
% Makes selected laps a set
% -------------------------------------------------------------------------
LS.PB = uicontrol(...
    'Parent',LS.Panel,...
    'Style','pushbutton',...
    'Units','pixels',...
    'position',[150-10-60 175-10-20 60 20],...
    'BackgroundColor',[.8 .8 .8],...
    'FontUnits','pixels',...
    'FontSize',10,...
    'FontWeight','bold',...
    'String','>>',...
    'Callback',@LSPBCall);
% ------------------------------------
    function [] = LSPBCall(varargin)
        if ~isempty(G)
            LapSel = get(LS.ListLaps,'Val');
            SetStr = [num2str(G.LapNums(LapSel(1))) '-' num2str(G.LapNums(LapSel(end)))];
            LS.SetStr = get(LS.ListSets,'String');

            if isempty(find(strcmp(LS.SetStr,'Sets'),1))
                UI.Sets{end+1} = LapSel;

                LS.SetStr(end+1) = {SetStr};
                set(LS.ListSets,'String',LS.SetStr);
            else
                UI.Sets{1} = LapSel;

                LS.SetStr = {SetStr};
                set(LS.ListSets,'String',LS.SetStr);
            end
        end
    end
% -------------------------------------------------------------------------

% OPTIONS PANEL

% -------------------------------------------------------------------------
Op.Panel = uipanel(...
    'Parent',window,...
    'Units','pixels',...
    'BackgroundColor',[.8 .8 .8],...
    'BorderType','beveledout',...
    'Position',[10+190+10+150+10 wh-10-274-10-175 190 175]);
% -------------------------------------------------------------------------
Op.RowLabel = {...
    'Max Width';...
    'Min Width 1';...
    'Min Width 2';...
    'Max Gap';...
    'Threshold'};
temp = get(Op.Panel,'Position');
Op.Width = temp(3)-20-58-2;
clear temp;
Op.numVars = length(Op.RowLabel);
Op.Data = Op.RowLabel;
Op.Defaults = [290;6;15;20;30];
Op.Data(:,end+1) = num2cell(Op.Defaults);
Op.numCols = length(Op.Data(1,:))-1;
Op.Editable = [false true];
Op.Table = uitable(...
    'Parent',Op.Panel,...
    'Units','Pixels',...
    'Position',[10 175-10-86.75 170 86.75],...
    'RowName',[],...
    'ColumnName',[],...
    'ColumnEditable',Op.Editable,...
    'ColumnWidth',{58,Op.Width/Op.numCols},...
    'BackgroundColor',[1 1 1],...
    'CellEditCallback',@FixParameters,...
    'Data',Op.Data);
    function [] = FixParameters(varargin)
        ind = varargin{2}.Indices;
        data = varargin{2}.NewData;
        if ~isnan(data)
            if data < 0
                data = 0;
            end
            
            if ind < 5
                if data > 297
                    data = 297;
                end
            else
                if data > 100
                    data = 100;
                end
            end
        else
            data = varargin{2}.PreviousData;
        end
        Op.Data = get(Op.Table,'Data');
        Op.Data(ind(1),ind(2)) = {data};
        set(Op.Table,'Data',Op.Data);            
    end
Op.Add = uicontrol(...
    'Parent',Op.Panel,...
    'Style','pushbutton',...
    'Units','pixels',...
    'FontUnits','pixels',...
    'FontSize',10,...
    'FontWeight','normal',...
    'BackgroundColor',[.8 .8 .8],...
    'String','Add',...
    'Position',[10 175-10-86.7-5-20 82.5 20],...
    'Callback',@OpAddCall);
    function [] = OpAddCall(varargin)
        if Op.numCols < 5
            Op.Data = get(Op.Table,'Data');
            Op.Data(:,end+1) = Op.Data(:,end);
            set(Op.Table,'Data',Op.Data);
            Op.numCols = Op.numCols+1;
            colWidth = get(Op.Table,'ColumnWidth');
            colWidth(2:end+1) = {Op.Width/Op.numCols};
            set(Op.Table,'ColumnWidth',colWidth);
            Op.Editable = get(Op.Table,'ColumnEditable');
            Op.Editable(end+1) = true;
            set(Op.Table,'ColumnEditable',Op.Editable);
        end
    end
Op.Delete = uicontrol(...
    'Parent',Op.Panel,...
    'Style','pushbutton',...
    'Units','pixels',...
    'FontUnits','pixels',...
    'FontWeight','normal',...
    'FontSize',10,...
    'BackgroundColor',[.8 .8 .8],...
    'String','Delete',...
    'Position',[10+82.5+5 175-10-86.7-5-20 82.5 20],...
    'Callback',@OpDeleteCall);
    function [] = OpDeleteCall(varargin)
        if Op.numCols > 1
            Op.Data = get(Op.Table,'Data');
            Op.Data(:,end) = [];
            set(Op.Table,'Data',Op.Data);
            Op.numCols = Op.numCols-1;
            colWidth = get(Op.Table,'ColumnWidth');
            colWidth(2:end) = {Op.Width/Op.numCols};
            set(Op.Table,'ColumnWidth',colWidth);
            Op.Editable = get(Op.Table,'ColumnEditable');
            Op.Editable(end) = [];
            set(Op.Table,'ColumnEditable',Op.Editable);
        end
    end
Op.IndPFSheets = uicontrol(...
    'Parent',Op.Panel,...
    'Style','checkbox',...
    'Units','pixels',...
    'FontUnits','pixels',...
    'FontSize',10,...
    'BackgroundColor',[.8 .8 .8],...
    'String','Individual PF sheets',...
    'Position',[10 175-10-86.7-5-20-3-17 190-20 17]);
Op.coherenceNeighborsLineSep = uipanel(...
    'Parent',Op.Panel,...
    'Units','pixels',...
    'BackgroundColor',[.8 .8 .8],...
    'BorderType','beveledout',...
    'Position',[10 175-10-86.7-5-20-3-17-3-2 190-20 2]);
Op.coherenceNeighborsText = uicontrol(...
    'Parent',Op.Panel,...
    'Style','text',...
    'FontUnits','pixels',...
    'FontSize',10,...
    'HorizontalAlignment','left',...
    'BackgroundColor',[.8,.8,.8],...
    'String','Coherence Radius',...
    'Position',[10 175-10-86.7-5-20-3-17-3-2-3-17 190-20 17]);
Op.coherenceNeighborsEdit = uicontrol(...
    'Parent',Op.Panel,...
    'Style','edit',...
    'FontUnits','pixels',...
    'FontSize',10,...
    'BackgroundColor','white',...
    'String','1',...
    'Position',[190-10-11-27 175-10-86.7-5-20-3-17-3-2-3-17 27 17],...
    'Callback',@coherenceNeighborsEditCall);
    function [] = coherenceNeighborsEditCall(varargin)
        t = str2double(get(Op.coherenceNeighborsEdit,'String'));
        if isnan(t), t = 1;
        else
            t = round(t);
            if t < 0, t = 1; end
            if t > 10, t = 10; end
        end
        set(Op.coherenceNeighborsEdit,'String',num2str(t));
        G.nRadius = t;
    end
Op.coherenceNeighborsSlider = uicontrol(...
    'Parent',Op.Panel,...
    'Style','slide',...
    'Units','pixels',...
    'BackgroundColor','white',...
    'ForegroundColor','white',...
    'Position',[190-10-11 175-10-86.7-5-20-3-17-3-2-3-17 11 17]);
% -------------------------------------------------------------------------

% RUN

% -------------------------------------------------------------------------
Run = uicontrol(...
    'Parent',window,...
    'Units','pixels',...
    'Style','pushbutton',...
    'String','Run',...
    'BackgroundColor',[.8 .8 .8],...
    'FontUnits','pixels',...
    'FontWeight','bold',...
    'FontSize',12,...
    'Position',[10+190+10+150+10 wh-10-274-10-175-10-20 190 20],...
    'Callback',@RunPFAnalysis);
    function [] = RunPFAnalysis(varargin)
        if ~isempty(UI.Sets)
            % number of lap sets user created
            UI.numSets = length(UI.Sets);
            % options data
            Op.Data = get(Op.Table,'Data');
            % "Para" = parameters, excludes the row headings
            Para = cell2mat(Op.Data(:,2:end));
            % "I" is the "input" structure
            I = cell(UI.numSets,1);
            for m = 1:UI.numSets
                % get the current cell selection
                tempSel = UI.CellSel;
                % "ICName" = "inactive cell names"
                ICName = [];
                % for each set of paramters
                for n = 1:Op.numCols
                    I{n}.Laps = UI.Sets{m};
                    I{n}.SetStr = LS.SetStr{m};
                    I{n}.MaxW = Para(1,n);
                    I{n}.MinW1 = Para(2,n);
                    I{n}.MinW2 = Para(3,n);
                    I{n}.MaxGap = Para(4,n);
                    I{n}.Threshold = Para(5,n)/100;
                    % if this is the last set of paramters
                    if n == Op.numCols
                        % print to excel
                        I{n}.print = true;
                        I{n}.IndPFSheets = get(Op.IndPFSheets,'Val');
                    else
                        % don't print
                        I{n}.print = false;
                        I{n}.IndPFSheets = false;
                    end
                    % only gather stats if last set of filtering,
                    % otherwise return index of cells that did not make it
                    % through the filtering, add to the end of the longer 1
                    ICName = PFAnalysisRun(I{n},MT(tempSel),G,ICName,Op.Data);
                    numIC = length(ICName); % num inactive cells
                    % search the current cell selection for inactive cells,
                    % exclude them from next round of analysis
                    for k = 1:numIC
                        match = find(strcmp(ICName{k},G.CellName),1);
                        if ~isempty(match),tempSel(tempSel == match) = [];end
                    end
                end
            end
        end
    end
end




function [AP] = UpdateAxes(Freq,Occu,Label,AP,G,Op)
MaxFreq = max(Freq);
MaxOccu = max(Occu);
Occu = (Occu*MaxFreq)/MaxOccu;
set(AP.Freq,'XData',G.Bins,'YData',Freq);
set(AP.Occu,'XData',G.Bins,'YData',Occu);

set(AP.Freq,'Visible','on');
set(AP.Occu,'Visible','on');
set(AP.OneHz,'Visible','on');
set(AP.Below,'Visible','on');
set(AP.Threshold,'Visible','on');

set(AP.Label,'String',Label);
set(AP.Axes,'YLim',[0,MaxFreq*1.2]);
set(AP.OneHz,'YData',[1 1],'XData',[G.Bins(1)-G.BinW/2,G.Bins(end)+G.BinW/2]);

Threshold = MaxFreq*Op.Data{5,2}/100;

set(AP.Threshold,'YData',[Threshold,Threshold],'XData',[G.Bins(1)-G.BinW/2,G.Bins(end)+G.BinW/2]);

FreqBelow = Freq;
FreqBelow(FreqBelow > Threshold) = 0;
set(AP.Below,'XData',G.Bins,'YData',FreqBelow);

AP.MaxFreq = MaxFreq;
end





% ImportData
% -------------------------------------------------------------------------
function [MT,G] = ImportPFAData(UI,G,MT)
FileName = UI.Name;
Path = UI.Path;

excelObj = actxserver('Excel.Application');
for n = 1:G.numFiles;
    excelWorkbook = excelObj.workbooks.Open([Path filesep FileName{n}]);
    worksheets = excelObj.sheets;
    numSheets = worksheets.Count;
    SheetIndex = 1;
    m = 0;
    while SheetIndex <= numSheets
        SheetName = worksheets.Item(SheetIndex).Name;
        if strncmp(SheetName,'Sheet',5) == 0 && strcmp(SheetName,'TS & Bin') == 0
            m = m + 1;
            WorkSheet = excelWorkbook.Sheets.Item(SheetIndex);
            invoke(WorkSheet,'Activate');
            DataRange = excelObj.ActiveSheet.UsedRange;
            temp = cell2mat(DataRange.Value);
            if n == 1
                MT{m,1}.CellName = SheetName;
                G.CellName{m,1} = SheetName;
            end
            if n == 1 && m == 1, G.Bins = temp(:,1); end % bins
            if m == 1, G.Time(:,n) = temp(:,2); end % time
            MT{m,1}.Freq(:,n) = temp(:,4); % frequency
            MT{m,1}.SC(:,n) = temp(:,3); % spike count smoothed
            MT{m,1}.SCReal(:,n) = temp(:,5); % spike count
            SheetIndex = SheetIndex + 1;
        else
            SheetIndex = SheetIndex + 1;
        end
    end
    excelWorkbook.Close;
end
excelObj.Quit; delete(excelObj);

end
% -------------------------------------------------------------------------




% -------------------------------------------------------------------------
% PF ANALYSIS RUN
% -------------------------------------------------------------------------
function [ICName] = PFAnalysisRun(UI,D,G,ICName,Settings)

% Members of UI (user input)
% UI.MaxW
% UI.MinW1
% UI.MinW2
% UI.MaxGap
% UI.Threshold
% UI.Laps
% UI.Path
% UI.Filename
% UI.CellSelect

% D is a cell of structures, one structure per tetrode cell
% Members of D (data) from ImportPFAData:
% D.SC
% D.Freq
% D.CellName

% G is a structure containing data constant from cell to cell
% Members of G (general):
% G.Bins
% G.Time
% G.LapNums
% G.BinW
% G.MaxW
% G.MaxGap
% G.MinW1
% G.MinW2
% G.Laps
% G.TimeSum
% G.Threshold
% G.nRadius

% Members of PF:
% PF.Bnds
% PF.LapsAct
% PF.Freq
% PF.Size (in bins)
% PF.Name
% PF.ShiftB
% PF.ShiftR

% convert user input values (UI, in cm) to bin values
G.BinW = G.Bins(2);
G.numBins = length(G.Bins);
G.MaxW = floor(UI.MaxW/G.BinW);
G.MaxGap = floor(UI.MaxGap/G.BinW);
G.MinW1 = floor(UI.MinW1/G.BinW);
G.MinW2 = floor(UI.MinW2/G.BinW);
G.Threshold = UI.Threshold;
G.numIC = length(ICName);

% G.Laps is in index of laps rather than the lap numbers themselves
G.Laps = [UI.Laps(1),UI.Laps(end)];
G.LapNums = G.LapNums(G.Laps(1):G.Laps(end));
G.numLaps = length(G.LapNums);

% D.TimeSum is sum of time spent in each bin over however many laps
G.TimeSum = sum(G.Time(:,G.Laps(1):G.Laps(end)),2);

G.numCells = length(D);
% ACc = active cell count
% ICc = inactive cell count
ACc = 0;
ICc = 0;
for m = 1:G.numCells
    temp = FindPFs(D{m},G);
    if ~isempty(temp)
        ACc = ACc + 1;
        if ACc == 1
            PF = temp;
        else
            PF(end+1:length(PF)+length(temp)) = temp;
        end
    else
        ICc = ICc + 1;
        ICName{ICc+G.numIC+1} = D{m}.CellName;
    end
end

if UI.print
    tic;
    if exist('PF','var')
        G.numPFs = length(PF);
        if UI.IndPFSheets
            IndPFSheet = cell(G.numPFs,1);
            IndPFSheetName = IndPFSheet;
        end
        Blank = zeros(G.numLaps,G.numPFs)/0;
        O.CofM = Blank; O.AvgFnz = Blank; O.AvgFaf = Blank; O.Size = Blank; O.rAvgAll = Blank; O.rAvg5L = Blank; O.Velocity = Blank; O.Info = Blank;
        Blank = zeros(G.numLaps-1,G.numPFs)/0;
        O.ShiftRPL = Blank; O.ShiftROP = Blank; O.ShiftAbs = Blank; O.ShiftCofM = Blank; O.ShiftCofMAbs = Blank; O.rRPL = Blank;
        for m = 1:G.numPFs       
            % Correlation adds PF.r, PF.ShiftB, and PF.ShiftR
            PF{m} = Correlation(PF{m},G);
            % CenterOfMass adds PF.CofM, PF.ShiftCofM
            PF{m} = CenterOfMass(PF{m},G);
            % AverageFrequency adds PF.AvgFnz and PF.AvgFaf
            PF{m} = AverageFrequency(PF{m});
            % Information per spike
            PF{m} = InfoPerSpike(PF{m});
            % Velocity
            PF{m} = Velocity(PF{m},G);
            % Calculate coherence
            PF{m} = Coherence(PF{m},G);
            % Relative adds PF.ShiftRPL, PF.ShiftROP, PF.ShiftAbs, PF.CorrRPL           
            PF{m} = OtherStats(PF{m});
            % Correction to LA (Laps Active) to make first lapnum "1"
            LA = PF{m}.LapsAct; %-G.LapNums(1)+1;
            
            % "O" contains overall stats, printed on the compiled data
            % sheet
            O.Velocity(LA,m) = PF{m}.Velocity;
            O.numLapsAct(1,m) = PF{m}.numLaps;
            O.CofM(LA,m) = PF{m}.CofM;
            O.AvgFnz(LA,m) = PF{m}.AvgFnz;
            O.AvgFaf(LA,m) = PF{m}.AvgFaf;
            O.Size(LA,m) = PF{m}.Size*G.BinW;
            O.rAvgAll(LA,m) = PF{m}.rAvgAll;
            O.rAvg5L(LA,m) = PF{m}.rAvg5L;
            O.Info(LA,m) = PF{m}.I;
            O.Coherence(:,m) = PF{m}.Coherence;

            O.ShiftRPL(LA(1:end-1),m) = PF{m}.ShiftRPL;
            O.ShiftROP(LA(1:end-1),m) = PF{m}.ShiftROP;
            O.ShiftAbs(LA(1:end-1),m) = PF{m}.ShiftAbs;
            O.ShiftCofM(LA(1:end-1),m) = PF{m}.ShiftCofM;
            O.ShiftCofMAbs(LA(1:end-1),m) = PF{m}.ShiftCofMAbs;
            O.rRPL(LA(1:end-1),m) = PF{m}.rRPL;

            if UI.IndPFSheets
                IndPFSheet{m} = WritePFSheet(PF{m},G);
                IndPFSheetName{m} = PF{m}.Name;
            end
            G.PFName{m} = PF{m}.Name;
        end
        % Overlap in bins, overlap in percent
        O = PFOverlap(PF,G,O);
        O = numPFsPerCell(G,O);

        % write compiled data sheet
        CompSheet{1,1} = WriteCompiledSheet(O,G);
        CompSheetName{1,1} = 'Compiled Data';
        % write inactive cell sheet
        CompSheetName{2,1} = 'Settings & Inactive Cells';
        if ~isempty(ICName)
            CompSheet{2,1} = Settings;
            CompSheet{2,1}(end+1:length(ICName)+5,1) = ICName;
        else
            CompSheet{2,1} = Settings;
            CompSheet{2,1}(end+2,1) = {'None'};
        end
        
        if UI.IndPFSheets
            Sheet = [CompSheet;IndPFSheet];
            SheetName = [CompSheetName;IndPFSheetName];
        else
            Sheet = CompSheet;
            SheetName = CompSheetName;
        end
    else
        SheetName{1} = 'Settings & Inactive Cells';
        if ~isempty(ICName)
            Sheet{1} = Settings;
            Sheet{1}(end+1:length(ICName)+5,1) = ICName;
        else
            Sheet{1} = Settings;
            Sheet{1}(end+2,1) = {'None'};
        end
    end
    toc;
    WritePFOutputToExcel(SheetName,Sheet,UI);
    
end

end
% -------------------------------------------------------------------------




function [O] = numPFsPerCell(G,O)
k = 0;
for m = 1:length(G.CellName)
    test = strncmp(G.PFName,G.CellName{m},length(G.CellName{m}));
    sumTest = sum(test);
    if sumTest~=0
        k = k + 1;
        O.numPFsPerCell{k,1} = G.CellName{m};
        O.numPFsPerCell{k,2} = sum(test);
    end
end
end




function [PF] = FindPFs(D,G)

% does it meet aggregate PF definition criteria?
% -------------------------------------------------------------------------
% SCSum = spike count sum
SCSum = sum(D.SC(:,G.Laps(1):G.Laps(end)),2);
FreqSmooth = SCSum./G.TimeSum;
% AggFreq = aggregate frequency
%FreqAgg = mean(D.Freq,2); %
SCSumReal = sum(D.SCReal(:,G.Laps(1):G.Laps(end)),2);
FreqAggReal = SCSumReal./G.TimeSum;
%FreqAgg = normalize_var(FreqSmooth, min(FreqAggReal), max(FreqAggReal));
 
% Normalize to [0, 1]:
     m = min(FreqSmooth);
     range = max(FreqSmooth) - m;
     array = (FreqSmooth - m) / range;
% Then scale to [x,y]:
     range2 = max(FreqAggReal) - min(FreqAggReal);
     FreqAgg = (array*range2) + min(FreqAggReal);
     
% double FreqAgg to find PFs that cross lap-line
FreqAgg = [FreqAgg;FreqAgg];
% FreqMax = frequency maximum
% FreqAggForMax = SCSum./G.TimeSum;
% FreqAggMaxRaw = max(FreqAggForMax);
FreqMax = max(FreqAgg);
% c = active cell counter

if FreqMax > 1
    % ActBins = active bins (those above threshold)
    ActBins = find(FreqAgg >=FreqMax*G.Threshold);
    % ActBinsDiff = number of bins between active bins
    ActBinsDiff = diff(ActBins);
    PFend = [find(ActBinsDiff > G.MaxGap),ActBins(ActBinsDiff > G.MaxGap)];
    PFstrt = [1,ActBins(1)];
    PFstrt(2:length(PFend(:,1))+1,:) = [PFend(:,1)+1,ActBins(PFend(:,1)+1)];
    PFend(end+1,:) = [length(ActBins),ActBins(end)];
    
    % PFBnds = place field boundaries
    PFBnds = [PFstrt(:,2),PFend(:,2)];

    % kill repeated place fields (those that result from doubling the frequency
    % data to find PFs that cross the lap-line
    PFBnds(PFBnds(:,1) > G.numBins,:) = [];

    % get place field width
    Width = PFBnds(:,2) - PFBnds(:,1) + 1;

    % kill place fields of > MaxW and < MinW1
    delete = [find(Width > G.MaxW); find(Width < G.MinW1)];
    PFBnds(delete,:) = [];

    % fix indexes of PFs that cross the lap-line
    check = find(PFBnds(:,2) > G.numBins);
    if ~isempty(check)
        PFBnds(check,2) = PFBnds(check,2)-G.numBins;
        PFBnds(1,:) = [];
    end
else
    PFBnds = [];
end

% does it meet active lap criteria?
% -------------------------------------------------------------------------
PF = [];
Blank = zeros(G.numBins,1);
if ~isempty(PFBnds)
    numPFs = length(PFBnds(:,1));
    % PFc = active PF count
    PFc = 0;
    for m = 1:numPFs
        temp = [];
        % s = start, e = end
        s = PFBnds(m,1); e = PFBnds(m,2);
        if s <= e
            SizeAgg = e-s+1;
        else
            SizeAgg = G.numBins-s+1+e;
        end 
        % ALc = active lap count
        ALc = 0;
        LapInd = 0;
        for n = G.Laps(1):G.Laps(end)
            LapInd = LapInd+1;
            % check for lap-line cross
            if s <= e
                FreqLap = D.Freq(s:e,n);
                SCLap = D.SC(s:e,n);
                TimeLap = G.Time(s:e,n);
                FreqLapForMax = SCLap./TimeLap;
            else
                FreqLap = [D.Freq(s:end,n);D.Freq(1:e,n)];
                SCLap = [D.SC(s:end,n);D.SC(1:e,n)];
                TimeLap = [G.Time(s:end,n);G.Time(1:e,n)];
                
                FreqLapForMax = SCLap./TimeLap;
            end
           
            FreqMaxRaw = max(FreqLapForMax);
            FreqMax = max(FreqLap);
            % check for frequencies > 1.0 Hz
            if FreqMaxRaw > 1.0
                % find active bins
                ActBins = find(FreqLap > FreqMax*G.Threshold);
                % check that it meets MinWidth criteria
                Width = ActBins(end)-ActBins(1)+1;
                if Width > G.MinW2
                    ALc = ALc + 1;
                    temp.Freq(:,ALc) = Blank;
                    temp.BndsLap(ALc,:) = [ActBins(1),ActBins(end)];
                    if s <= e
                        temp.Freq(s:e,ALc) = FreqLap;
                    else
                        temp.Freq(s:end,ALc) = FreqLap(1:end-e);
                        temp.Freq(1:e,ALc) = FreqLap(end-e+1:end);
                    end
                    temp.SC(:,ALc) = SCLap;
                    temp.IsoFreq(:,ALc) = FreqLap;
                    temp.Size(ALc,1) = Width;
                    temp.LapsAct(ALc,1) = LapInd;
                end
            end
        end
        if ~isempty(temp)
            % are there more than two active laps?
            if ALc > 1
                PFc = PFc + 1;
                PF{PFc,1} = temp;
                PF{PFc}.Name = [D.CellName '_PF' num2str(PFc)];
                PF{PFc}.Bnds = PFBnds(m,:);
                PF{PFc}.SizeAgg = SizeAgg;
                PF{PFc}.numLaps = length(PF{PFc}.LapsAct);
                if PF{PFc}.Bnds(1) < PF{PFc}.Bnds(2)
                    PF{PFc}.Time = G.Time(PF{PFc}.Bnds(1):PF{PFc}.Bnds(2),PF{PFc}.LapsAct);
                else
                    PF{PFc}.Time = [G.Time(PF{PFc}.Bnds(1):end,PF{PFc}.LapsAct);G.Time(1:PF{PFc}.Bnds(2),PF{PFc}.LapsAct)];
                end
            end
        end
    end
end
end
% -------------------------------------------------------------------------





% Correlation
% -------------------------------------------------------------------------
function [PF] = Correlation(PF,G)
for i = 1:PF.numLaps
    x = PF.Freq(:,i);
    for j = 1:PF.numLaps
        y = PF.Freq(:,j);
        yShifted = zeros(G.numBins,G.numBins);
        for h = 1:G.numBins
            % shift forward by 1 bin
            yShifted(:,h) = [y(end-h+1:end);y(1:end-h)];
        end
        r = corrcoef([x,y,yShifted]);
        PF.r(j,i) = r(2,1);
        % find max correlation
        rIndMax = find(r == max(r(2:end,1)),1);
        if ~isempty(rIndMax)
            % ShiftB = bins shifted at max corr
            PF.ShiftB(j,i) = rIndMax-1;
            % ShiftR = max corr
            PF.ShiftR(j,i) = r(rIndMax);
        end
    end
end
PF.ShiftB(PF.ShiftB > G.numBins/2) = PF.ShiftB(PF.ShiftB > G.numBins/2)-G.numBins;
end
% -------------------------------------------------------------------------
function [r] = Pearson(x,y)
r = corrcoef(x,y);
r = r(2);
r(isnan(r)) = 0;
end
% -------------------------------------------------------------------------





% Center Of Mass
% -------------------------------------------------------------------------
function [PF] = CenterOfMass(PF,G)
s = PF.Bnds(1);
Weight = bsxfun(@times,PF.IsoFreq,(G.Bins(s):G.BinW:(PF.SizeAgg-1)*G.BinW+G.Bins(s))');
temp = (sum(Weight)./sum(PF.Freq))';
PF.CofM = temp;
% PF.CofM(PF.CofM > G.Bins(end)) = PF.CofM(PF.CofM > G.Bins(end)) - G.Bins(end);
PF.ShiftCofM = temp-temp(1);
PF.ShiftCofM(PF.ShiftCofM > G.Bins(end)/2) = PF.ShiftCofM(PF.ShiftCofM > G.Bins(end)/2)-G.Bins(end);
PF.ShiftCofM(PF.ShiftCofM < -G.Bins(end)/2) = PF.ShiftCofM(PF.ShiftCofM < -G.Bins(end)/2)+G.Bins(end);
PF.ShiftCofM = PF.ShiftCofM(2:end);
PF.ShiftCofMAbs = abs(diff(temp));
end
% -------------------------------------------------------------------------




% Average Frequency
% -------------------------------------------------------------------------
function [PF] = AverageFrequency(PF)
for m = 1:PF.numLaps
    nonZero = PF.IsoFreq(:,m);
    PF.AvgFnz(m,1) = mean(nonZero(nonZero > 0));
end
PF.AvgFaf = mean(PF.IsoFreq)';
end
% -------------------------------------------------------------------------




% Information Per Spike (Spatial Information)
% -------------------------------------------------------------------------
function [PF] = InfoPerSpike(PF)
TimeData = PF.Time;
Ri = PF.IsoFreq;

R = mean(Ri);
sumTime = sum(TimeData);

Pi = bsxfun(@rdivide,TimeData,sumTime);
RiOverR = bsxfun(@rdivide,Ri,R);

temp = bsxfun(@times,bsxfun(@times,Pi,RiOverR),log2(RiOverR));
temp(isnan(temp)) = 0;

PF.I = sum(temp)';

end
% -------------------------------------------------------------------------




% Coherence
% -------------------------------------------------------------------------
function [PF] = Coherence(PF,G)
% Coherence is the nearest-neighbor 2-D autocorrelation of firing rate and
% is calculated in three steps.

% 1) Parallel lists are constructed for the firing rate in each pixel and
%    the average firing rate in the eight nearest neighbors
% 2) the average is the sum of the number of spikes in the neighbors
%    divided by the sum of the time spent in the neighbors
% 3) the product-moment correlation between the two lists is calculated

 % neighbor radius

% this method will only work IFF the PF aggregate is 3 bins or longer

PF.Coherence = zeros(G.numBins,1)/0;
if PF.SizeAgg-G.nRadius*2 > 0
    r = zeros(PF.SizeAgg-G.nRadius*2,1);
    for m = G.nRadius+1:PF.SizeAgg-G.nRadius
        % step 2:
        tempTime = [PF.Time(m-G.nRadius:m-1,:);PF.Time(m+1:m+G.nRadius,:)];
        tempSC = [PF.SC(m-G.nRadius:m-1,:);PF.SC(m+1:m+G.nRadius,:)];
        tempFreq = sum(tempSC)./sum(tempTime);
        % step 3;
        r(m-G.nRadius) = Pearson(PF.IsoFreq(m,:),tempFreq);
    end
    
    % formatting:
    if PF.Bnds(1) < PF.Bnds(2)
        PF.Coherence(PF.Bnds(1)+G.nRadius:PF.Bnds(2)-G.nRadius) = r;
    else
%         if rem((G.numBins - PF.Bnds(1)+1),G.nRadius) > 0
           remain = rem((G.numBins - PF.Bnds(2)+1),G.nRadius);
           if (PF.Bnds(2)+remain)./G.nRadius >1
            PF.Coherence(PF.Bnds(1)+G.nRadius:end) = r(1:end-PF.Bnds(2)+G.nRadius);
            PF.Coherence(1:PF.Bnds(2)-G.nRadius) = r(end-PF.Bnds(2)+G.nRadius+1:end);
           else
               PF.Coherence(PF.Bnds(1)+G.nRadius:end-remain) = r(1:end);
           end
    end

end

end
% -------------------------------------------------------------------------




% Velocity
% -------------------------------------------------------------------------
function [PF] = Velocity(PF,G)
time = sum(PF.Time);
PF.Velocity = ((PF.SizeAgg*G.BinW)./time)';
end
% -------------------------------------------------------------------------



% Other Stats
% -------------------------------------------------------------------------
function [PF] = OtherStats(PF)
[r,c] = find(eye([PF.numLaps,PF.numLaps])~=0);
row = r + 1; col = c; row(end) = []; col(end) = [];
Index = sub2ind([PF.numLaps,PF.numLaps],row,col);

PF.ShiftRPL = PF.ShiftB(Index);
PF.ShiftAbs = abs(PF.ShiftRPL);
for m = 1:PF.numLaps-1
    PF.ShiftROP(m) = sum(PF.ShiftRPL(1:m));
end

PF.rRPL = PF.r(Index);
Diag = sub2ind([PF.numLaps,PF.numLaps],r,c);
temp = PF.r; temp(Diag) = 0;
PF.rAvgAll = (sum(temp)/(PF.numLaps-1))';
ind = 0:5:PF.numLaps;
if ind(end) ~= PF.numLaps, ind(end+1) = PF.numLaps; end
for m = 1:length(ind)-1
    num = ind(m+1)-(ind(m)+1);
    PF.rAvg5L{m,1} = (sum(temp(ind(m)+1:ind(m+1),ind(m)+1:ind(m+1)))/num)';
end
PF.rAvg5L = cell2mat(PF.rAvg5L);
end
% -------------------------------------------------------------------------




% Place Field Overlap
% -------------------------------------------------------------------------
function [O] = PFOverlap(PF,G,O)
OverlapB = zeros(G.numPFs,G.numPFs);
OverlapP = OverlapB;
for j = 1:G.numPFs
    tempj = PF{j}.Bnds(1):PF{j}.SizeAgg+PF{j}.Bnds(1)-1;
    for i = 1:G.numPFs
        tempi = PF{i}.Bnds(1):PF{i}.SizeAgg+PF{i}.Bnds(1)-1;
        tempij = [tempi,tempj];
        OverlapB(i,j) = length(tempij)-length(unique(tempij));
        OverlapP(i,j) = OverlapB(i,j)/length(tempj);
    end
end
O.OverlapB = OverlapB;
O.OverlapP = OverlapP;
end
% -------------------------------------------------------------------------




% Excel Output
% -------------------------------------------------------------------------
function [Sheet] = WritePFSheet(PF,G)

SheetWidth = PF.numLaps*2+1;
Sheet = cell(1,SheetWidth);
Sheet(1,1) = {PF.Name};
Sheet(end+1,:) = {[]};

Sheet(end+1:end+2,1) = {'Start';'End'};
Sheet(end-1:end,2) = num2cell(PF.Bnds');
Sheet(end+1,:) = {[]};

Sheet(end+1,1:2) = {'Lap','Size'};
temp = [PF.LapsAct,PF.Size*G.BinW];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
Sheet(end+1,:) = {[]};

Sheet(end+1,1:3) = {'Lap Number','Center of Mass (cm)','Average Frequency (Hz)'};
temp = [PF.LapsAct,PF.CofM,PF.AvgFnz];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Pearson Correlation'};
Sheet(end+1,2:PF.numLaps+1) = num2cell(PF.LapsAct');
temp = [PF.LapsAct,PF.r];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Frequency Data'};
Sheet(end+1,2:PF.numLaps+1) = num2cell(PF.LapsAct');
s = PF.Bnds(1); e = PF.Bnds(2);
if s <= e
    tempBins = G.Bins(s:e,:);
else
    tempBins = [G.Bins(s:end,:);G.Bins(1:e,:)];
end
temp = [tempBins,PF.IsoFreq];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Shifting Correlation (given in number of Bins shifted)'};
Sheet(end+1,2:2:PF.numLaps*2+1) = num2cell(PF.LapsAct');
Sheet(end+1,2:2:PF.numLaps*2+1) = {'Shift'};
Sheet(end,3:2:PF.numLaps*2+1) = {'r'};
a = 1:2:PF.numLaps*2;
b = 2:2:PF.numLaps*2;
clear temp;
temp(:,a) = PF.ShiftB;
temp(:,b) = PF.ShiftR;
temp = [PF.LapsAct,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
clear temp; 

end
% -------------------------------------------------------------------------





% Write Compiled Data Sheet
% -------------------------------------------------------------------------
function [Sheet] = WriteCompiledSheet(O,G)
RowHeader = cell(G.numLaps-1,1);
for n = 1:G.numLaps-1
    RowHeader{n} = ['L' num2str(G.LapNums(n)) '-L' num2str(G.LapNums(n+1))];
end
statsHeader = {'Mean';'StDev';'Count'};

% O.CofM
% O.AvgFnz
% O.AvgFaf
% O.Size
% O.rAvgAll
% O.rAvg5L
% O.ShiftRPL
% O.ShiftROP
% O.ShiftAbs
% O.ShiftCofM
% O.rRPL
% O.Velocity
% O.numLapsAct

Sheet = cell(1,G.numPFs+4);

Sheet(1,1) = {'Compiled Data'};
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Number of Laps Active'};
Sheet(end+1,2:end-3) = [G.PFName];
temp = [0/0,O.numLapsAct];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Place Field Overlap (Bins)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
[r,c] = find(eye(size(O.OverlapB))~=0);
Index = sub2ind(size(O.OverlapB),r,c);
O.OverlapB(Index) = 0/0;
temp = getMeanStdCountRow(O.OverlapB,false);
temp = [G.PFName',temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Place Field Overlap (%)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
[r,c] = find(eye(size(O.OverlapP))~=0);
Index = sub2ind(size(O.OverlapP),r,c);
O.OverlapP(Index) = 0/0;
temp = getMeanStdCountRow(O.OverlapP,false);
temp = [G.PFName',temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

% Sheet(end+1,1) = {'Place Field Overlap (%)'};
% Sheet(end+1,2:end-3) = G.PFName';
% Sheet(end+1:length(Sheet(:,1))+G.numPFs,1) = G.PFName;
% Sheet(end-G.numPFs+1:end,2:G.numPFs+1) = num2cell(O.OverlapP);
% Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Center of Mass (cm)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.CofM);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Average Frequency (non-zero only, Hz)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.AvgFnz);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Average Frequency (all frequencies, Hz)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.AvgFaf);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Information Per Spike'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.Info);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Velocity (cm/s)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.Velocity);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Field Size (cm)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.Size);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'SHIFTING CORRELATION'};
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Shift Relative to Prior Lap (in bins)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.ShiftRPL);
temp = getMeanStdCountRow(temp,true);
tempHeader = [RowHeader;statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Shift Relative to Original Position (o.p. = 0)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.ShiftROP);
temp = getMeanStdCountRow(temp,true);
tempHeader = [RowHeader;statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Absolute Shift'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.ShiftAbs);
temp = getMeanStdCountRow(temp,true);
tempHeader = [RowHeader;statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Center of Mass Shift Relative to Original Position (o.p. = CofM 1st active lap)'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.ShiftCofM);
temp = getMeanStdCountRow(temp,true);
tempHeader = [RowHeader;statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Absolute Center of Mass Shift'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.ShiftCofMAbs);
temp = getMeanStdCountRow(temp,true);
tempHeader = [RowHeader;statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'LAP-TO-LAP CORRELATION'};
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Average Correlation Within 5-Lap Sets'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.rAvg5L);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Average Correlation Across All Laps'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.rAvgAll);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.LapNums);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Correlation of Each Lap With the Next'};
Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.rRPL);
temp = getMeanStdCountRow(temp,true);
tempHeader = [RowHeader;statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'PLACE FIELD COHERENCE'};
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'Coherence (r)'};
% Sheet(end+1,2:end-3) = G.PFName';
% temp = [G.Bins,];
% [M,N] = size(temp);
% Sheet(end+1:length(Sheet(:,1))+M,1:N) = num2cell(temp);
% Sheet(end+1,:) = {[]};

Sheet(end+1,2:end) = [G.PFName,statsHeader'];
temp = getMeanStdCountCol(O.Coherence);
temp = getMeanStdCountRow(temp,true);
tempHeader = [num2cell(G.Bins);statsHeader];
temp = [tempHeader,temp];
[M,N] = size(temp);
Sheet(end+1:length(Sheet(:,1))+M,1:N) = temp;
Sheet(end+1,:) = {[]};

Sheet(end+1,1) = {'NUMBER OF PLACE FIELDS PER CELL'};
Sheet(end+1,:) = {[]};

Sheet(end+1,1:2) = {'Cell Name','numPFs'};
Sheet(end+1:length(Sheet(:,1))+length(O.numPFsPerCell(:,1)),1:2) = O.numPFsPerCell;
end
% Get Mean, Standard Deviation, and Count Per Column
% -------------------------------------------------------------------------
function [temp] = getMeanStdCountCol(temp)
% get size of input array
sizeTemp = size(temp);
numRows = sizeTemp(1);
numCols = sizeTemp(2);
t = temp;
% find any entries 
[r,c] = find(isnan(temp));
rowCol = [r,c];
numRowsNaN = zeros(1,numCols)/0;
for m = 1:numCols
    numRowsNaN(m) = length(find(rowCol(:,2) == m));
end
rowsAct = bsxfun(@minus,numRows*ones(1,numCols),numRowsNaN);
t(isnan(t)) = 0;
meanTemp = sum(t,1)./rowsAct;
varTemp = (bsxfun(@minus,temp,meanTemp)).^2;
varTemp(isnan(varTemp)) = 0;
varTemp = sum(varTemp,1)./(rowsAct-1);
stdTemp = varTemp.^(1/2);

temp = [temp;meanTemp;stdTemp;rowsAct];
end
% Get Mean, Standard Deviation, and Count Per Row
% -------------------------------------------------------------------------
function [temp] = getMeanStdCountRow(temp,clear3by3Option)
% if true, "clear3by3option" gets rid of the 3x3 lower-right-hand corner of
% the matrix

sizeTemp = size(temp);
numRows = sizeTemp(1);
numCols = sizeTemp(2);
t = temp;
[r,c] = find(isnan(temp));
rowCol = [r,c];
numColsNaN = zeros(numRows,1)/0;
for m = 1:numRows
    numColsNaN(m) = length(find(rowCol(:,1) == m));
end
colsAct = bsxfun(@minus,numCols*ones(numRows,1),numColsNaN);
t(isnan(t)) = 0;
meanTemp = sum(t,2)./colsAct;

varTemp = (bsxfun(@minus,temp,meanTemp)).^2;
varTemp(isnan(varTemp)) = 0;
varTemp = sum(varTemp,2)./(colsAct-1);
stdTemp = varTemp.^(1/2);

temp = [temp,meanTemp,stdTemp,colsAct];
if clear3by3Option, temp(end-2:end,end-2:end) = 0/0; end
temp = num2cell(temp);
end




% Write Output To File
% -------------------------------------------------------------------------
function [] = WritePFOutputToExcel(SheetNames,Sheets,UI)

[Name,Path] = uiputfile(['Laps ' UI.SetStr '.xls'],'Save As');
excelObj = actxserver('Excel.Application');
Workbook = excelObj.Workbooks.Add;
numSheets = length(Sheets);

for n = numSheets:-1:1
    Size = size(Sheets{n});
    OverShoot = Size(2)-26;
    % if number of columns greater than number of letters in alphabet
    if OverShoot > 0
        NumAlphabets = ceil(Size(2)/26)-1;
        ExcelRange = ['A1:' char('a'+NumAlphabets-1) char('a'+OverShoot-26*(NumAlphabets-1)-1) num2str(Size(1))];
    else
        ExcelRange = ['A1:' char('a'+Size(2)-1) num2str(Size(1))];
    end
        
    Worksheet{n} = excelObj.sheets.Add;
    Worksheet{n}.Name = SheetNames{n};
    Range{n} = get(Worksheet{n},'Range',ExcelRange);
    Range{n}.Value = Sheets{n};    
end

Workbook.SaveAs([Path Name]); Workbook.Close;
excelObj.Quit; delete(excelObj);

end
% -------------------------------------------------------------------------















