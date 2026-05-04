function Iout = read_and_resize_img(image_file, target_size)
%reads an image and resizer to target size 
I=imread(image_file);
Iout=imresize(I,target_size);
%if grayscale conver to 3 channels, just in case
if ndims(Iout) == 2
    Iout = repmat(Iout, [1 1 3]);
end
end