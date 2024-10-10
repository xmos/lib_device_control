
//TODO complete this file

cmake -B build -G Ninja
make -C build
xflash --target-file src/XK-EVK-XU316-AIV_i2c.xn bin/i2c.xe
