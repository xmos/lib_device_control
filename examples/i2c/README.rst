
//TODO complete this file

cmake -B build -G Ninja
make -C build 
xflash --target-file src/XCORE-VISION-EXPLORER.xn bin/i2c.xe
