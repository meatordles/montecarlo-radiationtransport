% ============================================================================================
% data cursor information 
% ============================================================================================
function txt = dataTipText(info, cmPerPixel)
    x = info.Position(1);
    y = info.Position(2);
    pixelValue = num2str(info.Target.CData(info.DataIndex));
    precision = ceil(-log10(cmPerPixel)); % 0.01 cm/px --> precision = 2
    X = num2str(round(x, precision));
    Y = num2str(round(y, precision));
    txt = sprintf("(%s cm, %s cm), value = %s", X, Y, pixelValue);
end