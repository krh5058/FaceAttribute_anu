classdef main < handle
% main.m class for Expression and similar tasks.
    
    properties
        debug = 0;
        subjinfo
        block = {'f1','f2','f3','m1','m2','m3'};      
        order;
        current_block
        prac_block = {'f4','m4'};
        prac_rep = 3;
        current_condition
        vals = {'02','03','04','06','08','11','16','27','32','45','64','91'};
        fix = 1;
        abort = 0;
        pracadd = 0; % Additional practice durations, added to timelim 1 and 3
        timelim = [3 .75 2]; % Response duration (1), ITI (2), Display duration (3 - optional)
        imgsize = [411 276 3];
%         rescale = 2/3; % Selected to fit an upper_buffer and middle_buffer of 100 pixels
        monitor
        path
        text
        keys
        keymap
        cbfeed = [zeros([5 1]); ones([5 1])]; % Counter-balance measures
        out
    end
    
    methods (Static)
        function d = listDirectory(path,varargin)
            % Search path with optional wildcards
            % path = search directory
            % varargin{1} = name filter
            % varargin{2} = extension filter
            
            narginchk(1,3);
            
            name = [];ext = [];
            
            vin = size(varargin,2);
            
            if vin==1
                name = varargin{1};
            elseif vin==2
                name = varargin{1};
                ext = varargin{2};
            end
            
            if ismac
                %                 [~,d] = system(['ls ' path filesep '*' name '*' ext ' | xargs -n1 basename']);
                if isempty(name) && isempty(ext)
                    [~,d] = system(['ls ' path filesep '| xargs -n1 basename']);
                elseif isempty(ext)
                    [~,d] = system(['ls ' path filesep '*' name '* | xargs -n1 basename']);
                else
                    [~,d] = system(['ls ' path filesep '*' name '*' ext '| xargs -n1 basename']);
                end
            elseif ispc
                [~,d] = system(['dir /b "' path '"' filesep '*' name '*' ext]);
            else
                error('main.m (listDirectory): Unsupported OS.');
            end
        end
    end
    
    methods
        %% Constructor
        function obj = main(varargin)
            
            obj.path.base = varargin{1};
            obj.pathset;
            
            d = obj.listDirectory(obj.path.pictures);
            condlist = regexp(d(1:end-1),'\n','split');
            
            fprintf('main.m UI query for experimental parameters.\n');
            frame = javaui(obj.block,condlist);
            waitfor(frame,'Visible','off'); % Wait for visibility to be off
            s = getappdata(frame,'UserData'); % Get frame data
            java.lang.System.gc();
            
            if isempty(s)
                error('main.m : User Cancelled.')
            end
            
            s{2} = char(s{2});
            
            obj.subjinfo.sid = s{1};
            obj.current_condition = lower(s{2});
            obj.order = cellfun(@(y)(regexprep(y,',','')),s{3},'UniformOutput',false);
                
            if ispc
                obj.path.condition = [obj.path.pictures filesep s{2}];
            else
                obj.path.condition = [obj.path.pictures filesep s{2}];
            end
            
            obj.path.prac = [obj.path.condition filesep 'practice'];
            obj.path.task = [obj.path.condition filesep 'task'];
            
            obj.current_condition = lower(s{2});
            
%             % Query user: subject info, block order, kid/adult condition
%             prompt={'Subject ID:'};
%             name='Experiment Info';
%             numlines=1;
%             defaultanswer={datestr(now,30)};
%             s=inputdlg(prompt,name,numlines,defaultanswer);
%             
%             if isempty(s)
%                 error('User Cancelled.')
%             end
            
            %             if obj.rescale % Rescale obj.imgsize
            %
            %                 obj.imgsize(1) = ceil(obj.imgsize(1)*(obj.rescale));
            %                 obj.imgsize(2) = ceil(obj.imgsize(2)*(obj.rescale));
            %
            %             end
            
            %             % Text prep
            %             obj.text.withpic = 'Which face shows more expression?';
            %             obj.text.leftarrow = '<';
            %             obj.text.rightarrow = '>';
            %             obj.text.goodbye = WrapString('Thank you for participating!  You are now finished with this portion of the study.');
            obj.text.cberr = 'Attempted to access cb(11,1); index out of bounds because size(cb)=[10,2].';
