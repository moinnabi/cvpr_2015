function image = draw_boxes_image(image, bboxes, intensity)
% bboxcords(xtl ytl xbr ybr) - top left and bottom right coord

if nargin < 3
    intensity = [255 0 0];
end
imgsiz = size(image);
thickness = min(imgsiz(1:2)) * 0.05;

for i=1:size(bboxes,1)    
    bboxcords = bboxes(i,:);
    lines_box(:,1) = bboxcords([1 3 2 2])';     % ytl xtl - ytl xbr
    lines_box(:,2) = bboxcords([3 3 2 4])';     % ytl xbr - ybr xbr
    lines_box(:,3) = bboxcords([3 1 4 4])';     % ybr xbr - ybr xtl
    lines_box(:,4) = bboxcords([1 1 4 2])';     % ybr xtl - ytl xtl
        
    image = draw_line_image2(image, lines_box, intensity, thickness); % hardcoded 3 pixel width
end
