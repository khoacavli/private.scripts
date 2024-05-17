# NOTE

## HOW TO RUN
- Choice a disk to run CICD. EX : /mnt/SSD17TB/CICD/SDX35
- Get github action token. EX : BCU4LE4VIBTEQUD6MDUH27LGIOCQM
- Make sure docker img "ghcr.io/cavli-wireless/sdx35/owrt:latest" ready
- Run below cmd to create 4 local RUNNER !!!!!
    ```
    bash cicd_helper.sh /mnt/SSD17TB/CICD/SDX35 1 BCU4LE4VIBTEQUD6MDUH27LGIOCQM
    bash cicd_helper.sh /mnt/SSD17TB/CICD/SDX35 2 BCU4LE4VIBTEQUD6MDUH27LGIOCQM
    bash cicd_helper.sh /mnt/SSD17TB/CICD/SDX35 3 BCU4LE4VIBTEQUD6MDUH27LGIOCQM
    bash cicd_helper.sh /mnt/SSD17TB/CICD/SDX35 4 BCU4LE4VIBTEQUD6MDUH27LGIOCQM
    ```