%             obj.text.txtSize = 30;
        end
        %%
        %% Dispset
        function [monitor] = dispset(obj)
            % 3/20/13
            % Ken Hwang
            % PSU, Scherf Lab, SLEIC, Dept. of Psych.
            
            % Determines monitor settings
            % Output: monitor data structure
            
            if obj.debug
%                 Desktop debug
                whichScreen = max(Screen('Screens'));
            else
%                 Find out how many screens and use smallest screen number (laptop screen).
                whichScreen = min(Screen('Screens'));
            end
            
            % Rect for screen
            rect = Screen('Rect', whichScreen);
            
            % Screen center calculations
            center_W = rect(3)/2;
            center_H = rect(4)/2;
            
            % ---------- Color Setup ----------
            % Gets color values.
            
            % Retrieves color codes for black and white and gray.
            black = BlackIndex(whichScreen);  % Retrieves the CLUT color code for black.
            white = WhiteIndex(whichScreen);  % Retrieves the CLUT color code for white.
            
            gray = (black + white) / 2;  % Computes the CLUT color code for gray.
            if round(gray)==white
                gray=black;
            end
            
            % Taking the absolute value of the difference between white and gray will
            % help keep the grating consistent regardless of whether the CLUT color
            % code for white is less or greater than the CLUT color code for black.
            absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
            
            % Definining image rects
            middle_buffer = 50;
            x1_left = ((center_W - (middle_buffer/2)) - obj.imgsize(2));
            x1_right = (center_W - (middle_buffer/2));
            x2_left = (center_W + (middle_buffer/2));
            x2_right = x2_left + obj.imgsize(2);
            y_extra = rect(4) - obj.imgsize(1);
            y_shift = 30;
            y_top = floor(y_extra/2)-y_shift;
            y_bottom = y_top + obj.imgsize(1);
            monitor.rect1 = [x1_left y_top x1_right y_bottom];
            monitor.rect2 = [x2_left y_top x2_right y_bottom];
                        
            % Data structure for monitor info
            monitor.whichScreen = whichScreen;
            monitor.rect = rect;
            monitor.center_W = center_W;
            monitor.center_H = center_H;
            monitor.black = black;
            monitor.white = white;
            monitor.gray = gray;
            monitor.absoluteDifferenceBetweenWhiteAndGray = absoluteDifferenceBetweenWhiteAndGray;
            
            obj.monitor = monitor;
            
        end
        %%
        
        %% Pathset
        function pathset(obj)
            try
                obj.path.bin = [obj.path.base filesep 'bin'];
                obj.path.out = [obj.path.base filesep 'out'];
                obj.path.content = [obj.path.base filesep 'content'];
                contentcell = {'general','pictures'}; % Add to cell for new directories in 'content'
                for i = 1:length(contentcell)
                    obj.path.(contentcell{i}) = [obj.path.content filesep contentcell{i}];
                end
            catch ME
                fprintf(['main.m (pathset): ' ME.message]);
                throw(ME)
            end
        end
        %%
        
        %% Keyset
        function keyset(obj)
            % Key prep
            KbName('UnifyKeyNames');
            
            obj.keys.leftkey = KbName('LeftArrow');
            obj.keys.rightkey = KbName('RightArrow');
            obj.keymap = [obj.keys.leftkey obj.keys.rightkey];  % Ordering: 1 = pic1, 2 = pic2
            
            obj.keys.esckey = KbName('Escape');
            obj.keys.spacekey = KbName('SPACE');
        end
        %%
        
        %% Cb
        function [cbout] = cb(obj)
            
            cbout = Shuffle(obj.cbfeed);
            cbout = [cbout ~cbout];
            
        end
        %%
        
        %% Imgload
        function [img, img0, img100] = imgload(obj,type,block)
            try
                %                 if obj.rescale % Rescale to parameter
                %                     img = zeros([obj.imgsize(1) obj.imgsize(2) obj.imgsize(3) length(obj.vals)]);
                %                     for i = 1:length(obj.vals)
                %                         img(:,:,:,i) = imresize(imread([obj.path.pictures filesep expr filesep expr obj.vals{i} '.jpg']),obj.rescale);
                %                         %                     img(:,:,:,i) = img(:,:,:,i)/max(max(max(img(:,:,:,i))));
                %                     end
                %
                %                     img0 = imresize(imread([obj.path.pictures filesep expr filesep expr '00.jpg']),obj.rescale);
                %                     %                 img0 = img0.*1.2; % 1.2 to compensate for Dot Gain in
                %                     img100 = imresize(imread([obj.path.pictures filesep expr filesep expr '100.jpg']),obj.rescale);
                %                     %                 img100 = img100.*1.2;
                %                 else
                %                 end
                
                switch type
                    case 'prac'
                        img = [];
                        img0 = imread(fullfile([obj.path.(type) filesep],[block '_00.jpg']));
                        img100 = imread(fullfile([obj.path.(type) filesep],[block '_100.jpg']));
                    case 'task'
                        img = cell([length(obj.vals) 1]);
                        for i = 1:length(obj.vals)
                            img{i} = imread(fullfile([obj.path.(type) filesep], [block '_' obj.vals{i} '.jpg']));
                            %                     img(:,:,:,i) = img(:,:,:,i)/max(max(max(img(:,:,:,i))));
                        end
                        
                        img0 = imread(fullfile([obj.path.(type) filesep],[block '_00.jpg']));
                        %                 img0 = img0.*1.2; % 1.2 to compensate for Dot Gain in
                        img100 = imread(fullfile([obj.path.(type) filesep],[block '_100.jpg']));
                        %                 img100 = img100.*1.2;
                end
                
            catch ME
                fprintf(['main.m (imgload): ' ME.message]);
                throw(ME)
            end
        end
        %%
        
        %% Imgshow
        function [tex1, tex2] = imgshow(obj,pic1,pic2)
            % pic1 (left), pic2 (right)
            tex1 = Screen('MakeTexture',obj.monitor.w,pic1);
            tex2 = Screen('MakeTexture',obj.monitor.w,pic2);
            Screen('DrawTexture',obj.monitor.w,tex1,[],obj.monitor.rect1);
            Screen('DrawTexture',obj.monitor.w,tex2,[],obj.monitor.rect2);
        end
        %%
        
        %% Imgshow2
        function [tex] = imgshow2(obj,picstring)
           picmat = imread(picstring);
           tex = Screen('MakeTexture',obj.monitor.w,picmat);
           Screen('DrawTexture',obj.monitor.w,tex);
        end
        %%
        
