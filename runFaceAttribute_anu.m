function runFaceAttribute_anu

% Directory setup
p = mfilename('fullpath');
[p,~,~] = fileparts(p);

% Bin
bin = [p filesep 'bin'];
addpath(bin);

% Object setup
try
    fprintf('\nFaceAttribute_anu: Main object set-up ...\n')
    obj = main(p);
    fprintf('\nFaceAttribute_anu: Done!\n')
catch ME
    fprintf(['\nFaceAttribute_anu: ' ME.message])
    throw(ME)
end

% Diary
d_file = datestr(now,30);
diary([obj.path.out filesep d_file]);

% Presentation set-up

if ~obj.debug
    ListenChar(2);
    HideCursor;
    
    if ispc
        ShowHideWinTaskbarMex(0)
    end
end

try
    fprintf('\nFaceAttribute_anu: Key set-up ...\n')
    obj.keyset;
    fprintf('\nFaceAttribute_anu: Done!\n')
catch ME
    fprintf(['\nFaceAttribute_anu: ' ME.message])
    throw(ME)
end

try
    fprintf('\nFaceAttribute_anu: Monitor set-up ...\n')
    obj.dispset;
    fprintf('\nFaceAttribute_anu: Done!\n')
catch ME
    fprintf(['\nFaceAttribute_anu: ' ME.message])
    throw(ME)
end

try
    fprintf('\nFaceAttribute_anu: Window set-up ...\n')
    % Open and format window
    obj.monitor.w = Screen('OpenWindow',obj.monitor.whichScreen,obj.monitor.black);
    Screen('BlendFunction', obj.monitor.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',obj.monitor.w,30);
    fprintf('\nFaceAttribute_anu: Done!\n')
catch ME
    fprintf(['\nFaceAttribute_anu: ' ME.message])
    throw(ME)
end

try
    fprintf('\nFaceAttribute_anu: Beginning practice ...\n')
    [tex] = obj.imgshow2([obj.path.general filesep 'intro.jpg']);
    Screen('Flip',obj.monitor.w);
    
    Screen('Close',tex);
    RestrictKeysForKbCheck(obj.keys.spacekey);
    KbStrokeWait;
    
    % Handling supplements
    [tex] = obj.imgshow2([obj.path.general filesep 'instruct_' obj.current_condition '.jpg']);
    Screen('Flip',obj.monitor.w);
    
    Screen('Close',tex);
    RestrictKeysForKbCheck(obj.keys.spacekey);
    KbStrokeWait;
    
    %     d = regexp(d(1:end-1),'[\t\n]','split');
    %     d = reshape(sort(d),[3 2 2]);
    %     d = [d(:,:,1); d(:,:,2)]'; % 1 sub and 1 dom picture for each type & percentage
    %     d = d(:,Shuffle(1:6)); % Randomize
    
    prac_img = cell([2 length(obj.prac_block)]);
    
    for i = 1:length(obj.prac_block)
        [~, prac_img{1,i}, prac_img{2,i}] = obj.imgload('prac',obj.prac_block{i}); % 1 = img0, 2 = img100, row index
    end
    
    prac_imgi = Shuffle(repmat(1:length(obj.prac_block),[1 obj.prac_rep])); % Make prac_block x prac_rep repetitions, prac_img column index
    
    for i = 1:length(prac_imgi)
        obj.practice(prac_img{1,prac_imgi(i)},prac_img{2,prac_imgi(i)});% (img0,img100)
        if obj.abort
            break;
        end
    end
    
    fprintf('\nFaceAttribute_anu: Done!\n')
catch ME
    throw(ME)
end

try
    fprintf('\nFaceAttribute_anu: Beginning task ...\n')
    
    [tex] = obj.imgshow2([obj.path.general filesep 'begin_' obj.current_condition '.jpg']);
    Screen('Flip',obj.monitor.w);
    
    Screen('Close',tex);
    RestrictKeysForKbCheck(obj.keys.spacekey);
    KbStrokeWait;
    
    for i = 1:length(obj.order)
        
        [img, img0, ~] = obj.imgload('task',obj.order{i});
        
        [tex1] = obj.imgshow2([obj.path.general filesep 'blockbegin.jpg']);
        [tex2] = obj.imgshow2(fullfile([obj.path.task filesep],[obj.order{i} '_100.jpg']));
        Screen('Flip',obj.monitor.w);
        
        Screen('Close',tex1);
        Screen('Close',tex2);
        RestrictKeysForKbCheck(obj.keys.spacekey);
        KbStrokeWait;
        
        obj.current_block = obj.order{i};
        
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
    
    fprintf('\nFaceAttribute_anu: Done!\n')
catch ME
    throw(ME)
end

% Clean up
if ~obj.debug
    ListenChar(0);
    ShowCursor;
    
    if ispc
        ShowHideWinTaskbarMex(1)
    end
end

diary off
fclose('all');

Screen('CloseAll');

end