function runExpression(varargin)
% Any arguments in are assumed to be property changes.

% Directory setup
p = mfilename('fullpath');
[p,~,~] = fileparts(p);

% Bin
bin = [p filesep 'bin'];
addpath(bin);

% Object setup
obj = main;
obj.path.base = p;

if nargin > 0 % Property additions
    for nargs = 1:nargin
        if isstruct(varargin{nargs})
            fnames = fieldnames(varargin{nargs});
            for j = 1:length(fnames)
                obj.(inputname(nargs)).(fnames{j}) = varargin{nargs}.(fnames{j});
            end
        else
            obj.(inputname(nargs)) = varargin{nargs};
        end
    end
end

obj.pathset;

% Diary
d_file = datestr(now,30);
diary([obj.path.out filesep d_file]);

% Preseentation set-up
ListenChar(2);
HideCursor;

if ispc
    ShowHideWinTaskbarMex(0)
end

try
    fprintf('\nExpression: Key set-up ...\n')
    obj.keyset;
    fprintf('\nExpression: Done!\n')
catch ME
    throw(ME)
end

try
    fprintf('\nExpression: Monitor set-up ...\n')
    obj.dispset;
    fprintf('\nExpression: Done!\n')
catch ME
    throw(ME)
end

if obj.audio_on
    try
        fprintf('\nExpression: Audio set-up ...\n')
        obj.audioload;
        fprintf('\nExpression: Done!\n')
    catch ME
        throw(ME)
    end
end

try
    fprintf('\nExpression: Window set-up ...\n')
    % Open and format window
    obj.monitor.w = Screen('OpenWindow',obj.monitor.whichScreen,obj.monitor.black);
    Screen('BlendFunction', obj.monitor.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',obj.monitor.w,30);
    fprintf('\nExpression: Done!\n')
catch ME
    throw(ME)
end

try
    fprintf('\nExpression: Beginning practice ...\n')
    [tex] = obj.imgshow2([obj.path.general filesep 'intro.jpg']);
    Screen('Flip',obj.monitor.w);
    
    Screen('Close',tex);
    RestrictKeysForKbCheck(obj.keys.spacekey);
    KbStrokeWait;
    
    % Handling supplements
    switch obj.type
        case 'FaceAttribute'
            [tex] = obj.imgshow2([obj.path.general filesep 'instruct.jpg']);
            Screen('Flip',obj.monitor.w);
            
            Screen('Close',tex);
            RestrictKeysForKbCheck(obj.keys.spacekey);
            KbStrokeWait;
            
        otherwise
            
    end
    
    switch obj.type
        case 'FaceAttribute'
            % Definining image rects for practice
            middle_buffer = 50;
            x1_left = ((obj.monitor.center_W - (middle_buffer/2)) - obj.imgsize(2));
            x1_right = (obj.monitor.center_W - (middle_buffer/2));
            x2_left = (obj.monitor.center_W + (middle_buffer/2));
            x2_right = x2_left + obj.imgsize(2);
            y_extra = obj.monitor.rect(4) - obj.imgsize(1);
            y_shift = 30;
            y_top = floor(y_extra/2)-y_shift;
            y_bottom = y_top + obj.imgsize(1);
            obj.monitor.rect1 = [x1_left y_top x1_right y_bottom];
            obj.monitor.rect2 = [x2_left y_top x2_right y_bottom];
            
            if ismac
                [~,d] = system(['ls ' obj.path.general filesep 'practice']);
            elseif ispc
                [~,d] = system(['dir /b ' obj.path.general filesep 'practice']);
            else
                error('runExpression: Unsupported OS.');
            end

            d = regexp(d(1:end-1),'[\t\n]','split');
            d = reshape(sort(d),[3 2 2]); 
            d = [d(:,:,1); d(:,:,2)]'; % 1 sub and 1 dom picture for each type & percentage
            d = d(:,Shuffle(1:6)); % Randomize
            for i = 1:size(d,2)
                img0 = imread([obj.path.general filesep 'practice' filesep d{2,i}]); % Sub
                img100 = imread([obj.path.general filesep 'practice' filesep d{1,i}]); % Dom
                obj.practice(img100,img0);
                if obj.abort
                    break;
                end
            end

        otherwise
    
            prac = randsample(obj.block,4);
            
            for i = 1:length(prac)
                [~, img0, img100] = obj.imgload(prac{i});
                obj.practice(img100,img0);
                if obj.abort
                    break;
                end
            end
            
    end
    %     disp('Practice done.');
    
    fprintf('\nExpression: Done!\n')
catch ME
    throw(ME)
end

try
    fprintf('\nExpression: Beginning task ...\n')
    
    [tex] = obj.imgshow2([obj.path.general filesep 'begin.jpg']);
    Screen('Flip',obj.monitor.w);
    
    Screen('Close',tex);
    RestrictKeysForKbCheck(obj.keys.spacekey);
    KbStrokeWait;
    
    % Randomize block
    s_block = Shuffle(obj.block);
    
    for i = 1:length(s_block)
        
        [tex1] = obj.imgshow2([obj.path.general filesep 'blockbegin.jpg']);
        [tex2] = obj.imgshow2([obj.path.pictures filesep s_block{i} filesep s_block{i} '100.jpg']);
        Screen('Flip',obj.monitor.w);
        
        Screen('Close',tex1);
        Screen('Close',tex2);
        RestrictKeysForKbCheck(obj.keys.spacekey);
        KbStrokeWait;
        
        obj.current_block = s_block{i};
        [img, img0, ~] = obj.imgload(s_block{i});
        obj.cycle(img,img0);
        if obj.abort
            break;
        end
    end
    fclose(obj.out.fid);
    
    obj.datproc(2);
    %     disp('Task finished.');
    
    [tex] = obj.imgshow2([obj.path.general filesep 'outro.jpg']);
    Screen('Flip',obj.monitor.w);
    
    Screen('Close',tex);
    RestrictKeysForKbCheck([]);
    KbStrokeWait;
    
    fprintf('\nExpression: Done!\n')
catch ME
    throw(ME)
end

% Clean up
ListenChar(0);
ShowCursor;

if ispc
    ShowHideWinTaskbarMex(1)
end

if obj.audio_on
    PsychPortAudio('Close', obj.audio.pahandle); % Close pahandle
end
Screen('CloseAll');

end