%         %% Audioload
%         function [pahandle] = audioload(obj)
%             % Loading general content -- Audio
%             if ismac
%                 try
%                     addpath([matlabroot filesep 'toolbox' filesep 'mp3readwrite']); % Add mp3readwrite
%                 catch ME
%                     throw(ME)
%                 end
%             else
%                 fprintf('Mac OS supported only.');
%             end
%             
%             audio.dat = cell([length(obj.soundfiles) 1]);
%             
%             for i = 1:length(obj.soundfiles)
%                 audio.dat{i} = mp3read([obj.path.general filesep obj.soundfiles{i} '.mp3']);
%             end
%             
%             InitializePsychSound;
%             PsychPortAudio('DeleteBuffer');
%             pahandle = PsychPortAudio('Open',[],[],0,44100,2); % 44100Hz, Stereo (2)
%             audio.pahandle = pahandle;
%             
%             obj.audio = audio;
%             
%         end
%         %%
%         
%         %% Playaudio
%         function playaudio(obj,dat)
%             buffer = PsychPortAudio('CreateBuffer',[],dat');
%             PsychPortAudio('FillBuffer',obj.audio.pahandle,buffer);
%             PsychPortAudio('Start',obj.audio.pahandle,1,0,0);
%         end
%         %%
        
        %% Practice
        function practice(obj,img0,img100)
            RestrictKeysForKbCheck([obj.keys.esckey obj.keymap]); 
            endflag = 0;
            while ~endflag
                if randi([0 1])
                    pic1 = 'img100';
                    pic2 = 'img0';
                    answer = obj.keymap(1);
                else
                    pic1 = 'img0';
                    pic2 = 'img100';
                    answer = obj.keymap(2);
                end
                
                [tex] = obj.imgshow2([obj.path.general filesep 'practrial_' obj.current_condition '.jpg']);
                [tex1,tex2] = obj.imgshow(eval(pic1),eval(pic2));
                Screen('Flip',obj.monitor.w);
                
                Screen('Close',tex);
                Screen('Close',tex1);
                Screen('Close',tex2);
                tic
                start = GetSecs;
                keyIsDown = 0;
                drop = 0;
                while (GetSecs-start) < (obj.timelim(1) + obj.pracadd)
                    
                    if ~drop
                        if numel(obj.timelim) >= 3
                            if (GetSecs-start) > (obj.timelim(3) + obj.pracadd)
                                [tex] = obj.imgshow2([obj.path.general filesep 'practrial_' obj.current_condition '.jpg']);
                                Screen('Flip',obj.monitor.w);
                                Screen('Close',tex);
                                drop = 1;
                                toc
                            end
                        end
                    end
                    
                    [keyIsDown,secs,keyCode]=KbCheck; %#ok<ASGLU>
                    if keyIsDown
                        if find(keyCode) == obj.keys.esckey
                            endflag = 1;
                            obj.abort = 1;
                            if obj.debug
                                fprintf('main.m (practice): Aborted!\n')
                            end
                        elseif find(keyCode) == answer
                            if obj.debug
                                fprintf('main.m (practice): Correct!\n');
                                fprintf(['main.m (practice): pic1 - ' pic1 '\n']);
                                fprintf(['main.m (practice): pic2 - ' pic2 '\n']);
                            end
                            endflag = 1;
                            % Audio
%                             if obj.audio_on
%                                 obj.playaudio(obj.audio.dat{1});
%                             end
                        else
                            if obj.debug
                                fprintf('main.m (practice): Incorrect!\n');
                                fprintf(['main.m (practice): pic1 - ' pic1 '\n']);
                                fprintf(['main.m (practice): pic2 - ' pic2 '\n']);
                            end
                        end
                        break;
                    end
                end
%                 toc
                
                if ~keyIsDown
                    if obj.debug
                        fprintf('main.m (practice): No response!\n');
                        fprintf(['main.m (practice): pic1 - ' pic1 '\n']);
                        fprintf(['main.m (practice): pic2 - ' pic2 '\n']);
                    end
%                    if obj.audio_on
%                        obj.playaudio(obj.audio.dat{2});
%                    end
                end
                                    
                if obj.fix
                    Screen('DrawLine',obj.monitor.w,obj.monitor.white,obj.monitor.center_W-20,obj.monitor.center_H,obj.monitor.center_W+20,obj.monitor.center_H,7);
                    Screen('DrawLine',obj.monitor.w,obj.monitor.white,obj.monitor.center_W,obj.monitor.center_H-20,obj.monitor.center_W,obj.monitor.center_H+20,7);
                end
                
                Screen('Flip',obj.monitor.w);
                pause(obj.timelim(2));
%                 toc
            end
        end
        
        %% Cycle
        function cycle(obj,img,img0)
            obj.datproc(1);
            endflag = 0;
            cb = obj.cb;
            i = 1;
            step = 11;
            track = 0;
            track_c = 0; % Track 3 corrects on hardest trial (in a row)
            thresh = [];
            threshcalc = []; % Value used in thresh calculation (typically step above, but not if prior trial was incorrect)
            RestrictKeysForKbCheck([obj.keys.esckey obj.keymap]); 
            
            while ~endflag
                try
                    if i > size(cb,1)
                        i = 1;
                    end
                    
                    if cb(i,1)
                        pic1 = 'img{step}';
                        pic1name = [obj.current_block '_' obj.vals{step}];
                        pic2 = 'img0';
                        pic2name = [obj.current_block '_00'];
                        
                        answer = obj.keymap(1);
                        
                    else
                        pic1 = 'img0';
                        pic1name = [obj.current_block '_00'];
                        pic2 = 'img{step}';
                        pic2name = [obj.current_block '_' obj.vals{step}];
                        
                        answer = obj.keymap(2);
                    end
                    
                    [tex] = obj.imgshow2([obj.path.general filesep 'trial_' obj.current_condition '.jpg']);
                    [tex1,tex2] = obj.imgshow(eval(pic1),eval(pic2));
                    Screen('Flip',obj.monitor.w);
                    
                    Screen('Close',tex);
                    Screen('Close',tex1);
                    Screen('Close',tex2);
%                     tic
                    start = GetSecs;
                    keyIsDown = 0;
                    drop = 0;
                    while (GetSecs-start) < obj.timelim(1)
                        
                        if ~drop
                            if numel(obj.timelim) >= 3
                                if (GetSecs-start) > obj.timelim(3)
                                    [tex] = obj.imgshow2([obj.path.general filesep 'trial_' obj.current_condition '.jpg']);
                                    Screen('Flip',obj.monitor.w);
                                    Screen('Close',tex);
                                    drop = 1;
%                                     toc
                                end
                            end
                        end
                        
                        [keyIsDown,secs,keyCode]=KbCheck; 
                        if keyIsDown
                            if find(keyCode) == obj.keys.esckey
                                endflag = 1;
                                obj.abort = 1;
                                if obj.debug
                                    fprintf('main.m (cycle): Aborted!\n')
                                end
                            elseif find(keyCode) == answer
 
                                threshcalc = str2double(obj.vals{step});
                                
                                if step == 1
                                    track_c = track_c + 1; % Add consecutive successes only for step == 1
                                    if track_c == 3
                                        % Calculate thresh using mean of
                                        % lowest percentage (img0 = 0%)  and step percentage (step = 1).
                                        % Average with running thresh and abort
                                        thresh = mean([mean([0 str2double(obj.vals{step})]) thresh]);
                                        endflag = 1;
                                    end
                                else
                                    step = step - 1;
                                end
                                
                                if obj.debug
                                    fprintf('main.m (cycle): Correct!\n');
                                    fprintf(['main.m (cycle): pic1 - ' pic1name '\n']);
                                    fprintf(['main.m (cycle): pic2 - ' pic2name '\n']);
                                    fprintf(['main.m (cycle): threshcalc - ' num2str(threshcalc) '\n']);
                                end
                                
                                % Record (after thresh calc if step==1)
                                fprintf(obj.out.fid,'%s,%s,%s,%1.2f,%i,%i,%2.2f\n',obj.subjinfo.sid,pic1name,pic2name,secs-start,1,0,thresh);
                                
                            else
                                
                                thresh = mean([mean([threshcalc str2double(obj.vals{step})]) thresh]);
                                threshcalc = thresh;
                                
                                if obj.debug
                                    fprintf('main.m (cycle): Incorrect!\n');
                                    fprintf(['main.m (cycle): pic1 - ' pic1name '\n']);
                                    fprintf(['main.m (cycle): pic2 - ' pic2name '\n']);
                                    fprintf(['main.m (cycle): threshcalc - ' num2str(threshcalc) '\n']);
                                end
                                
                                % Record
                                fprintf(obj.out.fid,'%s,%s,%s,%1.2f,%i,%i,%2.2f\n',obj.subjinfo.sid,pic1name,pic2name,secs-start,0,1,thresh);
                                
                                track = track + 1;
                                
                                if track == 5
                                    endflag = 1;
                                else
                                    step = step + 4;
                                    if step > length(obj.vals)
                                        step = length(obj.vals);
                                    end
                                end
                            end
                            break;
                        end
                    end
                    
                    if ~keyIsDown % No response
                        thresh = mean([mean([threshcalc str2double(obj.vals{step})]) thresh]);
                        threshcalc = thresh;
                        if obj.debug
                            fprintf('main.m (cycle): No response!\n');
                            fprintf(['main.m (cycle): pic1 - ' pic1name '\n']);
                            fprintf(['main.m (cycle): pic2 - ' pic2name '\n']);
                            fprintf(['main.m (cycle): threshcalc - ' num2str(threshcalc) '\n']);
                        end

                        fprintf(obj.out.fid,'%s,%s,%s,%1.2f,%i,%i,%2.2f\n',obj.subjinfo.sid,pic1name,pic2name,[],0,1,thresh);
                        
                        track = track + 1;
                        if track == 5
                            endflag = 1;
                        else
                            step = step + 4;
                            if step > length(obj.vals)
                                step = length(obj.vals);
                            end
                        end
                    end
%                     toc
                    
                    if obj.debug
                        fprintf(['main.m (cycle): Next image name - ' [obj.current_block '_' obj.vals{step}] '\n']);
                        fprintf(['main.m (cycle): Track number - ' num2str(track) '\n']);
                    end
                    
                    i = i + 1;
                    
                    if obj.fix
                        Screen('DrawLine',obj.monitor.w,obj.monitor.white,obj.monitor.center_W-20,obj.monitor.center_H,obj.monitor.center_W+20,obj.monitor.center_H,7);
                        Screen('DrawLine',obj.monitor.w,obj.monitor.white,obj.monitor.center_W,obj.monitor.center_H-20,obj.monitor.center_W,obj.monitor.center_H+20,7);
                    end
                    
                    Screen('Flip',obj.monitor.w);
                    pause(obj.timelim(2));
%                     toc
                    
                catch ME
                    if strcmp(ME.message,obj.text.cberr)
                        cb = obj.cb;
                        i = 1;
                    else
                        disp(ME.message)
                        endflag = 1;
%                         break;
                    end
                end
            end
        end
        %%
        
        %% Datproc
        function datproc(obj,type)
            if type == 1
                obj.out.h = {'Subject','Left','Right','RT','Acc','Reversal','Thresh Avg.'};
                obj.out.fid = fopen([obj.path.out filesep obj.subjinfo.sid '.csv'],'a');
                fprintf(obj.out.fid,'%s,%s,%s,%s,%s,%s,%s\n',obj.out.h{:});
            elseif type == 2
                
                try
                    obj.out.h2 = {'Condition','TotalTrials','Reversals','FinalThresh','CorrectRT','IncorrectRT'};
                    obj.out.fid2 = fopen([obj.path.out filesep obj.subjinfo.sid '.csv']);
                    dat = textscan(obj.out.fid2, '%s%s%s%s%s%s%s','Delimiter',',');
                    dat = [dat{:}];
                    cond = 0;
                    head = [];
                    
                    for i = 1:size(dat,1)
                        if all(strcmp(dat(i,:),obj.out.h));
                            head = [head i];
                            cond = cond + 1;
                        end
                    end
                    
                    if (head(end) + 1) > size(dat,1)
                        head = head(1:end-1);
                    end
                        
                    condnames = cellfun(@(y)(regexprep(y,'(_\d{2,3})$','')),dat(head + 1,2),'UniformOutput',false);
                    
                    if isempty(condnames)
                        fprintf('main.m (datproc): No conditions found.\n');
                        return;
                    end
                    
                    for i = 1:length(head)
                        if i == length(head)
                            x2 = 'end';
                        else
                            x2 = 'head(i + 1)-1';
                        end
                        dat2.(condnames{i}) = eval(['dat(head(i):' x2 ',:);']);
                    end
                    
                    out2 = cell([length(condnames) length(obj.out.h2)]);
                    out2(:,1) = condnames;
                    
                    for i = 1:length(condnames)
                        out2{i,2} = size(dat2.(condnames{i}),1)-1; % Length minus 1 (following header)
                        rev = regexp([dat2.(condnames{i}){2:end,6}],'1');
                        correct = setxor(2:size(dat2.(condnames{i}),1),rev+1);
                        
                        if ~isempty(rev)
                            out2{i,3} = length(rev);
                        end
                        
                        out2{i,4} = str2num(dat2.(condnames{i}){end,end}); %#ok<*ST2NM>
                        corrRT = cellfun(@(y)(str2num(y)),dat2.(condnames{i})(correct,4),'UniformOutput',false);
                        out2{i,5} = mean([corrRT{:}]);
                        
                        if ~isempty(rev)
                            incorrRT = cellfun(@(y)(str2num(y)),dat2.(condnames{i})(rev+1,4),'UniformOutput',false);
                            out2{i,6} = mean([incorrRT{:}]);
                        end
                        
                    end
                    
                    cell2csv([obj.path.out filesep obj.subjinfo.sid '_summary.csv'],[obj.out.h2; out2]);
                    
                catch ME
                    fprintf(['main.m (datproc): ' ME.message]);
                    throw(ME)
                end
            end
        end
    end
    
end

