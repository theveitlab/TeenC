function token = str2binTokenGenerator(inpToken)
    % str2binTokenGenerator
    % Creates a uint32 number from 4 chars and returns the number as a
    % single. This is used to create a unique identifier that is used to switch between
    % the various functions inside ino/TeenC.ino
    binArr = zeros(8,4);

    for i = 1:4
        binArr(:,i) = dec2bin(double(char(inpToken(i))), 8);
    end

    binArr = char(reshape(binArr,1,[]));
    token = typecast(uint32(bin2dec(binArr)),'single');
end