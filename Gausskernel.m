function[convdata] = Gausskernel(binned, width, sd)

tk = -sd *width : sd * width;

kernel = exp(-(tk/width).^2/2)/(width*sqrt(2*pi));

AA = conv(binned, kernel);

convdata = AA( ceil(length(kernel)/2) : end - floor(length(kernel)/2));



